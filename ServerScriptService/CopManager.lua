-- CopManager.lua
-- Script → ServerScriptService

print("[CopManager] Script started")

local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config  = require(RS:WaitForChild("GameConfig"))

local function getRemote(name)
    local re = RS:FindFirstChild(name)
    if not re then
        re = Instance.new("RemoteEvent")
        re.Name   = name
        re.Parent = RS
    end
    return re
end

local RE_Take  = getRemote("RE_TakeDamage")
local RE_Flash = getRemote("RE_CopFlash")

print("[CopManager] Remotes ready — waiting 3s for world to load")
task.wait(3)
print("[CopManager] Starting cop spawn")

local FY      = Config.FLOOR_Y
local TORSO_Y = FY + 3.5

local AllCops    = {}
local COP_MAX_HP = 100

-- torch state: true = on (cop can see at full range), false/nil = dark (near-blind)
local playerTorchOn = {}

-- ── Build cop CFrame from position + look direction ───────────────────
local function makeCF(pos, lookDir)
    if lookDir and lookDir.Magnitude > 0.01 then
        local angle = math.atan2(lookDir.X, lookDir.Z)
        return CFrame.new(pos) * CFrame.Angles(0, angle, 0)
    end
    return CFrame.new(pos)
end

-- ── Move all cop parts together ───────────────────────────────────────
local function moveCop(cop, newCF)
    for _, entry in ipairs(cop.parts) do
        entry.part.CFrame = newCF * entry.offset
    end
end

-- ── Build realistic police officer ───────────────────────────────────
local function makeCopModel(spawnPos)
    local model = Instance.new("Model")
    model.Name  = "Cop"

    local baseCF = CFrame.new(spawnPos.X, TORSO_Y, spawnPos.Z)
    local parts  = {}

    local function add(name, size, offset, color, mat)
        local p = Instance.new("Part")
        p.Name      = name
        p.Size      = size
        p.BrickColor= color
        p.Material  = mat or Enum.Material.SmoothPlastic
        p.Anchored  = true
        p.CanCollide= false
        p.CastShadow= true
        p.CFrame    = baseCF * CFrame.new(offset)
        p.Parent    = model
        table.insert(parts, { part = p, offset = CFrame.new(offset) })
        return p
    end

    local torso = add("Torso",    Vector3.new(2,   2,   1),   Vector3.new(0, 0, 0),       BrickColor.new("Navy blue"))
    add("Belt",                   Vector3.new(2.1, 0.3, 1.1), Vector3.new(0,-1.1, 0),     BrickColor.new("Black"))
    add("Badge",                  Vector3.new(0.45,0.45,0.1), Vector3.new(-0.5,0.5,-0.55),BrickColor.new("Bright yellow"), Enum.Material.Metal)
    add("Gun",                    Vector3.new(0.25,0.7, 1),   Vector3.new(1.1,-0.9,-0.3), BrickColor.new("Dark stone grey"), Enum.Material.Metal)

    local head = add("Head",      Vector3.new(2,   1,   1),   Vector3.new(0, 1.5, 0),     BrickColor.new("Nougat"))
    local face  = Instance.new("Decal")
    face.Texture = "rbxasset://textures/face.png"
    face.Face    = Enum.NormalId.Front
    face.Parent  = head

    add("HatBrim",                Vector3.new(2.5, 0.15,2.1), Vector3.new(0, 2.15,-0.1),  BrickColor.new("Black"))
    add("HatTop",                 Vector3.new(2,   0.9, 1.8), Vector3.new(0, 2.6,  0),    BrickColor.new("Black"))
    add("HatBadge",               Vector3.new(0.4, 0.35,0.1), Vector3.new(0, 2.6, -0.95), BrickColor.new("Mid gray"), Enum.Material.Metal)

    add("LeftArm",                Vector3.new(1,   2,   1),   Vector3.new(-1.5, 0,   0),  BrickColor.new("Navy blue"))
    add("RightArm",               Vector3.new(1,   2,   1),   Vector3.new( 1.5, 0,   0),  BrickColor.new("Navy blue"))
    add("LeftHand",               Vector3.new(0.9, 0.6, 0.9), Vector3.new(-1.5,-1.3, 0),  BrickColor.new("Nougat"))
    add("RightHand",              Vector3.new(0.9, 0.6, 0.9), Vector3.new( 1.5,-1.3, 0),  BrickColor.new("Nougat"))

    add("LeftLeg",                Vector3.new(0.9, 2,   1),   Vector3.new(-0.5,-2,   0),  BrickColor.new("Dark blue"))
    add("RightLeg",               Vector3.new(0.9, 2,   1),   Vector3.new( 0.5,-2,   0),  BrickColor.new("Dark blue"))
    add("LeftBoot",               Vector3.new(1,   0.5, 1.3), Vector3.new(-0.5,-3.25,0.1),BrickColor.new("Black"))
    add("RightBoot",              Vector3.new(1,   0.5, 1.3), Vector3.new( 0.5,-3.25,0.1),BrickColor.new("Black"))

    local sg = Instance.new("SurfaceGui")
    sg.Face = Enum.NormalId.Back ; sg.Parent = torso
    local sgL = Instance.new("TextLabel")
    sgL.Size = UDim2.new(1,0,1,0) ; sgL.Text = "POLICE"
    sgL.TextColor3 = Color3.fromRGB(0,0,128)
    sgL.BackgroundColor3 = Color3.new(1,1,1)
    sgL.Font = Enum.Font.GothamBold ; sgL.TextScaled = true ; sgL.Parent = sg

    local bg = Instance.new("BillboardGui")
    bg.Size = UDim2.new(0,120,0,32) ; bg.StudsOffset = Vector3.new(0,4,0)
    bg.Parent = head

    local nameL = Instance.new("TextLabel")
    nameL.Size = UDim2.new(1,0,0.55,0) ; nameL.BackgroundTransparency = 1
    nameL.Text = "🚔 OFFICER" ; nameL.TextColor3 = Color3.new(1,1,1)
    nameL.Font = Enum.Font.GothamBold ; nameL.TextScaled = true ; nameL.Parent = bg

    local hpL = Instance.new("TextLabel")
    hpL.Name = "HPLabel" ; hpL.Size = UDim2.new(1,0,0.45,0)
    hpL.Position = UDim2.new(0,0,0.55,0) ; hpL.BackgroundTransparency = 1
    hpL.Text = "HP: 100" ; hpL.TextColor3 = Color3.fromRGB(80,255,80)
    hpL.Font = Enum.Font.Gotham ; hpL.TextScaled = true ; hpL.Parent = bg

    model.PrimaryPart = torso
    model.Parent      = workspace

    return model, parts, torso
