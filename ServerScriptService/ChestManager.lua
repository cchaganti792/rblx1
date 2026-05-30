-- ChestManager.lua
-- Script → ServerScriptService
-- Mystery weapon chests — contents hidden until opened.

local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config  = require(RS:WaitForChild("GameConfig"))
local RE_Wpn  = RS:WaitForChild("RE_PickupWeapon")

task.wait(3)

local FY = Config.FLOOR_Y

-- ── Build a mystery chest ─────────────────────────────────────────────
local function makeChest(position, tier)
    -- All chests look the same — mystery box style
    local chest = Instance.new("Part")
    chest.Name      = "Chest"
    chest.Size      = Vector3.new(4, 3, 3)
    chest.BrickColor= BrickColor.new("Reddish brown")
    chest.Material  = Enum.Material.Wood
    chest.Anchored  = true
    chest.CFrame    = CFrame.new(position)
    chest.Parent    = workspace

    -- Lid
    local lid = Instance.new("Part")
    lid.Size       = Vector3.new(4, 0.5, 3)
    lid.BrickColor = BrickColor.new("Brown")
    lid.Material   = Enum.Material.Wood
    lid.Anchored   = true
    lid.CFrame     = CFrame.new(position + Vector3.new(0, 1.75, 0))
    lid.CanCollide = false
    lid.Parent     = workspace

    -- Metal latch
    local latch = Instance.new("Part")
    latch.Size      = Vector3.new(0.8, 0.4, 0.2)
    latch.BrickColor= BrickColor.new("Mid gray")
    latch.Material  = Enum.Material.Metal
    latch.Anchored  = true
    latch.CFrame    = CFrame.new(position + Vector3.new(0, 1.75, -1.6))
    latch.CanCollide= false
    latch.Parent    = workspace

    -- Mystery "?" billboard — NO weapon hint
    local bg = Instance.new("BillboardGui")
    bg.Size        = UDim2.new(0, 80, 0, 80)
    bg.StudsOffset = Vector3.new(0, 4, 0)
    bg.Parent      = chest

    local icon = Instance.new("TextLabel")
    icon.Name              = "Icon"
    icon.Size              = UDim2.new(1,0,1,0)
    icon.BackgroundTransparency = 1
    icon.Text              = "?"
    icon.TextColor3        = Color3.fromRGB(255, 200, 0)
    icon.Font              = Enum.Font.GothamBold
    icon.TextScaled        = true
    icon.Parent            = bg

    -- Proximity prompt — no weapon name shown
    local pp = Instance.new("ProximityPrompt")
    pp.ActionText          = "Open Chest"
    pp.KeyboardKeyCode     = Enum.KeyCode.E
    pp.MaxActivationDistance = 8
    pp.Parent              = chest

    -- Tier stored invisibly (not shown to player)
    local tv = Instance.new("IntValue")
    tv.Name = "WeaponTier" ; tv.Value = tier ; tv.Parent = chest

    local opened = false

    pp.Triggered:Connect(function(player)
        if opened then return end
        opened = true

        -- Give player this weapon (keep highest tier)
        local wVal = player:FindFirstChild("WeaponTier")
        if not wVal then
            wVal = Instance.new("IntValue")
            wVal.Name = "WeaponTier" ; wVal.Value = 0 ; wVal.Parent = player
        end
        if tier > wVal.Value then wVal.Value = tier end

        -- Notify client with what was found
        RE_Wpn:FireClient(player, tier, Config.WEAPONS[tier].name)

        -- Animate chest lid opening
        local openTween = game:GetService("TweenService"):Create(lid,
            TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { CFrame = lid.CFrame * CFrame.Angles(math.rad(-70), 0, 0) })
        openTween:Play()

        -- Visual: show "EMPTY" after open
        icon.Text      = "✓"
        icon.TextColor3= Color3.fromRGB(100, 255, 100)
        pp:Destroy()

        -- Respawn after 60s
        task.delay(60, function()
            opened = false
            lid.CFrame = CFrame.new(position + Vector3.new(0, 1.75, 0))
            icon.Text       = "?"
            icon.TextColor3 = Color3.fromRGB(255, 200, 0)

            local newPP = Instance.new("ProximityPrompt")
            newPP.ActionText = "Open Chest"
            newPP.KeyboardKeyCode = Enum.KeyCode.E
            newPP.MaxActivationDistance = 8
            newPP.Parent = chest

            newPP.Triggered:Connect(function(p2)
                if opened then return end
                opened = true
                local wv = p2:FindFirstChild("WeaponTier")
                if not wv then wv = Instance.new("IntValue"); wv.Name="WeaponTier"; wv.Value=0; wv.Parent=p2 end
                if tier > wv.Value then wv.Value = tier end
                RE_Wpn:FireClient(p2, tier, Config.WEAPONS[tier].name)
                icon.Text = "✓"
                icon.TextColor3 = Color3.fromRGB(100,255,100)
                newPP:Destroy()
            end)
        end)
    end)
end

-- ── Spawn chests in every cave ────────────────────────────────────────
for caveId, data in pairs(Config.CAVES) do
    local cx   = data.center.X
    local cz   = data.center.Z
    local tier = data.weaponTier
    local offsets = {
        Vector3.new(-22, 0, -22),
        Vector3.new( 20, 0,  18),
    }
    for i = 1, Config.CHESTS_PER_CAVE do
        local off = offsets[i] or Vector3.new(math.random(-25,25), 0, math.random(-25,25))
        makeChest(Vector3.new(cx + off.X, FY + 1.5, cz + off.Z), tier)
    end
end

print("[ChestManager] Mystery chests spawned")
