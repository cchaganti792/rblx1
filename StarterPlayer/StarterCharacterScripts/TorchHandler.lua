-- TorchHandler.lua
-- LocalScript → StarterPlayer/StarterCharacterScripts

local RS        = game:GetService("ReplicatedStorage")
local Players   = game:GetService("Players")
local UIS       = game:GetService("UserInputService")
local Debris    = game:GetService("Debris")

local player    = Players.LocalPlayer
local character = script.Parent
local hrp       = character:WaitForChild("HumanoidRootPart")

local RE_Torch  = RS:WaitForChild("RE_GiveTorch")

local torchLight = nil
local torchFlame = nil
local torchOn    = true

-- ── Toggle torch on/off with T ────────────────────────────────────────
UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.T then
		if not torchLight then return end  -- no torch yet
		torchOn = not torchOn
		torchLight.Enabled      = torchOn
		torchFlame.Transparency = torchOn and 0 or 0.85
	end
end)

RE_Torch.OnClientEvent:Connect(function()
	-- Clean up any old torch from a previous life
	local old = character:FindFirstChild("TorchHandle")
	if old then old:Destroy() end
	torchOn = true

	-- ── Torch handle ──────────────────────────────────────────────────
	local handle = Instance.new("Part")
	handle.Name       = "TorchHandle"
	handle.Size       = Vector3.new(0.28, 1.5, 0.28)
	handle.BrickColor = BrickColor.new("Reddish brown")
	handle.Material   = Enum.Material.Wood
	handle.Anchored   = false
	handle.CanCollide = false
	handle.CastShadow = false
	handle.CFrame     = hrp.CFrame * CFrame.new(1.3, -0.35, -0.9)
	handle.Parent     = character

	-- ── Flame ball on top ─────────────────────────────────────────────
	local flame = Instance.new("Part")
	flame.Name        = "TorchFlame"
	flame.Size        = Vector3.new(0.65, 0.72, 0.65)
	flame.Shape       = Enum.PartType.Ball
	flame.BrickColor  = BrickColor.new("Bright orange")
	flame.Material    = Enum.Material.Neon
	flame.Anchored    = false
	flame.CanCollide  = false
	flame.CastShadow  = false
	flame.CFrame      = handle.CFrame * CFrame.new(0, 1.08, 0)
	flame.Parent      = character

	-- ── Point light ───────────────────────────────────────────────────
	local light = Instance.new("PointLight")
	light.Brightness = 4
	light.Range      = 32
	light.Color      = Color3.fromRGB(255, 150, 50)
	light.Parent     = flame

	-- Store references for toggle
	torchLight = light
	torchFlame = flame

	-- ── Weld handle to HRP ────────────────────────────────────────────
	local weld1 = Instance.new("WeldConstraint")
	weld1.Part0 = hrp ; weld1.Part1 = handle ; weld1.Parent = handle

	-- ── Weld flame to handle ──────────────────────────────────────────
	local weld2 = Instance.new("WeldConstraint")
	weld2.Part0 = handle ; weld2.Part1 = flame ; weld2.Parent = flame

	-- ── Pickup notification ───────────────────────────────────────────
	local hint = Instance.new("ScreenGui")
	hint.Name = "TorchHint" ; hint.ResetOnSpawn = false ; hint.Parent = player.PlayerGui
	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(0.45, 0, 0.07, 0)
	lbl.Position               = UDim2.new(0.275, 0, 0.44, 0)
	lbl.BackgroundColor3       = Color3.new(0, 0, 0)
	lbl.BackgroundTransparency = 0.4
	lbl.TextColor3             = Color3.fromRGB(255, 210, 80)
	lbl.Font                   = Enum.Font.GothamBold
	lbl.TextScaled             = true
	lbl.Text                   = "Torch equipped!  Press T to toggle on/off"
	lbl.Parent                 = hint
	Debris:AddItem(hint, 4)
end)