end

-- ── Line-of-sight check ───────────────────────────────────────────────
local function hasLOS(fromPos, toPos)
    local dir    = toPos - fromPos
    local result = workspace:Raycast(fromPos, dir)
    if result then
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl.Character and result.Instance:IsDescendantOf(pl.Character) then
                return true
            end
        end
        return false
    end
    return true
end

-- ── Patrol point inside a cave ────────────────────────────────────────
local function patrolPoint(caveId)
    local c = Config.CAVES[caveId].center
    return Vector3.new(
        c.X + math.random(-Config.COP_PATROL_RANGE, Config.COP_PATROL_RANGE),
        TORSO_Y,
        c.Z + math.random(-Config.COP_PATROL_RANGE, Config.COP_PATROL_RANGE)
    )
end

-- ── Shoot player ──────────────────────────────────────────────────────
local function shootPlayer(cop, player)
    if not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local dist = (cop.torso.Position - hrp.Position).Magnitude
    if dist > Config.COP_SHOOT_RANGE then return end
    if not hasLOS(cop.torso.Position, hrp.Position) then return end
    local ratio  = 1 - (dist / Config.COP_SHOOT_RANGE)
    local damage = math.max(5, math.floor(Config.COP_BASE_DAMAGE * ratio))
    local hum    = player.Character:FindFirstChild("Humanoid")
    if hum and hum.Health > 0 then
        hum:TakeDamage(damage)
        RE_Take:FireClient(player, damage, hum.Health)
        RE_Flash:FireAllClients(cop.torso.Position)
    end
end

-- ── Damage cop ────────────────────────────────────────────────────────
local function damageCop(cop, dmg)
    cop.hp = math.max(0, cop.hp - dmg)

    local head = cop.model:FindFirstChild("Head")
    local bg   = head and head:FindFirstChildOfClass("BillboardGui")
    local hpL  = bg and bg:FindFirstChild("HPLabel")
    if hpL then
        hpL.Text = "HP: " .. cop.hp
        hpL.TextColor3 = cop.hp > 60 and Color3.fromRGB(80,255,80)
            or cop.hp > 30 and Color3.fromRGB(255,200,0)
            or Color3.fromRGB(255,60,60)
    end

    if cop.hp <= 0 then
        cop.alive = false
        local originCave = cop.caveId
        cop.model:Destroy()
        for i, c in ipairs(AllCops) do
            if c == cop then table.remove(AllCops, i) break end
        end

        task.delay(Config.COP_REGEN_TIME, function()
            local caveData = Config.CAVES[originCave]
            if not caveData then return end
            local c  = caveData.center
            local sp = Vector3.new(c.X + math.random(-20,20), FY, c.Z + math.random(-20,20))
            local newModel, newParts, newTorso = makeCopModel(sp)
            local newCop = {
                model  = newModel,
                parts  = newParts,
                torso  = newTorso,
                caveId = originCave,
                alive  = true,
                hp     = COP_MAX_HP,
            }
            table.insert(AllCops, newCop)
            task.spawn(copLoop, newCop)
        end)
    end
