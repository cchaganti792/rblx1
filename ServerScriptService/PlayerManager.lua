-- PlayerManager.lua
-- Script → ServerScriptService
-- Handles player spawning, diamond collection, win/lose conditions, HUD updates.

local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunS    = game:GetService("RunService")

local Config    = require(RS:WaitForChild("GameConfig"))
local RE_Diamond= RS:WaitForChild("RE_PickupDiamond")
local RE_Won    = RS:WaitForChild("RE_GameWon")
local RE_Lost   = RS:WaitForChild("RE_GameLost")
local RE_HUD    = RS:WaitForChild("RE_UpdateHUD")
local RE_Dmg    = RS:WaitForChild("RE_TakeDamage")

task.wait(3)

local FY = Config.FLOOR_Y

-- ── Track per-player state ─────────────────────────────────────────────
local playerData = {}  -- [player] = { diamonds=0, currentCave=1, won=false }

-- ── Teleport player to a random spawn cave ─────────────────────────────
local function spawnPlayerInCave(player)
    local character = player.Character
    if not character then return end
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end

    local spawnCaves = Config.SPAWN_CAVES
    local caveId     = spawnCaves[math.random(1, #spawnCaves)]
    local c          = Config.CAVES[caveId].center

    hrp.CFrame = CFrame.new(c.X + math.random(-15,15), FY + 4, c.Z + math.random(-15,15))

    -- Give player WeaponTier value
    if not player:FindFirstChild("WeaponTier") then
        local wv = Instance.new("IntValue")
        wv.Name   = "WeaponTier"
        wv.Value  = 0
        wv.Parent = player
    end

    playerData[player] = { diamonds = 0, currentCave = caveId, won = false }
    RE_HUD:FireClient(player, Config.MAX_HEALTH, 0, caveId)
end

-- ── Detect which cave the player is currently in ──────────────────────
local function getCurrentCave(player)
    local char = player.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local pos = hrp.Position

    for caveId, data in pairs(Config.CAVES) do
        local c  = data.center
        local hw = Config.CAVE_W / 2
        local hd = Config.CAVE_D / 2
        if math.abs(pos.X - c.X) < hw and math.abs(pos.Z - c.Z) < hd then
            return caveId
        end
    end
    return nil
end

-- ── Diamond pickup ─────────────────────────────────────────────────────
local function setupDiamondPickups()
    -- Find all Diamond parts in the workspace (placed by CaveBuilder)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "Diamond" and obj:IsA("BasePart") then
            local pp = obj:FindFirstChildOfClass("ProximityPrompt")
            if pp then
                pp.Triggered:Connect(function(player)
                    local data = playerData[player]
                    if not data or data.won then return end

                    data.diamonds = data.diamonds + 1
                    obj:Destroy()

                    RE_Diamond:FireClient(player, data.diamonds)
                    RE_HUD:FireClient(player,
                        player.Character and player.Character:FindFirstChild("Humanoid") and
                        player.Character.Humanoid.Health or 0,
                        data.diamonds,
                        data.currentCave or 0)
                end)
            end
        end
    end
end

-- ── Exit zone touch (win condition) ───────────────────────────────────
local function setupExitZone()
    local exitZone = workspace:FindFirstChild("ExitZone")
    if not exitZone then return end

    exitZone.Touched:Connect(function(hit)
        local char = hit.Parent
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then return end

        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character == char then
                local data = playerData[player]
                if data and not data.won and data.diamonds >= Config.DIAMONDS_TO_WIN then
                    data.won = true
                    RE_Won:FireClient(player)
                end
                break
            end
        end
    end)
end

-- ── Humanoid death → game lost ─────────────────────────────────────────
local function onCharacterAdded(player, character)
    local hum = character:WaitForChild("Humanoid")

    hum.Died:Connect(function()
        local data = playerData[player]
        if data and not data.won then
            RE_Lost:FireClient(player)
        end
    end)
end

-- ── HUD update loop ───────────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(1)
        for _, player in ipairs(Players:GetPlayers()) do
            local char = player.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                local data= playerData[player]
                if hum and data then
                    local cave = getCurrentCave(player)
                    if cave then data.currentCave = cave end
                    RE_HUD:FireClient(player, math.floor(hum.Health), data.diamonds, data.currentCave or 0)
                end
            end
        end
    end
end)

-- ── Wire up events ────────────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(1)  -- let character load
        spawnPlayerInCave(player)
        onCharacterAdded(player, character)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    playerData[player] = nil
end)

-- Handle players already in game (Studio play test)
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        task.spawn(spawnPlayerInCave, player)
        task.spawn(onCharacterAdded, player, player.Character)
    end
    player.CharacterAdded:Connect(function(character)
        task.wait(1)
        spawnPlayerInCave(player)
        onCharacterAdded(player, character)
    end)
end

task.wait(1)
setupDiamondPickups()
setupExitZone()

print("[PlayerManager] Ready")
