-- WeaponHandler.lua
-- LocalScript → StarterCharacterScripts
-- Handles player shooting: mouse click → raycast → fire RE_ShootWeapon to server.

local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")
local UIS       = game:GetService("UserInputService")
local RunS      = game:GetService("RunService")

local player    = Players.LocalPlayer
local mouse     = player:GetMouse()
local character = script.Parent
local hrp       = character:WaitForChild("HumanoidRootPart")
local humanoid  = character:WaitForChild("Humanoid")

local Config    = require(RS:WaitForChild("GameConfig"))
local RE_Shoot  = RS:WaitForChild("RE_ShootWeapon")
local RE_Flash  = RS:WaitForChild("RE_CopFlash")

local camera    = workspace.CurrentCamera

-- ── Shoot cooldown ────────────────────────────────────────────────────
local canShoot   = true
local shootSFX   = nil  -- sound played on shoot

-- ── Muzzle flash effect (client-side visual) ──────────────────────────
local function showMuzzleFlash(pos)
    local flash = Instance.new("Part")
    flash.Size      = Vector3.new(1, 1, 1)
    flash.Shape     = Enum.PartType.Ball
    flash.Material  = Enum.Material.Neon
    flash.BrickColor= BrickColor.new("Bright yellow")
    flash.Anchored  = true
    flash.CanCollide= false
    flash.CFrame    = CFrame.new(pos)
    flash.Parent    = workspace
    game:GetService("Debris"):AddItem(flash, 0.15)
end

RE_Flash.OnClientEvent:Connect(function(copPos)
    showMuzzleFlash(copPos)
end)

-- ── Shoot on mouse click ───────────────────────────────────────────────
mouse.Button1Down:Connect(function()
    if not canShoot then return end
    if humanoid.Health <= 0 then return end

    -- Check player has a weapon
    local wVal = player:FindFirstChild("WeaponTier")
    if not wVal or wVal.Value < 1 then
        -- No weapon — show hint
        local hint = Instance.new("ScreenGui")
        hint.Name        = "NoWeaponHint"
        hint.ResetOnSpawn= false
        hint.Parent      = player.PlayerGui
        local lbl = Instance.new("TextLabel")
        lbl.Size         = UDim2.new(0.4, 0, 0.06, 0)
        lbl.Position     = UDim2.new(0.3, 0, 0.45, 0)
        lbl.BackgroundColor3 = Color3.new(0,0,0)
        lbl.BackgroundTransparency = 0.4
        lbl.TextColor3   = Color3.fromRGB(255,200,0)
        lbl.Font         = Enum.Font.GothamBold
        lbl.TextScaled   = true
        lbl.Text         = "Find a weapon chest first! (Press E)"
        lbl.Parent       = hint
        game:GetService("Debris"):AddItem(hint, 2)
        return
    end

    local tier       = wVal.Value
    local weaponData = Config.WEAPONS[tier]
    if not weaponData then return end

    canShoot = false

    -- Raycast from camera through mouse
    local origin    = hrp.Position + Vector3.new(0, 1.5, 0)
    local direction = (mouse.Hit.Position - origin).Unit

    -- Show client muzzle flash at player's position
    showMuzzleFlash(origin + direction * 2)

    -- Draw a quick tracer line
    local dist    = (mouse.Hit.Position - origin).Magnitude
    local tracer  = Instance.new("Part")
    tracer.Size   = Vector3.new(0.1, 0.1, math.min(dist, weaponData.range))
    tracer.CFrame = CFrame.lookAt(origin, origin + direction) *
                    CFrame.new(0, 0, -math.min(dist, weaponData.range)/2)
    tracer.Material    = Enum.Material.Neon
    tracer.BrickColor  = BrickColor.new("Bright yellow")
    tracer.Anchored    = true
    tracer.CanCollide  = false
    tracer.Parent      = workspace
    game:GetService("Debris"):AddItem(tracer, 0.08)

    -- Fire to server
    RE_Shoot:FireServer(origin, direction, tier)

    -- Cooldown based on weapon fire rate
    task.delay(weaponData.fireRate, function()
        canShoot = true
    end)
end)

-- ── Crosshair ─────────────────────────────────────────────────────────
local crosshairGui = Instance.new("ScreenGui")
crosshairGui.Name        = "Crosshair"
crosshairGui.ResetOnSpawn= false
crosshairGui.IgnoreGuiInset = true
crosshairGui.Parent      = player.PlayerGui

local ch = Instance.new("TextLabel")
ch.Size              = UDim2.new(0, 20, 0, 20)
ch.Position          = UDim2.new(0.5, -10, 0.5, -10)
ch.BackgroundTransparency = 1
ch.Text              = "+"
ch.TextColor3        = Color3.new(1, 1, 1)
ch.TextStrokeTransparency= 0
ch.Font              = Enum.Font.GothamBold
ch.TextSize          = 22
ch.Parent            = crosshairGui

-- Update crosshair color when aiming at a cop
RunS.RenderStepped:Connect(function()
    local wVal = player:FindFirstChild("WeaponTier")
    if not wVal or wVal.Value < 1 then
        ch.TextColor3 = Color3.fromRGB(180,180,180)
        return
    end
    local target = mouse.Target
    if target and target:FindFirstAncestor("Cop") then
        ch.TextColor3 = Color3.fromRGB(255, 60, 60)
    else
        ch.TextColor3 = Color3.new(1, 1, 1)
    end
end)

print("[WeaponHandler] Ready — click to shoot")
