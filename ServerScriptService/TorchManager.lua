-- TorchManager.lua
-- Script → ServerScriptService
-- Places torch chests in spawn caves and handles pickup logic

local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Config  = require(RS:WaitForChild("GameConfig"))

local FY = Config.FLOOR_Y

local function getRemote(name)
	local re = RS:FindFirstChild(name)
	if not re then
		re = Instance.new("RemoteEvent")
		re.Name = name ; re.Parent = RS
	end
	return re
end

local RE_Torch = getRemote("RE_GiveTorch")

local playerHasTorch = {}

-- ── Build a torch chest in a cave ─────────────────────────────────────
local function buildTorchChest(caveId)
	local cave = Config.CAVES[caveId]
	local cx   = cave.center.X
	local cz   = cave.center.Z

	-- Wooden chest
	local chest = Instance.new("Part")
	chest.Name       = "TorchChest"
	chest.Size       = Vector3.new(3, 2, 2)
	chest.CFrame     = CFrame.new(cx - 10, FY + 1, cz + 10)
	chest.Anchored   = true
	chest.BrickColor = BrickColor.new("Brown")
	chest.Material   = Enum.Material.Wood
	chest.Parent     = workspace

	-- Small handle on front
	local knob = Instance.new("Part")
	knob.Size      = Vector3.new(0.3, 0.3, 0.3)
	knob.Shape     = Enum.PartType.Ball
	knob.BrickColor= BrickColor.new("Bright yellow")
	knob.Material  = Enum.Material.Metal
	knob.Anchored  = true
	knob.CanCollide= false
	knob.CFrame    = CFrame.new(cx - 10, FY + 1, cz + 9)
	knob.Parent    = workspace

	-- Glowing flame above chest so player can spot it in the dark
	local glow = Instance.new("Part")
	glow.Name       = "TorchChestGlow"
	glow.Size       = Vector3.new(0.8, 0.8, 0.8)
	glow.Shape      = Enum.PartType.Ball
	glow.BrickColor = BrickColor.new("Bright orange")
	glow.Material   = Enum.Material.Neon
	glow.Anchored   = true
	glow.CanCollide = false
	glow.CFrame     = CFrame.new(cx - 10, FY + 3, cz + 10)
	glow.Parent     = workspace

	local light = Instance.new("PointLight")
	light.Brightness = 2 ; light.Range = 16 ; light.Color = Color3.fromRGB(255, 150, 40)
	light.Parent = glow

	-- Floating label visible in the dark
	local bg = Instance.new("BillboardGui")
	bg.Size         = UDim2.new(0, 160, 0, 50)
	bg.StudsOffset  = Vector3.new(0, 2.5, 0)
	bg.AlwaysOnTop  = false
	bg.Parent       = glow

	local lbl = Instance.new("TextLabel")
	lbl.Size                  = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency= 1
	lbl.Text                  = "TORCH\n(Press F)"
	lbl.TextColor3            = Color3.fromRGB(255, 210, 80)
	lbl.Font                  = Enum.Font.GothamBold
	lbl.TextScaled            = true
	lbl.Parent                = bg

	-- ProximityPrompt on the chest
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText            = "Pick up Torch"
	pp.ObjectText            = "Torch Chest"
	pp.KeyboardKeyCode       = Enum.KeyCode.F
	pp.MaxActivationDistance = 8
	pp.Parent                = chest

	pp.Triggered:Connect(function(player)
		if playerHasTorch[player] then return end
		playerHasTorch[player] = true
		RE_Torch:FireClient(player)
		-- Dim the chest flame to show it's been taken
		pp.Enabled      = false
		glow.BrickColor = BrickColor.new("Medium stone grey")
		light:Destroy()
		lbl.Text        = "Empty"
		lbl.TextColor3  = Color3.fromRGB(150, 150, 150)
	end)
end

-- ── Re-give torch when player respawns ────────────────────────────────
local function hookRespawn(player)
	player.CharacterAdded:Connect(function()
		if playerHasTorch[player] then
			task.wait(1.5)   -- let character finish loading
			RE_Torch:FireClient(player)
		end
	end)
end

Players.PlayerAdded:Connect(hookRespawn)
for _, player in ipairs(Players:GetPlayers()) do
	hookRespawn(player)
end

Players.PlayerRemoving:Connect(function(player)
	playerHasTorch[player] = nil
end)

-- ── Wait for CaveBuilder then place chests ────────────────────────────
task.wait(5)
for _, caveId in ipairs(Config.SPAWN_CAVES) do
	buildTorchChest(caveId)
end

print("[TorchManager] Torch chests placed in spawn caves")