end

-- ── Main cop AI loop ──────────────────────────────────────────────────
function copLoop(cop)
    local shootCD   = 0
    local rotateT   = math.random(Config.COP_ROTATE_MIN, Config.COP_ROTATE_MAX)
    local patrolTgt = patrolPoint(cop.caveId)

    while cop.alive do
        task.wait(0.05)

        if not cop.alive or not cop.model or not cop.model.Parent then break end

        local ok, err = pcall(function()
            local torsoPos = cop.torso.Position
            shootCD = math.max(0, shootCD - 0.05)

            local nearest, nearDist, nearHRP = nil, math.huge, nil
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl.Character then
                    local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local d = (torsoPos - hrp.Position).Magnitude
                        if d < nearDist then
                            nearDist = d ; nearest = pl ; nearHRP = hrp
                        end
                    end
                end
            end

            -- Torch off → cops nearly blind (6 studs); torch on → full range
            local effectiveRange = (nearest and playerTorchOn[nearest]) and Config.COP_DETECT_RANGE or 6
            local detected = nearest ~= nil
                and nearDist <= effectiveRange
                and hasLOS(torsoPos, nearHRP.Position)

            if detected then
                local tgt    = Vector3.new(nearHRP.Position.X, torsoPos.Y, nearHRP.Position.Z)
                local dir    = tgt - torsoPos
                local newPos = torsoPos

                if dir.Magnitude > 1.5 then
                    local step = Config.COP_CHASE_SPEED * 0.05
                    newPos = torsoPos + dir.Unit * math.min(step, dir.Magnitude - 1.5)
                end

                moveCop(cop, makeCF(newPos, tgt - newPos))

                if shootCD <= 0 and nearDist <= Config.COP_SHOOT_RANGE then
                    shootPlayer(cop, nearest)
                    shootCD = Config.COP_FIRE_RATE
                end

                rotateT = math.random(Config.COP_ROTATE_MIN, Config.COP_ROTATE_MAX)

            else
                local dir = patrolTgt - torsoPos

                if dir.Magnitude < 2 then
                    rotateT = rotateT - 2
                    if rotateT <= 0 then
                        local conns = Config.CAVES[cop.caveId].connections
                        cop.caveId  = conns[math.random(1, #conns)]
                        rotateT     = math.random(Config.COP_ROTATE_MIN, Config.COP_ROTATE_MAX)
                    end
                    patrolTgt = patrolPoint(cop.caveId)
                else
                    local step   = Config.COP_SPEED * 0.05
                    local newPos = torsoPos + dir.Unit * math.min(step, dir.Magnitude)
                    moveCop(cop, makeCF(newPos, dir))
                end
            end
        end)

        if not ok then
            warn("[CopManager] loop error: " .. tostring(err))
        end
    end
end

-- ── Track torch state from clients ───────────────────────────────────
getRemote("RE_TorchState").OnServerEvent:Connect(function(player, isOn)
    playerTorchOn[player] = isOn
end)

Players.PlayerRemoving:Connect(function(player)
    playerTorchOn[player] = nil
end)

-- ── Player shoots ─────────────────────────────────────────────────────
getRemote("RE_ShootWeapon").OnServerEvent:Connect(function(player, origin, direction, tier)
    local weaponData = Config.WEAPONS[tier]
    if not weaponData then return end
    local wVal = player:FindFirstChild("WeaponTier")
    if not wVal or wVal.Value < 1 then return end

    local dir = direction.Unit
    local bestCop, bestDist = nil, math.huge

    for _, cop in ipairs(AllCops) do
        if cop.alive and cop.model and cop.model.Parent then
            local copPos = cop.torso.Position
            local t = (copPos - origin):Dot(dir)
            if t > 0 and t <= weaponData.range then
                local perpDist = (copPos - (origin + dir * t)).Magnitude
                if perpDist < 6 and perpDist < bestDist then
                    bestDist = perpDist
                    bestCop  = cop
                end
            end
        end
    end

    if bestCop then
        damageCop(bestCop, weaponData.damage)
        RE_Flash:FireAllClients(bestCop.torso.Position)
    end
end)

-- ── Spawn all cops ────────────────────────────────────────────────────
for caveId, data in pairs(Config.CAVES) do
    for i = 1, data.copCount do
        task.wait(0.15)
        local c  = data.center
        local sp = Vector3.new(c.X + math.random(-20,20), FY, c.Z + math.random(-20,20))
        local m, p, t = makeCopModel(sp)
        local cop = { model=m, parts=p, torso=t, caveId=caveId, alive=true, hp=COP_MAX_HP }
        table.insert(AllCops, cop)
        task.spawn(copLoop, cop)
    end
end

print("[CopManager] Cops spawned — torch-aware detection active")
