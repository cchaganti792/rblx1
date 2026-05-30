-- PlayerUI.lua
-- LocalScript → StarterPlayerScripts
-- HUD: health bar, weapon display, diamond counter, cave label, map (press M), win/lose screen.

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local TweenS  = game:GetService("TweenService")
local UIS     = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player.PlayerGui

local RE_HUD  = RS:WaitForChild("RE_UpdateHUD")
local RE_Wpn  = RS:WaitForChild("RE_PickupWeapon")
local RE_Gem  = RS:WaitForChild("RE_PickupDiamond")
local RE_Won  = RS:WaitForChild("RE_GameWon")
local RE_Lost = RS:WaitForChild("RE_GameLost")
local RE_Dmg  = RS:WaitForChild("RE_TakeDamage")
local Config  = require(RS:WaitForChild("GameConfig"))

-- ── HUD ScreenGui ──────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "HUD" ; gui.ResetOnSpawn = false ; gui.IgnoreGuiInset = true
gui.Parent = playerGui

-- ── Health bar (bottom-left) ───────────────────────────────────────────
local hpBg = Instance.new("Frame")
hpBg.Size = UDim2.new(0,260,0,28) ; hpBg.Position = UDim2.new(0,20,1,-60)
hpBg.BackgroundColor3 = Color3.fromRGB(30,30,30) ; hpBg.BorderSizePixel = 0
hpBg.Parent = gui

local hpBar = Instance.new("Frame")
hpBar.Name = "HPBar" ; hpBar.Size = UDim2.new(1,0,1,0)
hpBar.BackgroundColor3 = Color3.fromRGB(60,200,60) ; hpBar.BorderSizePixel = 0
hpBar.Parent = hpBg

local hpLabel = Instance.new("TextLabel")
hpLabel.Size = UDim2.new(1,0,1,0) ; hpLabel.BackgroundTransparency = 1
hpLabel.Text = "HP: 100" ; hpLabel.TextColor3 = Color3.new(1,1,1)
hpLabel.Font = Enum.Font.GothamBold ; hpLabel.TextScaled = true
hpLabel.Parent = hpBg

-- ── Diamond counter (top-right) ────────────────────────────────────────
local gemFrame = Instance.new("Frame")
gemFrame.Size = UDim2.new(0,190,0,48) ; gemFrame.Position = UDim2.new(1,-210,0,20)
gemFrame.BackgroundColor3 = Color3.fromRGB(0,0,0) ; gemFrame.BackgroundTransparency = 0.4
gemFrame.BorderSizePixel = 0 ; gemFrame.Parent = gui

local gemLabel = Instance.new("TextLabel")
gemLabel.Name = "GemLabel" ; gemLabel.Size = UDim2.new(1,0,1,0)
gemLabel.BackgroundTransparency = 1
gemLabel.Text = "💎 0 / " .. Config.DIAMONDS_TO_WIN
gemLabel.TextColor3 = Color3.fromRGB(0,220,255)
gemLabel.Font = Enum.Font.GothamBold ; gemLabel.TextScaled = true
gemLabel.Parent = gemFrame

-- ── Weapon display (bottom-right) ─────────────────────────────────────
local wpnFrame = Instance.new("Frame")
wpnFrame.Size = UDim2.new(0,190,0,48) ; wpnFrame.Position = UDim2.new(1,-210,1,-70)
wpnFrame.BackgroundColor3 = Color3.fromRGB(0,0,0) ; wpnFrame.BackgroundTransparency = 0.4
wpnFrame.BorderSizePixel = 0 ; wpnFrame.Parent = gui

local wpnLabel = Instance.new("TextLabel")
wpnLabel.Name = "WpnLabel" ; wpnLabel.Size = UDim2.new(1,0,1,0)
wpnLabel.BackgroundTransparency = 1
wpnLabel.Text = "🔫 No Weapon" ; wpnLabel.TextColor3 = Color3.fromRGB(255,220,100)
wpnLabel.Font = Enum.Font.GothamBold ; wpnLabel.TextScaled = true
wpnLabel.Parent = wpnFrame

-- ── Cave indicator (top-left) ──────────────────────────────────────────
local caveFrame = Instance.new("Frame")
caveFrame.Size = UDim2.new(0,180,0,42) ; caveFrame.Position = UDim2.new(0,20,0,20)
caveFrame.BackgroundColor3 = Color3.fromRGB(0,0,0) ; caveFrame.BackgroundTransparency = 0.4
caveFrame.BorderSizePixel = 0 ; caveFrame.Parent = gui

