-- CopManager.lua
-- Script → ServerScriptService
-- Cops with full police uniform, face, arms, legs. Patrol + chase AI. Regeneration.

local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config  = require(RS:WaitForChild("GameConfig"))
local RE_Take = RS:WaitForChild("RE_TakeDamage")
local RE_Flash= RS:WaitForChild("RE_CopFlash")

task.wait(3)

local FY      = Config.FLOOR_Y   -- 2 (floor surface)
local TORSO_Y = FY + 3.5         -- torso center so boots touch floor

local AllCops   = {}
local COP_MAX_HP = 100

-- ── Weld helper ───────────────────────────────────────────────────────
local function weld(torso, part, offset)
    part.CFrame   = torso.CFrame * CFrame.new(offset)
    part.Anchored = false
    local wc = Instance.new("WeldConstraint")
    wc.Part0 = torso
    wc.Part1 = part
    wc.Parent = torso
    part.Parent = torso.Parent
    return part
end

-- ── Build realistic police officer model ──────────────────────────────
local function makeCopModel(spawnPos)
    local model = Instance.new("Model")
    model.Name  = "Cop"

    local cf = CFrame.new(spawnPos.X, TORSO_Y, spawnPos.Z)

    -- ── TORSO (anchor, navy blue uniform) ─────────────────────────────
    local torso = Instance.new("Part")
    torso.Name      = "Torso"
    torso.Size      = Vector3.new(2, 2, 1)
    torso.BrickColor= BrickColor.new("Navy blue")
    torso.Material  = Enum.Material.SmoothPlastic
    torso.Anchored  = true
    torso.CFrame    = cf
    torso.Parent    = model

    -- "POLICE" text on back of torso
    local sg = Instance.new("SurfaceGui")
    sg.Face = Enum.NormalId.Back
    sg.Parent = torso
    local sgLabel = Instance.new("TextLabel")
    sgLabel.Size = UDim2.new(1,0,1,0)
    sgLabel.BackgroundColor3 = Color3.fromRGB(255,255,255)
    sgLabel.Text = "POLICE"
    sgLabel.TextColor3 = Color3.fromRGB(0,0,128)
    sgLabel.Font = Enum.Font.GothamBold
    sgLabel.TextScaled = true
    sgLabel.Parent = sg

    -- Gold badge on front chest
    local badge = Instance.new("Part")
    badge.Name = "Badge"
    badge.Size = Vector3.new(0.45, 0.45, 0.1)
    badge.BrickColor = BrickColor.new("Bright yellow")
    badge.Material = Enum.Material.Metal
    weld(torso, badge, Vector3.new(-0.5, 0.5, -0.55))

    -- Black belt
    local belt = Instance.new("Part")
    belt.Name = "Belt"
    belt.Size = Vector3.new(2.1, 0.3, 1.1)
    belt.BrickColor = BrickColor.new("Black")
    belt.Material = Enum.Material.SmoothPlastic
    weld(torso, belt, Vector3.new(0, -1.1, 0))

    -- Gun holster on right hip
    local gun = Instance.new("Part")
    gun.Name = "Gun"
    gun.Size = Vector3.new(0.25, 0.7, 1)
    gun.BrickColor = BrickColor.new("Dark stone grey")
    gun.Material = Enum.Material.Metal
    weld(torso, gun, Vector3.new(1.1, -0.9, -0.3))

    -- ── HEAD (skin tone with face decal) ──────────────────────────────
    local head = Instance.new("Part")
    head.Name      = "Head"
    head.Size      = Vector3.new(2, 1, 1)
    head.BrickColor= BrickColor.new("Nougat")
    head.Material  = Enum.Material.SmoothPlastic
    weld(torso, head, Vector3.new(0, 1.5, 0))

    -- Face decal (default Roblox face on the front)
    local face = Instance.new("Decal")
    face.Texture = "rbxasset://textures/face.png"
    face.Face    = Enum.NormalId.Front
    face.Parent  = head

    -- ── POLICE HAT ────────────────────────────────────────────────────
    local hatBrim = Instance.new("Part")
    hatBrim.Name      = "HatBrim"
    hatBrim.Size      = Vector3.new(2.5, 0.15, 2.1)
    hatBrim.BrickColor= BrickColor.new("Black")
    hatBrim.Material  = Enum.Material.SmoothPlastic
    weld(torso, hatBrim, Vector3.new(0, 2.15, -0.1))

    local hatTop = Instance.new("Part")
    hatTop.Name      = "HatTop"
    hatTop.Size      = Vector3.new(2, 0.9, 1.8)
    hatTop.BrickColor= BrickColor.new("Black")
    hatTop.Material  = Enum.Material.SmoothPlastic
    weld(torso, hatTop, Vector3.new(0, 2.6, 0))

    -- Silver shield on hat front
    local hatBadge = Instance.new("Part")
    hatBadge.Name      = "HatBadge"
    hatBadge.Size      = Vector3.new(0.4, 0.35, 0.1)
    hatBadge.BrickColor= BrickColor.new("Mid gray")
    hatBadge.Material  = Enum.Material.Metal
    weld(torso, hatBadge, Vector3.new(0, 2.6, -0.95))

    -- ── ARMS (navy blue sleeves + skin hands) ─────────────────────────
    local leftArm = Instance.new("Part")
    leftArm.Name      = "LeftArm"
    leftArm.Size      = Vector3.new(1, 2, 1)
    leftArm.BrickColor= BrickColor.new("Navy blue")
    leftArm.Material  = Enum.Material.SmoothPlastic
    weld(torso, leftArm, Vector3.new(-1.5, 0, 0))

    local rightArm = Instance.new("Part")
    rightArm.Name      = "RightArm"
    rightArm.Size      = Vector3.new(1, 2, 1)
    rightArm.BrickColor= BrickColor.new("Navy blue")
    rightArm.Material  = Enum.Material.SmoothPlastic
    weld(torso, rightArm, Vector3.new(1.5, 0, 0))

    local leftHand = Instance.new("Part")
    leftHand.Name      = "LeftHand"
    leftHand.Size      = Vector3.new(0.9, 0.6, 0.9)
    leftHand.BrickColor= BrickColor.new("Nougat")
    leftHand.Material  = Enum.Material.SmoothPlastic
    weld(torso, leftHand, Vector3.new(-1.5, -1.3, 0))

    local rightHand = Instance.new("Part")
    rightHand.Name      = "RightHand"
    rightHand.Size      = Vector3.new(0.9, 0.6, 0.9)
    rightHand.BrickColor= BrickColor.new("Nougat")
    rightHand.Material  = Enum.Material.SmoothPlastic
    weld(torso, rightHand, Vector3.new(1.5, -1.3, 0))

    -- ── LEGS (dark blue trousers + black boots) ───────────────────────
    local leftLeg = Instance.new("Part")
    leftLeg.Name      = "LeftLeg"
    leftLeg.Size      = Vector3.new(0.9, 2, 1)
    leftLeg.BrickColor= BrickColor.new("Dark blue")
    leftLeg.Material  = Enum.Material.SmoothPlastic
    weld(torso, leftLeg, Vector3.new(-0.5, -2, 0))

    local rightLeg = Instance.new("Part")
    rightLeg.Name      = "RightLeg"
    rightLeg.Size      = Vector3.new(0.9, 2, 1)
    rightLeg.BrickColor= BrickColor.new("Dark blue")
    rightLeg.Material  = Enum.Material.SmoothPlastic
    weld(torso, rightLeg, Vector3.new(0.5, -2, 0))

    local leftBoot = Instance.new("Part")
    leftBoot.Name      = "LeftBoot"
    leftBoot.Size      = Vector3.new(1, 0.5, 1.3)
    leftBoot.BrickColor= BrickColor.new("Black")
    leftBoot.Material  = Enum.Material.SmoothPlastic
    weld(torso, leftBoot, Vector3.new(-0.5, -3.25, 0.1))

    local rightBoot = Instance.new("Part")
    rightBoot.Name      = "RightBoot"
    rightBoot.Size      = Vector3.new(1, 0.5, 1.3)
    rightBoot.BrickColor= BrickColor.new("Black")
    rightBoot.Material  = Enum.Material.SmoothPlastic
    weld(torso, rightBoot, Vector3.new(0.5, -3.25, 0.1))

    -- ── OVERHEAD NAME + HP ────────────────────────────────────────────
    local bg = Instance.new("BillboardGui")
    bg.Size        = UDim2.new(0, 120, 0, 32)
    bg.StudsOffset = Vector3.new(0, 4, 0)
    bg.Parent      = head

    local nameL = Instance.new("TextLabel")
    nameL.Size = UDim2.new(1,0,0.55,0)
    nameL.BackgroundTransparency = 1
    nameL.Text = "🚔 OFFICER"
    nameL.TextColor3 = Color3.new(1,1,1)
    nameL.Font = Enum.Font.GothamBold
    nameL.TextScaled = true
    nameL.Parent = bg

    local hpL = Instance.new("TextLabel")
    hpL.Name = "HPLabel"
    hpL.Size = UDim2.new(1,0,0.45,0)
    hpL.Position = UDim2.new(0,0,0.55,0)
    hpL.BackgroundTransparency = 1
    hpL.Text = "HP: 100"
    hpL.TextColor3 = Color3.fromRGB(80,255,80)
    hpL.Font = Enum.Font.Gotham
    hpL.TextScaled = true
    hpL.Parent = bg

    model.PrimaryPart = torso
    model.Parent      = workspace
    return model
