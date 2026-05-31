-- TorchHandler.lua
-- LocalScript → StarterPlayer/StarterCharacterScripts
-- Creates the held torch visual + PointLight on the player's character

local RS        = game:GetService("ReplicatedStorage")
local Players   = game:GetService("Players")
local Debris    = game:GetService("Debris")

local player    = Players.LocalPlayer
local character = script.Parent
local hrp       = character:WaitForChild("HumanoidRootPart")

local RE_Torch  = RS:WaitForChild("RE_GiveTorch")

RE_Torch.OnClientEvent:Connect(function()
	-- Clean up any old torch from a previous life
	local old = character:FindFirstChild("TorchHandle")
	if old then old:Destroy() end

	-- ── Torch handle ──────────────────────────────────────────────────
	local handle = Instance.new("Part")
	handle.Name       = "TorchHandle"
	handle.Size       = Vector3.new(0.28, 1.5, 0.28)
	handle.BrickColor = BrickColor.new("Reddish brown")
	handle.Material   = Enum.Material.Wood
	handle.Anchored   = false
	handle.CanCollide = false
	handle.CastShadow = false
	-- Position to the right side of player before welding
	handle.CFrame = hrp.CFrame * CFrame.new(1.3, -0.35, -0.9)
	handle.Parent = character

	-- ── Flame ball on top ─────────────────────────────────────────────
	local flame = Instance.new("Part")
	flame.Name       = "TorchFlame"
	flame.Size       = Vector3.new(0.65, 0.72, 0.65)
	flame.Shape      = Enum.PartType.Ball
	flame.BrickColor = BrickColor.new("Bright orange")
	flame.Material   = Enum.Material.Neon
	flame.Anchored   = false
	flame.CanCollide = false
	flame.CastShadow = false
	flame.CFrame     = handle.CFrame * CFrame.new(0, 1.08, 0)
	flame.Parent     = character

	-- ── Point light that actually lights the cave ─────────────────────
	local light = Instance.new("PointLight")
	light.Brightness = 4
	light.Range      = 32
	light.Color      = Color3.fromRGB(255, 150, 50)
	light.Parent     = flame

	-- ── Weld handle rigidly to HumanoidRootPart ───────────────────────
	local weld1 = Instance.new("WeldConstraint")
	weld1.Part0  = hrp
	weld1.Part1  = handle
	weld1.Parent = handle

	-- ── Weld flame to top of handle ───────────────────────────────────
	local weld2 = Instance.new("WeldConstraint")
	weld2.Part0  = handle
	weld2.Part1  = flame
	weld2.Parent = flame

	-- ── Pickup notification ───────────────────────────────────────────
	local hint = Instance.new("ScreenGui")
	hint.Name         = "TorchHint"
	hint.ResetOnSpawn = false
	hint.Parent       = player.PlayerGui

	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(0.4, 0, 0.06, 0)
	lbl.Position               = UDim2.new(0.3, 0, 0.45, 0)
	lbl.BackgroundColor3       = Color3.new(0, 0, 0)
	lbl.BackgroundTransparency = 0.4
	lbl.TextColor3             = Color3.fromRGB(255, 210, 80)
	lbl.Font                   = Enum.Font.GothamBold
	lbl.TextScaled             = true
	lbl.Text                   = "Torch equipped — you can see in the dark!"
	lbl.Parent                 = hint

	Debris:AddItem(hint, 3)
end)