local caveLabel = Instance.new("TextLabel")
caveLabel.Name = "CaveLabel" ; caveLabel.Size = UDim2.new(1,0,1,0)
caveLabel.BackgroundTransparency = 1 ; caveLabel.Text = "Cave: --"
caveLabel.TextColor3 = Color3.new(1,1,1)
caveLabel.Font = Enum.Font.Gotham ; caveLabel.TextScaled = true
caveLabel.Parent = caveFrame

-- ── Map key hint ───────────────────────────────────────────────────────
local mapHint = Instance.new("TextLabel")
mapHint.Size = UDim2.new(0,160,0,28) ; mapHint.Position = UDim2.new(0,20,0,68)
mapHint.BackgroundTransparency = 1
mapHint.Text = "[M] Toggle Map"
mapHint.TextColor3 = Color3.fromRGB(180,180,180)
mapHint.Font = Enum.Font.Gotham ; mapHint.TextScaled = true
mapHint.Parent = gui

-- ── Damage flash ───────────────────────────────────────────────────────
local dmgFlash = Instance.new("Frame")
dmgFlash.Size = UDim2.new(1,0,1,0) ; dmgFlash.BackgroundColor3 = Color3.fromRGB(255,0,0)
dmgFlash.BackgroundTransparency = 1 ; dmgFlash.BorderSizePixel = 0
dmgFlash.ZIndex = 8 ; dmgFlash.Parent = gui

-- ── Weapon pickup notification ─────────────────────────────────────────
local function showPickupNotif(text)
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0,300,0,50) ; notif.Position = UDim2.new(0.5,-150,0.6,0)
    notif.BackgroundColor3 = Color3.fromRGB(30,30,30)
    notif.BackgroundTransparency = 0.2 ; notif.BorderSizePixel = 0
    notif.ZIndex = 7 ; notif.Parent = gui

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1,0,1,0) ; tl.BackgroundTransparency = 1
    tl.Text = text ; tl.TextColor3 = Color3.fromRGB(255,220,50)
    tl.Font = Enum.Font.GothamBold ; tl.TextScaled = true ; tl.ZIndex = 7
    tl.Parent = notif

    TweenS:Create(notif, TweenInfo.new(0.5), {BackgroundTransparency=0.2}):Play()
    task.delay(2, function()
        TweenS:Create(notif, TweenInfo.new(0.5), {BackgroundTransparency=1}):Play()
        TweenS:Create(tl, TweenInfo.new(0.5), {TextTransparency=1}):Play()
        task.delay(0.5, function() notif:Destroy() end)
    end)
end

-- ────────────────────────────────────────────────────────────────────────
-- MAP SYSTEM
-- ────────────────────────────────────────────────────────────────────────

-- Cave grid positions for map (row, col) — 1-indexed
local CAVE_GRID = {
    [1]={row=1,col=1}, [2]={row=1,col=2}, [3]={row=1,col=3},
    [4]={row=2,col=1}, [5]={row=2,col=2}, [6]={row=2,col=3},
    [7]={row=3,col=1}, [8]={row=3,col=2}, [9]={row=3,col=3},
}

local MAP_CELL   = 60   -- px per cave cell
local MAP_GAP    = 18   -- px gap (tunnel) between cells
local MAP_TOTAL  = 3 * MAP_CELL + 2 * MAP_GAP  -- 216px

local mapGui = Instance.new("ScreenGui")
mapGui.Name = "MapGui" ; mapGui.ResetOnSpawn = false ; mapGui.IgnoreGuiInset = true
mapGui.Enabled = false
mapGui.Parent = playerGui

-- Map background panel
local mapPanel = Instance.new("Frame")
mapPanel.Size = UDim2.new(0, MAP_TOTAL + 40, 0, MAP_TOTAL + 80)
mapPanel.Position = UDim2.new(0.5, -(MAP_TOTAL+40)/2, 0.5, -(MAP_TOTAL+80)/2)
mapPanel.BackgroundColor3 = Color3.fromRGB(20,15,10)
mapPanel.BackgroundTransparency = 0.1
mapPanel.BorderSizePixel = 0
mapPanel.Parent = mapGui