end

-- ── Random patrol point inside a cave ─────────────────────────────────
local function patrolPoint(caveId)
    local c = Config.CAVES[caveId].center
    return Vector3.new(
        c.X + math.random(-Config.COP_PATROL_RANGE, Config.COP_PATROL_RANGE),
        TORSO_Y,
        c.Z + math.random(-Config.COP_PATROL_RANGE, Config.COP_PATROL_RANGE)
    )
end

-- ── Line of sight check ───────────────────────────────────────────────
local function hasLOS(copPos, playerPos)
    local dir = playerPos - copPos
    if dir.Magnitude > Config.COP_DETECT_RANGE then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(copPos, dir, params)
    if result then
        if result.Instance.Name == "Hideout" then return false end
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl.Character and result.Instance:IsDescendantOf(pl.Character) then
                return true
            end
        end
        return false
    end
    return true
end

-- ── Shoot player ──────────────────────────────────────────────────────
local function shootPlayer(cop, player)
    if not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local dist   = (cop.model.Torso.Position - hrp.Position).Magnitude
    if dist > Config.COP_SHOOT_RANGE then return end
    local ratio  = 1 - (dist / Config.COP_SHOOT_RANGE)
    local damage = math.max(5, math.floor(Config.COP_BASE_DAMAGE * ratio))
    local hum    = player.Character:FindFirstChild("Humanoid")
    if hum and hum.Health > 0 then
        hum:TakeDamage(damage)
        RE_Take:FireClient(player, damage, hum.Health)
        RE_Flash:FireAllClients(cop.model.Torso.Position)
    end