-- Map title
local mapTitle = Instance.new("TextLabel")
mapTitle.Size = UDim2.new(1,0,0,35) ; mapTitle.Position = UDim2.new(0,0,0,0)
mapTitle.BackgroundTransparency = 1 ; mapTitle.Text = "CAVE MAP  [M to close]"
mapTitle.TextColor3 = Color3.fromRGB(255,220,80)
mapTitle.Font = Enum.Font.GothamBold ; mapTitle.TextScaled = true
mapTitle.Parent = mapPanel

-- Map legend
local legend = Instance.new("TextLabel")
legend.Size = UDim2.new(1,0,0,22) ; legend.Position = UDim2.new(0,0,1,-24)
legend.BackgroundTransparency = 1
legend.Text = "■ Safe  ■ Guarded  ■ Diamond  ★ You"
legend.TextColor3 = Color3.fromRGB(180,180,180)
legend.Font = Enum.Font.Gotham ; legend.TextScaled = true
legend.Parent = mapPanel

-- Cave cell frames
local caveCells = {}

local function cellX(col) return 20 + (col-1) * (MAP_CELL + MAP_GAP) end
local function cellY(row) return 40 + (row-1) * (MAP_CELL + MAP_GAP) end

for id, data in pairs(Config.CAVES) do
    local g    = CAVE_GRID[id]
    local cell = Instance.new("Frame")
    cell.Name  = "Cave_" .. id
    cell.Size  = UDim2.new(0, MAP_CELL, 0, MAP_CELL)
    cell.Position = UDim2.new(0, cellX(g.col), 0, cellY(g.row))
    cell.BorderSizePixel = 2
    cell.BorderColor3 = Color3.fromRGB(80,80,80)

    if data.isDiamond then
        cell.BackgroundColor3 = Color3.fromRGB(0,80,120)
    elseif data.guarded then
        cell.BackgroundColor3 = Color3.fromRGB(100,40,20)
    else
        cell.BackgroundColor3 = Color3.fromRGB(40,50,40)
    end
    cell.Parent = mapPanel

    -- Cave number label
    local numL = Instance.new("TextLabel")
    numL.Size = UDim2.new(1,0,0.45,0) ; numL.BackgroundTransparency = 1
    numL.Text = tostring(id) .. (data.isDiamond and " 💎" or data.guarded and " ⚠" or "")
    numL.TextColor3 = Color3.new(1,1,1)
    numL.Font = Enum.Font.GothamBold ; numL.TextScaled = true
    numL.Parent = cell

    -- "YOU ARE HERE" indicator
    local here = Instance.new("TextLabel")
    here.Name = "HereLabel"
    here.Size = UDim2.new(1,0,0.45,0) ; here.Position = UDim2.new(0,0,0.5,0)
    here.BackgroundTransparency = 1 ; here.Text = ""
    here.TextColor3 = Color3.fromRGB(255,255,0)
    here.Font = Enum.Font.GothamBold ; here.TextScaled = true
    here.Parent = cell

    caveCells[id] = cell
end

-- Draw tunnel connections (thin rectangles between cells)
local drawnConns = {}
for idA, data in pairs(Config.CAVES) do
    for _, idB in ipairs(data.connections) do
        local key = math.min(idA,idB) .. "_" .. math.max(idA,idB)
        if not drawnConns[key] then
            drawnConns[key] = true
            local gA = CAVE_GRID[idA]
            local gB = CAVE_GRID[idB]
            local tunnel = Instance.new("Frame")
            tunnel.BackgroundColor3 = Color3.fromRGB(70,60,50)
            tunnel.BorderSizePixel = 0

            local dr = gB.row - gA.row
            local dc = gB.col - gA.col

            if dc == 1 then
                -- Horizontal tunnel (A is left of B)
                tunnel.Size = UDim2.new(0, MAP_GAP, 0, 10)
                tunnel.Position = UDim2.new(0,
                    cellX(gA.col) + MAP_CELL,
                    0,
                    cellY(gA.row) + MAP_CELL/2 - 5)
            elseif dr == 1 then
                -- Vertical tunnel (A is above B)
                tunnel.Size = UDim2.new(0, 10, 0, MAP_GAP)
                tunnel.Position = UDim2.new(0,
                    cellX(gA.col) + MAP_CELL/2 - 5,
                    0,
                    cellY(gA.row) + MAP_CELL)
            end
            tunnel.Parent = mapPanel
        end
    end
end

-- Track current cave for map highlighting
local currentCaveId = 0

local function updateMapHighlight(caveId)
    for id, cell in pairs(caveCells) do
        local here = cell:FindFirstChild("HereLabel")
        if id == caveId then
            cell.BorderColor3 = Color3.fromRGB(255,255,0)
            cell.BorderSizePixel = 3
            if here then here.Text = "★ YOU" end
        else
            cell.BorderColor3 = Color3.fromRGB(80,80,80)
            cell.BorderSizePixel = 2
            if here then here.Text = "" end
        end
    end
end

-- Toggle map with M key
local mapOpen = false
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.M then
        mapOpen = not mapOpen
        mapGui.Enabled = mapOpen
        if mapOpen then updateMapHighlight(currentCaveId) end
    end
end)

-- ── Win / Lose screen ─────────────────────────────────────────────────
local function showEndScreen(won)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,1,0) ; frame.BackgroundColor3 = Color3.new(0,0,0)
    frame.BackgroundTransparency = 0.3 ; frame.ZIndex = 15 ; frame.Parent = gui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.6,0,0.2,0) ; title.Position = UDim2.new(0.2,0,0.35,0)
    title.BackgroundTransparency = 1 ; title.Font = Enum.Font.GothamBold
    title.TextScaled = true ; title.ZIndex = 16 ; title.Parent = frame

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(0.6,0,0.1,0) ; sub.Position = UDim2.new(0.2,0,0.56,0)
    sub.BackgroundTransparency = 1 ; sub.Font = Enum.Font.Gotham
    sub.TextScaled = true ; sub.ZIndex = 16 ; sub.Parent = frame

    if won then
        title.Text = "YOU ESCAPED! 💎"
        title.TextColor3 = Color3.fromRGB(0,255,100)
        sub.Text = "The diamonds are yours. Well played."
    else
        title.Text = "BUSTED!"
        title.TextColor3 = Color3.fromRGB(255,60,60)
        sub.Text = "The cops got you. Try again."
    end
    sub.TextColor3 = Color3.new(1,1,1)
end

-- ── Remote event listeners ─────────────────────────────────────────────
RE_HUD.OnClientEvent:Connect(function(health, diamonds, caveId)
    local ratio = math.clamp(health / Config.MAX_HEALTH, 0, 1)
    hpBar.Size = UDim2.new(ratio, 0, 1, 0)
    hpBar.BackgroundColor3 = ratio > 0.5 and Color3.fromRGB(60,200,60)
        or ratio > 0.25 and Color3.fromRGB(220,180,0)
        or Color3.fromRGB(220,60,60)
    hpLabel.Text = "HP: " .. math.max(0, math.floor(health))
    gemLabel.Text = "💎 " .. diamonds .. " / " .. Config.DIAMONDS_TO_WIN

    if caveId and caveId > 0 then
        currentCaveId = caveId
        local cData = Config.CAVES[caveId]
        if cData then
            if cData.isDiamond then
                caveLabel.Text = "💎 DIAMOND CAVE"
                caveLabel.TextColor3 = Color3.fromRGB(0,220,255)
            elseif cData.guarded then
                caveLabel.Text = "Cave " .. caveId .. " ⚠ DANGER"
                caveLabel.TextColor3 = Color3.fromRGB(255,120,60)
            else
                caveLabel.Text = "Cave " .. caveId .. " — Safe"
                caveLabel.TextColor3 = Color3.new(1,1,1)
            end
        end
    end
end)

RE_Wpn.OnClientEvent:Connect(function(tier, name)
    wpnLabel.Text = "🔫 " .. name .. " (Tier " .. tier .. ")"
    showPickupNotif("Found: " .. name .. "!")
end)

RE_Gem.OnClientEvent:Connect(function(count)
    gemLabel.Text = "💎 " .. count .. " / " .. Config.DIAMONDS_TO_WIN
    TweenS:Create(gemFrame, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(0,200,255)}):Play()
    task.delay(0.4, function()
        TweenS:Create(gemFrame, TweenInfo.new(0.3), {BackgroundColor3=Color3.new(0,0,0)}):Play()
    end)
    if count >= Config.DIAMONDS_TO_WIN then
        showPickupNotif("Get to the EXIT to win!")
    end
end)

RE_Dmg.OnClientEvent:Connect(function()
    dmgFlash.BackgroundTransparency = 0.45
    TweenS:Create(dmgFlash, TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
end)

RE_Won.OnClientEvent:Connect(function() showEndScreen(true) end)
RE_Lost.OnClientEvent:Connect(function() showEndScreen(false) end)

print("[PlayerUI] HUD + Map ready")