end

-- ── Damage & kill cop ─────────────────────────────────────────────────
local function damageCop(cop, dmg)
    cop.hp = cop.hp - dmg

    local head = cop.model:FindFirstChild("Head")
    local bg   = head and head:FindFirstChildOfClass("BillboardGui")
    local hpL  = bg and bg:FindFirstChild("HPLabel")
    if hpL then
        hpL.Text = "HP: " .. math.max(0, cop.hp)
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

        -- Respawn after delay
        task.delay(Config.COP_REGEN_TIME, function()
            local caveData = Config.CAVES[originCave]
            if not caveData then return end
            local c = caveData.center
            local sp = Vector3.new(c.X + math.random(-20,20), FY, c.Z + math.random(-20,20))
            local newCop = { model=makeCopModel(sp), caveId=originCave, alive=true, hp=COP_MAX_HP }
            table.insert(AllCops, newCop)
            task.spawn(function()
                local ok, err = pcall(function() copLoop(newCop) end)
                if not ok then warn("[CopManager] copLoop error: " .. tostring(err)) end
            end)
        end)
    end
end

-- ── Main AI loop ──────────────────────────────────────────────────────
function copLoop(cop)
    local shootCD   = 0
    local rotateT   = math.random(Config.COP_ROTATE_MIN, Config.COP_ROTATE_MAX)
    local patrolTgt = patrolPoint(cop.caveId)

    while cop.alive do
        task.wait(0.05)
        if not cop.alive or not cop.model or not cop.model.Parent then break end

        local torsoPos = cop.model.Torso.Position
        shootCD = math.max(0, shootCD - 0.05)

        -- Find nearest player
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

        local detected = nearest
            and nearDist <= Config.COP_DETECT_RANGE
            and hasLOS(torsoPos, nearHRP.Position)

        if detected then
            -- CHASE
            local tgt = Vector3.new(nearHRP.Position.X, torsoPos.Y, nearHRP.Position.Z)
            local dir = tgt - torsoPos
            if dir.Magnitude > 3 then
                local step = Config.COP_CHASE_SPEED * 0.05
                local newPos = torsoPos + dir.Unit * math.min(step, dir.Magnitude - 3)
                cop.model.Torso.CFrame = CFrame.lookAt(newPos, Vector3.new(tgt.X, newPos.Y, tgt.Z))
            end
            if shootCD <= 0 and nearDist <= Config.COP_SHOOT_RANGE then
                shootPlayer(cop, nearest)
                shootCD = Config.COP_FIRE_RATE
            end
            rotateT = math.random(Config.COP_ROTATE_MIN, Config.COP_ROTATE_MAX)
        else
            -- PATROL
            local dir = patrolTgt - torsoPos
            if dir.Magnitude < 2 then
                rotateT = rotateT - 1
                if rotateT <= 0 then
                    local conns = Config.CAVES[cop.caveId].connections
                    cop.caveId = conns[math.random(1, #conns)]
                    rotateT    = math.random(Config.COP_ROTATE_MIN, Config.COP_ROTATE_MAX)
                end
                patrolTgt = patrolPoint(cop.caveId)
            else
                local step   = Config.COP_SPEED * 0.05
                local newPos = torsoPos + dir.Unit * math.min(step, dir.Magnitude)
                cop.model.Torso.CFrame = CFrame.lookAt(newPos, Vector3.new(patrolTgt.X, newPos.Y, patrolTgt.Z))
            end
        end
    end
end

-- ── Handle player shooting cops ───────────────────────────────────────
RS:WaitForChild("RE_ShootWeapon").OnServerEvent:Connect(function(player, origin, direction, tier)
    local weaponData = Config.WEAPONS[tier]
    if not weaponData then return end
    local wVal = player:FindFirstChild("WeaponTier")
    if not wVal or wVal.Value < tier then return end

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { player.Character }
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(origin, direction * weaponData.range, params)
    if not result then return end

    local hitModel = result.Instance and result.Instance:FindFirstAncestorOfClass("Model")
    if hitModel and hitModel.Name == "Cop" then
        for _, cop in ipairs(AllCops) do
            if cop.model == hitModel then
                damageCop(cop, weaponData.damage)
                break
            end
        end
    end
end)

-- ── Spawn all cops ────────────────────────────────────────────────────
for caveId, data in pairs(Config.CAVES) do
    for i = 1, data.copCount do
        task.wait(0.15)
        local c  = data.center
        local sp = Vector3.new(c.X + math.random(-20,20), FY, c.Z + math.random(-20,20))
        local cop = { model=makeCopModel(sp), caveId=caveId, alive=true, hp=COP_MAX_HP }
        table.insert(AllCops, cop)
        task.spawn(copLoop, cop)
    end
end

print("[CopManager] Police officers spawned with full uniforms")
