-- CaveBuilder.lua
-- Script → ServerScriptService

local RS     = game:GetService("ReplicatedStorage")
local Config = require(RS:WaitForChild("GameConfig"))

local W  = Config.CAVE_W
local D  = Config.CAVE_D
local H  = Config.CAVE_H
local WT = Config.WALL_T
local TW = Config.TUNNEL_W
local TH = Config.TUNNEL_H
local SP = Config.SPACING
local HW = W / 2
local HD = D / 2
local FY = Config.FLOOR_Y

local FLOOR_CY = 0
local CEIL_CY  = 24
local WALL_CY  = 12
local WALL_H   = 24

local MAT_ROCK   = Enum.Material.Rock
local MAT_GROUND = Enum.Material.Ground
local MAT_WOOD   = Enum.Material.Wood
local MAT_NEON   = Enum.Material.Neon
local MAT_SLATE  = Enum.Material.Slate
local MAT_GLASS  = Enum.Material.Glass
local MAT_SMOOTH = Enum.Material.SmoothPlastic
local MAT_MARBLE = Enum.Material.Marble

local COL_ROCK   = BrickColor.new("Dark stone grey")
local COL_DIRT   = BrickColor.new("Reddish brown")
local COL_WOOD   = BrickColor.new("Reddish brown")
local COL_FLAME  = BrickColor.new("Bright orange")
local COL_STONE  = BrickColor.new("Medium stone grey")
local COL_DIAM   = BrickColor.new("Cyan")
local COL_COAL   = BrickColor.new("Really black")
local COL_IRON   = BrickColor.new("Rust")
local COL_QUARTZ = BrickColor.new("White")

local CaveFolder = Instance.new("Folder")
CaveFolder.Name   = "Caves"
CaveFolder.Parent = workspace

-- ── Part factory ──────────────────────────────────────────────────────
local function p(parent, sz, cf, col, mat, transp, nocol)
	local part = Instance.new("Part")
	part.Size         = sz
	part.CFrame       = cf
	part.Anchored     = true
	part.BrickColor   = col or COL_ROCK
	part.Material     = mat or MAT_ROCK
	part.Transparency = transp or 0
	part.CanCollide   = not nocol
	part.CastShadow   = false
	part.Parent       = parent
	return part
end

-- ── Sphere helper ─────────────────────────────────────────────────────
local function ball(parent, sz, pos, col, mat, nocol, transp)
	local b = p(parent, Vector3.new(sz,sz,sz), CFrame.new(pos), col, mat, transp or 0, nocol)
	b.Shape = Enum.PartType.Ball
	return b
end

-- ── Torch ─────────────────────────────────────────────────────────────
local function makeTorch(parent, position, facingDir)
	local bracket = p(parent, Vector3.new(0.5,0.5,0.5), CFrame.new(position), COL_STONE, MAT_SLATE, 0, false)
	bracket.Name = "TorchBracket"
	local stickPos = position + Vector3.new(0, 0.8, 0) + facingDir * 0.3
	p(parent, Vector3.new(0.3, 1.4, 0.3),
		CFrame.new(stickPos) * CFrame.Angles(0, 0, math.rad(15) * (facingDir.X ~= 0 and facingDir.X or facingDir.Z)),
		COL_WOOD, MAT_WOOD, 0, false).Name = "TorchStick"
	local flamePos = stickPos + Vector3.new(0, 1, 0)
	local flame = p(parent, Vector3.new(0.6, 0.8, 0.6), CFrame.new(flamePos), COL_FLAME, MAT_SMOOTH, 0, false)
	flame.Name  = "TorchFlame"
	flame.Shape = Enum.PartType.Ball
end

-- ── Wall torches ──────────────────────────────────────────────────────
local function placeTorches(model, cx, cz)
	local y = FY + 5
	makeTorch(model, Vector3.new(cx - 22, y, cz - HW + 1), Vector3.new(0,0,1))
	makeTorch(model, Vector3.new(cx + 22, y, cz - HW + 1), Vector3.new(0,0,1))
	makeTorch(model, Vector3.new(cx - 22, y, cz + HW - 1), Vector3.new(0,0,-1))
	makeTorch(model, Vector3.new(cx + 22, y, cz + HW - 1), Vector3.new(0,0,-1))
	makeTorch(model, Vector3.new(cx - HD + 1, y, cz - 22), Vector3.new(1,0,0))
	makeTorch(model, Vector3.new(cx - HD + 1, y, cz + 22), Vector3.new(1,0,0))
	makeTorch(model, Vector3.new(cx + HD - 1, y, cz - 22), Vector3.new(-1,0,0))
	makeTorch(model, Vector3.new(cx + HD - 1, y, cz + 22), Vector3.new(-1,0,0))
end

-- ── Ore cluster: sphere nodules embedded in wall ─────────────────────
-- Spheres look like actual mineral deposits, not flat patches
local function makeOreCluster(model, wallPos, col, mat)
	local n = math.random(5, 8)
	for i = 1, n do
		local sz = math.random(18, 52) / 100
		local b = ball(model, sz,
			Vector3.new(
				wallPos.X + math.random(-45, 45)/100,
				wallPos.Y + math.random(-45, 45)/100,
				wallPos.Z + math.random(-8, 4)/100),
			col, mat, false)
		b.Name = "Ore"
	end
end

-- ── Place all ore types on walls ──────────────────────────────────────
local function placeOreVeins(model, cx, cz, isDiamond)
	local function wpos(margin)
		local f = math.random(1, 4)
		if     f == 1 then return Vector3.new(cx + math.random(-30,30), FY + math.random(1,11), cz - HW + margin)
		elseif f == 2 then return Vector3.new(cx + math.random(-30,30), FY + math.random(1,11), cz + HW - margin)
		elseif f == 3 then return Vector3.new(cx - HD + margin, FY + math.random(1,11), cz + math.random(-30,30))
		else               return Vector3.new(cx + HD - margin, FY + math.random(1,11), cz + math.random(-30,30)) end
	end

	-- Coal seams: dark sphere clusters in wall
	for i = 1, 6 do
		makeOreCluster(model, wpos(0.5), COL_COAL, MAT_SMOOTH)
	end
	-- Iron ore: rust-coloured sphere clusters
	for i = 1, 4 do
		makeOreCluster(model, wpos(0.6), COL_IRON, MAT_ROCK)
	end
	-- Quartz: white streaks (small tight sphere cluster)
	for i = 1, 3 do
		makeOreCluster(model, wpos(0.5), COL_QUARTZ, MAT_MARBLE)
	end
	-- Diamond veins: cyan glass sphere clusters (visible in torch light)
	local dCount = isDiamond and 12 or 3
	for i = 1, dCount do
		makeOreCluster(model, wpos(0.4), COL_DIAM, MAT_GLASS)
	end

	-- Crystal spikes on floor (diamond cave): tapered 4-segment columns
	if isDiamond then
		for i = 1, 8 do
			local crx = cx + math.random(-32, 32)
			local crz = cz + math.random(-32, 32)
			local totalH = math.random(3, 7)
			local angle  = CFrame.Angles(math.rad(math.random(-18,18)), math.rad(math.random(0,360)), 0)
			-- 4 segments, decreasing width as they go up
			local widths = {1.4, 0.95, 0.55, 0.25}
			for s = 1, 4 do
				local segH  = totalH / 4
				local yC    = FY + (s - 0.5) * segH
				local diam  = widths[s]
				local seg = p(model, Vector3.new(diam, segH, diam),
					CFrame.new(crx, yC, crz) * angle,
					COL_DIAM, MAT_GLASS, 0, false)
				seg.Name = "Crystal"
			end
		end
	end
end

-- ── Stalactite: tapered 3-segment shape ──────────────────────────────
local function makeStalactite(model, x, z, fromCeil)
	local totalH = math.random(3, 10)
	local baseW  = math.random(10, 22) / 10
	-- 3 segments, widest at top (root) narrowing to a point at bottom
	local segs   = {{1.0, baseW}, {0.55, baseW*0.55}, {0.2, baseW*0.22}}
	local col    = math.random() > 0.5 and COL_STONE or COL_ROCK

	for s, seg in ipairs(segs) do
		local frac  = seg[1]
		local diam  = seg[2]
		local segH  = totalH * frac * 0.6
		local yC
		if fromCeil then
			yC = Config.CEIL_Y - (s == 1 and segH*0.5 or
				(s == 2 and totalH*0.6*segs[1][1] + segH*0.5 or
				totalH*0.6*(segs[1][1]+segs[2][1]) + segH*0.5))
		else
			yC = FY + (s == 1 and segH*0.5 or
				(s == 2 and totalH*0.6*segs[1][1] + segH*0.5 or
				totalH*0.6*(segs[1][1]+segs[2][1]) + segH*0.5))
		end
		p(model, Vector3.new(diam, segH, diam), CFrame.new(x, yC, z), col, MAT_SLATE).Name =
			fromCeil and "Stalactite" or "Stalagmite"
	end
end

-- ── Dense rock protrusions on cave walls ─────────────────────────────
-- Overlapping angled rock masses make flat walls look like natural stone
local function addWallRockFace(model, cx, cz)
	for _, face in ipairs({"N","S","E","W"}) do
		for i = 1, 11 do
			local rw  = math.random(4, 13)
			local rh  = math.random(3, 11)
			local rd  = math.random(6, 20) / 10
			local ry  = FY + math.random(2, 17)
			local rot = CFrame.Angles(
				math.rad(math.random(-18,18)),
				math.rad(math.random(-25,25)),
				math.rad(math.random(-18,18)))
			local col = (math.random() > 0.6) and COL_STONE or COL_ROCK
			if face == "N" then
				local xp = cx + math.random(-(HW-10), HW-10)
				p(model, Vector3.new(rw, rh, rd),
					CFrame.new(xp, ry, cz - HW + WT/2 + rd/2) * rot, col, MAT_ROCK, 0, false)
			elseif face == "S" then
				local xp = cx + math.random(-(HW-10), HW-10)
				p(model, Vector3.new(rw, rh, rd),
					CFrame.new(xp, ry, cz + HW - WT/2 - rd/2) * rot, col, MAT_ROCK, 0, false)
			elseif face == "W" then
				local zp = cz + math.random(-(HD-10), HD-10)
				p(model, Vector3.new(rd, rh, rw),
					CFrame.new(cx - HW + WT/2 + rd/2, ry, zp) * rot, col, MAT_ROCK, 0, false)
			elseif face == "E" then
				local zp = cz + math.random(-(HD-10), HD-10)
				p(model, Vector3.new(rd, rh, rw),
					CFrame.new(cx + HW - WT/2 - rd/2, ry, zp) * rot, col, MAT_ROCK, 0, false)
			end
		end
	end
end

-- ── Round boxy corners: large 45-degree rock masses ───────────────────
local function addCornerFills(model, cx, cz)
	local csz = 16
	for _, c in ipairs({
		{cx - HW, cz - HD}, {cx + HW, cz - HD},
		{cx - HW, cz + HD}, {cx + HW, cz + HD},
	}) do
		p(model, Vector3.new(csz, WALL_H + 6, csz),
			CFrame.new(c[1], WALL_CY, c[2]) * CFrame.Angles(0, math.rad(45), 0),
			COL_ROCK, MAT_ROCK).Name = "CornerFill"
		p(model, Vector3.new(csz * 0.65, WALL_H * 0.55, csz * 0.65),
			CFrame.new(c[1] + math.random(-3,3), WALL_CY * 0.5, c[2] + math.random(-3,3)) *
			CFrame.Angles(math.rad(math.random(-8,8)), math.rad(math.random(15,75)), math.rad(math.random(-8,8))),
			COL_ROCK, MAT_ROCK).Name = "CornerFill"
	end
end

-- ── Ceiling: hanging boulder masses + stalactite forest ───────────────
local function addCeiling(model, cx, cz)
	-- Irregular ceiling boulder masses
	for i = 1, 6 do
		local bw = math.random(7, 16)
		local bh = math.random(3, 7)
		p(model, Vector3.new(bw, bh, math.random(6, 14)),
			CFrame.new(cx + math.random(-33,33), Config.CEIL_Y - bh/2, cz + math.random(-33,33)) *
			CFrame.Angles(math.rad(math.random(-10,10)), math.rad(math.random(0,360)), math.rad(math.random(-10,10))),
			COL_ROCK, MAT_ROCK).Name = "CeilingBoulder"
	end
	-- Stalactite forest (tapered)
	for i = 1, 20 do
		makeStalactite(model,
			cx + math.random(-36, 36),
			cz + math.random(-36, 36), true)
	end
end

-- ── Floor: stalagmites + rocks + puddles ─────────────────────────────
local function addFloor(model, cx, cz)
	-- Loose rocks and boulders
	for i = 1, 14 do
		local sz = Vector3.new(math.random(1,5), math.random(1,4), math.random(1,5))
		p(model, sz,
			CFrame.new(cx + math.random(-33,33), FY + sz.Y/2, cz + math.random(-33,33)) *
			CFrame.Angles(math.rad(math.random(-20,20)), math.rad(math.random(0,360)), math.rad(math.random(-20,20))),
			math.random() > 0.5 and COL_ROCK or COL_STONE, MAT_ROCK).Name = "Rock"
	end
	-- Stalagmites rising from floor (tapered)
	for i = 1, 7 do
		makeStalactite(model,
			cx + math.random(-28, 28),
			cz + math.random(-28, 28), false)
	end
	-- Water puddles (glass material, slightly transparent)
	for i = 1, 4 do
		local pw = math.random(4, 11)
		local pd = math.random(3, 9)
		p(model, Vector3.new(pw, 0.18, pd),
			CFrame.new(cx + math.random(-26,26), FY + 0.09, cz + math.random(-26,26)),
			BrickColor.new("Bright blue"), MAT_GLASS, 0.35, false).Name = "Puddle"
	end
end

-- ── Wooden mine support arches ────────────────────────────────────────
local function addMineSupports(model, cx, cz)
	for _, zOff in ipairs({-16, 16}) do
		local bz = cz + zOff
		local pH = 13
		p(model, Vector3.new(1.5, pH, 1.5), CFrame.new(cx-15, FY+pH/2, bz), COL_WOOD, MAT_WOOD).Name = "Support"
		p(model, Vector3.new(1.5, pH, 1.5), CFrame.new(cx+15, FY+pH/2, bz), COL_WOOD, MAT_WOOD).Name = "Support"
		p(model, Vector3.new(32,  1.5, 1.5), CFrame.new(cx, FY+pH+0.75, bz), COL_WOOD, MAT_WOOD).Name = "Support"
		p(model, Vector3.new(1, 6, 1), CFrame.new(cx-11, FY+pH-2.5, bz) * CFrame.Angles(0,0,math.rad(35)),
			BrickColor.new("Brown"), MAT_WOOD).Name = "Support"
		p(model, Vector3.new(1, 6, 1), CFrame.new(cx+11, FY+pH-2.5, bz) * CFrame.Angles(0,0,math.rad(-35)),
			BrickColor.new("Brown"), MAT_WOOD).Name = "Support"
	end
end

-- ── Which sides have tunnel openings ─────────────────────────────────
local function getOpenSides(caveId)
	local data = Config.CAVES[caveId]
	local open = { N=false, S=false, E=false, W=false }
	local cx, cz = data.center.X, data.center.Z
	for _, connId in ipairs(data.connections) do
		local c  = Config.CAVES[connId]
		local dx = c.center.X - cx
		local dz = c.center.Z - cz
		if math.abs(dx) >= math.abs(dz) then
			if dx > 0 then open.E = true else open.W = true end
		else
			if dz > 0 then open.S = true else open.N = true end
		end
	end
	return open
end

-- ── Build wall face with optional tunnel opening ──────────────────────
local function buildWallFace(model, side, cx, cz, open)
	local facePos = {
		N = Vector3.new(cx, WALL_CY, cz-HD),
		S = Vector3.new(cx, WALL_CY, cz+HD),
		E = Vector3.new(cx+HW, WALL_CY, cz),
		W = Vector3.new(cx-HW, WALL_CY, cz),
	}
	local isEW   = (side == "E" or side == "W")
	local fullSz = isEW and Vector3.new(WT, WALL_H, D) or Vector3.new(W, WALL_H, WT)
	if not open[side] then
		p(model, fullSz, CFrame.new(facePos[side]), COL_ROCK, MAT_SLATE).Name = "Wall"
		return
	end
	local halfRoom = isEW and HD or HW
	local halfGap  = TW / 2
	local segLen   = halfRoom - halfGap
	local lintH    = WALL_H - TH
	local fp       = facePos[side]
	if not isEW then
		p(model, Vector3.new(segLen, WALL_H, WT), CFrame.new(cx - halfRoom + segLen/2, WALL_CY, fp.Z), COL_ROCK, MAT_SLATE).Name = "Wall"
		p(model, Vector3.new(segLen, WALL_H, WT), CFrame.new(cx + halfRoom - segLen/2, WALL_CY, fp.Z), COL_ROCK, MAT_SLATE).Name = "Wall"
		p(model, Vector3.new(TW, lintH, WT),      CFrame.new(cx, TH + lintH/2, fp.Z), COL_ROCK, MAT_SLATE).Name = "Lintel"
	else
		p(model, Vector3.new(WT, WALL_H, segLen), CFrame.new(fp.X, WALL_CY, cz - halfRoom + segLen/2), COL_ROCK, MAT_SLATE).Name = "Wall"
		p(model, Vector3.new(WT, WALL_H, segLen), CFrame.new(fp.X, WALL_CY, cz + halfRoom - segLen/2), COL_ROCK, MAT_SLATE).Name = "Wall"
		p(model, Vector3.new(WT, lintH, TW),      CFrame.new(fp.X, TH + lintH/2, cz), COL_ROCK, MAT_SLATE).Name = "Lintel"
	end
end

-- ── Build one cave room ───────────────────────────────────────────────
local function buildCave(id)
	local data = Config.CAVES[id]
	local cx   = data.center.X
	local cz   = data.center.Z

	local model = Instance.new("Model")
	model.Name   = "Cave_" .. id .. (data.isDiamond and "_DIAMOND" or "")
	model.Parent = CaveFolder

	-- Structural surfaces
	p(model, Vector3.new(W, WT, D), CFrame.new(cx, FLOOR_CY, cz), COL_DIRT, MAT_GROUND).Name = "Floor"
	p(model, Vector3.new(W, WT, D), CFrame.new(cx, CEIL_CY,  cz), COL_ROCK, MAT_SLATE).Name  = "Ceiling"

	local open = getOpenSides(id)
	for _, side in ipairs({"N","S","E","W"}) do
		buildWallFace(model, side, cx, cz, open)
	end

	-- Cave location trigger
	local det = p(model, Vector3.new(W-4, 2, D-4), CFrame.new(cx, 2, cz), COL_ROCK, nil, 1, true)
	det.Name = "CaveTrigger"
	local tag = Instance.new("IntValue")
	tag.Name = "CaveId" ; tag.Value = id ; tag.Parent = det

	-- Organic visual layers
	addCornerFills(model, cx, cz)
	addWallRockFace(model, cx, cz)
	addCeiling(model, cx, cz)
	addFloor(model, cx, cz)
	placeTorches(model, cx, cz)
	addMineSupports(model, cx, cz)
	placeOreVeins(model, cx, cz, data.isDiamond)

	-- Diamond pickups
	if data.isDiamond then
		for i = 1, Config.DIAMONDS_IN_CAVE do
			local angle = (i / Config.DIAMONDS_IN_CAVE) * math.pi * 2
			local gem = p(model, Vector3.new(2, 3, 2),
				CFrame.new(cx + math.cos(angle)*10, FY + 2.5, cz + math.sin(angle)*10),
				COL_DIAM, MAT_GLASS)
			gem.Name  = "Diamond"
			gem.Shape = Enum.PartType.Ball
			local pp = Instance.new("ProximityPrompt")
			pp.ActionText = "Take Diamond"
			pp.KeyboardKeyCode = Enum.KeyCode.E
			pp.MaxActivationDistance = 8
			pp.Parent = gem
		end
	end

	-- Cover crates along walls (away from corners which have rock fills)
	local hideouts = {
		Vector3.new(cx - 22, FY + 2, cz - HD + 7),
		Vector3.new(cx + 22, FY + 2, cz + HD - 7),
	}
	for _, hpos in ipairs(hideouts) do
		p(model, Vector3.new(6,4,6), CFrame.new(hpos), BrickColor.new("Brown"), MAT_WOOD).Name = "Hideout"
		p(model, Vector3.new(6,4,6), CFrame.new(hpos + Vector3.new(0,4,0)), BrickColor.new("Reddish brown"), MAT_WOOD).Name = "Hideout"
	end
end

-- ── Build tunnel corridor with nooks ─────────────────────────────────
local builtTunnels = {}
local function buildTunnel(idA, idB)
	local key = math.min(idA,idB) .. "_" .. math.max(idA,idB)
	if builtTunnels[key] then return end
	builtTunnels[key] = true

	local aPos      = Config.CAVES[idA].center
	local bPos      = Config.CAVES[idB].center
	local midX      = (aPos.X + bPos.X) / 2
	local midZ      = (aPos.Z + bPos.Z) / 2
	local tunnelLen = SP - W

	local model = Instance.new("Model")
	model.Name   = ("Tunnel_%d_%d"):format(math.min(idA,idB), math.max(idA,idB))
	model.Parent = CaveFolder

	local NOOK_W = 10
	local NOOK_D = 6
	local PAR_H  = 4
	local halfN  = NOOK_W / 2
	local segLen = (tunnelLen - NOOK_W) / 2
	local nDT    = NOOK_D + WT

	local isEW = math.abs(aPos.X - bPos.X) >= math.abs(aPos.Z - bPos.Z)

	if isEW then
		p(model, Vector3.new(tunnelLen, WT, TW), CFrame.new(midX, FLOOR_CY, midZ), COL_DIRT, MAT_GROUND).Name = "Floor"
		p(model, Vector3.new(tunnelLen, WT, TW), CFrame.new(midX, CEIL_CY,  midZ), COL_ROCK, MAT_SLATE).Name  = "Ceiling"

		local nInZ   = midZ - TW/2
		local nCenZ  = nInZ - WT/2
		local nNookZ = nInZ - nDT/2
		local nBackZ = nInZ - nDT - WT/2

		p(model, Vector3.new(segLen, H, WT), CFrame.new(midX - halfN - segLen/2, H/2+2, nCenZ), COL_ROCK, MAT_SLATE).Name = "Wall"
		p(model, Vector3.new(segLen, H, WT), CFrame.new(midX + halfN + segLen/2, H/2+2, nCenZ), COL_ROCK, MAT_SLATE).Name = "Wall"
		p(model, Vector3.new(WT, H, nDT), CFrame.new(midX - halfN - WT/2, H/2+2, nNookZ), COL_ROCK, MAT_SLATE).Name = "NookSide"
		p(model, Vector3.new(WT, H, nDT), CFrame.new(midX + halfN + WT/2, H/2+2, nNookZ), COL_ROCK, MAT_SLATE).Name = "NookSide"
		p(model, Vector3.new(NOOK_W + WT*2, H, WT), CFrame.new(midX, H/2+2, nBackZ), COL_ROCK, MAT_SLATE).Name = "NookBack"
		p(model, Vector3.new(NOOK_W, WT, nDT), CFrame.new(midX, FLOOR_CY, nNookZ), COL_DIRT, MAT_GROUND).Name = "NookFloor"
		p(model, Vector3.new(NOOK_W, WT, nDT), CFrame.new(midX, CEIL_CY,  nNookZ), COL_ROCK, MAT_SLATE).Name  = "NookCeiling"
		p(model, Vector3.new(NOOK_W, PAR_H, WT), CFrame.new(midX, FY + PAR_H/2, nInZ + WT/2), COL_STONE, MAT_SLATE).Name = "NookParapet"
		makeTorch(model, Vector3.new(midX, FY+5, nInZ - nDT), Vector3.new(0,0,1))

		local sInZ   = midZ + TW/2
		local sCenZ  = sInZ + WT/2
		local sNookZ = sInZ + nDT/2
		local sBackZ = sInZ + nDT + WT/2

		p(model, Vector3.new(segLen, H, WT), CFrame.new(midX - halfN - segLen/2, H/2+2, sCenZ), COL_ROCK, MAT_SLATE).Name = "Wall"
		p(model, Vector3.new(segLen, H, WT), CFrame.new(midX + halfN + segLen/2, H/2+2, sCenZ), COL_ROCK, MAT_SLATE).Name = "Wall"
		p(model, Vector3.new(WT, H, nDT), CFrame.new(midX - halfN - WT/2, H/2+2, sNookZ), COL_ROCK, MAT_SLATE).Name = "NookSide"
		p(model, Vector3.new(WT, H, nDT), CFrame.new(midX + halfN + WT/2, H/2+2, sNookZ), COL_ROCK, MAT_SLATE).Name = "NookSide"
		p(model, Vector3.new(NOOK_W + WT*2, H, WT), CFrame.new(midX, H/2+2, sBackZ), COL_ROCK, MAT_SLATE).Name = "NookBack"
		p(model, Vector3.new(NOOK_W, WT, nDT), CFrame.new(midX, FLOOR_CY, sNookZ), COL_DIRT, MAT_GROUND).Name = "NookFloor"
		p(model, Vector3.new(NOOK_W, WT, nDT), CFrame.new(midX, CEIL_CY,  sNookZ), COL_ROCK, MAT_SLATE).Name  = "NookCeiling"
		p(model, Vector3.new(NOOK_W, PAR_H, WT), CFrame.new(midX, FY + PAR_H/2, sInZ - WT/2), COL_STONE, MAT_SLATE).Name = "NookParapet"
		makeTorch(model, Vector3.new(midX, FY+5, sInZ + nDT), Vector3.new(0,0,-1))

	else
		p(model, Vector3.new(TW, WT, tunnelLen), CFrame.new(midX, FLOOR_CY, midZ), COL_DIRT, MAT_GROUND).Name = "Floor"
		p(model, Vector3.new(TW, WT, tunnelLen), CFrame.new(midX, CEIL_CY,  midZ), COL_ROCK, MAT_SLATE).Name  = "Ceiling"

		local wInX   = midX - TW/2
		local wCenX  = wInX - WT/2
		local wNookX = wInX - nDT/2
		local wBackX = wInX - nDT - WT/2

		p(model, Vector3.new(WT, H, segLen), CFrame.new(wCenX, H/2+2, midZ - halfN - segLen/2), COL_ROCK, MAT_SLATE).Name = "Wall"
		p(model, Vector3.new(WT, H, segLen), CFrame.new(wCenX, H/2+2, midZ + halfN + segLen/2), COL_ROCK, MAT_SLATE).Name = "Wall"
		p(model, Vector3.new(nDT, H, WT), CFrame.new(wNookX, H/2+2, midZ - halfN - WT/2), COL_ROCK, MAT_SLATE).Name = "NookSide"
		p(model, Vector3.new(nDT, H, WT), CFrame.new(wNookX, H/2+2, midZ + halfN + WT/2), COL_ROCK, MAT_SLATE).Name = "NookSide"
		p(model, Vector3.new(WT, H, NOOK_W + WT*2), CFrame.new(wBackX, H/2+2, midZ), COL_ROCK, MAT_SLATE).Name = "NookBack"
		p(model, Vector3.new(nDT, WT, NOOK_W), CFrame.new(wNookX, FLOOR_CY, midZ), COL_DIRT, MAT_GROUND).Name = "NookFloor"
		p(model, Vector3.new(nDT, WT, NOOK_W), CFrame.new(wNookX, CEIL_CY,  midZ), COL_ROCK, MAT_SLATE).Name  = "NookCeiling"
		p(model, Vector3.new(WT, PAR_H, NOOK_W), CFrame.new(wInX + WT/2, FY + PAR_H/2, midZ), COL_STONE, MAT_SLATE).Name = "NookParapet"
		makeTorch(model, Vector3.new(wInX - nDT, FY+5, midZ), Vector3.new(1,0,0))

		local eInX   = midX + TW/2
		local eCenX  = eInX + WT/2
		local eNookX = eInX + nDT/2
		local eBackX = eInX + nDT + WT/2

		p(model, Vector3.new(WT, H, segLen), CFrame.new(eCenX, H/2+2, midZ - halfN - segLen/2), COL_ROCK, MAT_SLATE).Name = "Wall"
		p(model, Vector3.new(WT, H, segLen), CFrame.new(eCenX, H/2+2, midZ + halfN + segLen/2), COL_ROCK, MAT_SLATE).Name = "Wall"
		p(model, Vector3.new(nDT, H, WT), CFrame.new(eNookX, H/2+2, midZ - halfN - WT/2), COL_ROCK, MAT_SLATE).Name = "NookSide"
		p(model, Vector3.new(nDT, H, WT), CFrame.new(eNookX, H/2+2, midZ + halfN + WT/2), COL_ROCK, MAT_SLATE).Name = "NookSide"
		p(model, Vector3.new(WT, H, NOOK_W + WT*2), CFrame.new(eBackX, H/2+2, midZ), COL_ROCK, MAT_SLATE).Name = "NookBack"
		p(model, Vector3.new(nDT, WT, NOOK_W), CFrame.new(eNookX, FLOOR_CY, midZ), COL_DIRT, MAT_GROUND).Name = "NookFloor"
		p(model, Vector3.new(nDT, WT, NOOK_W), CFrame.new(eNookX, CEIL_CY,  midZ), COL_ROCK, MAT_SLATE).Name  = "NookCeiling"
		p(model, Vector3.new(WT, PAR_H, NOOK_W), CFrame.new(eInX - WT/2, FY + PAR_H/2, midZ), COL_STONE, MAT_SLATE).Name = "NookParapet"
		makeTorch(model, Vector3.new(eInX + nDT, FY+5, midZ), Vector3.new(-1,0,0))
	end
end

-- ── Locked exit gate inside cave 1 ───────────────────────────────────
local function buildExitGate()
	local cave1 = Config.CAVES[1]
	local cx    = cave1.center.X
	local cz    = cave1.center.Z
	local gateZ = cz - HD + 15

	local model = Instance.new("Model")
	model.Name   = "ExitGate"
	model.Parent = workspace

	local pillarH = 12
	p(model, Vector3.new(4, pillarH, 4), CFrame.new(cx-11, FY+pillarH/2, gateZ), COL_STONE, MAT_SLATE).Name = "GatePillar"
	p(model, Vector3.new(4, pillarH, 4), CFrame.new(cx+11, FY+pillarH/2, gateZ), COL_STONE, MAT_SLATE).Name = "GatePillar"

	local lintel = p(model, Vector3.new(26, 3, 4), CFrame.new(cx, FY+pillarH+1.5, gateZ), COL_STONE, MAT_SLATE)
	lintel.Name = "GateLintel"

	local barH = pillarH - 1
	for i = -1, 1 do
		local bar = p(model, Vector3.new(2, barH, 2),
			CFrame.new(cx + i*6, FY + barH/2, gateZ),
			BrickColor.new("Bright red"), MAT_SMOOTH)
		bar.Name = "GateBar"
	end

	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(0,260,0,80) ; bg.StudsOffset = Vector3.new(0,4,0) ; bg.Parent = lintel
	local sl = Instance.new("TextLabel")
	sl.Name = "SignText" ; sl.Size = UDim2.new(1,0,1,0)
	sl.BackgroundColor3 = Color3.fromRGB(20,0,0) ; sl.BackgroundTransparency = 0.3
	sl.Text = "EXIT LOCKED\nCollect 3 diamonds first!"
	sl.TextColor3 = Color3.fromRGB(255,60,60) ; sl.Font = Enum.Font.GothamBold
	sl.TextScaled = true ; sl.Parent = bg

	makeTorch(model, Vector3.new(cx-14, FY+5, gateZ), Vector3.new(1,0,0))
	makeTorch(model, Vector3.new(cx+14, FY+5, gateZ), Vector3.new(-1,0,0))

	local exitZone = p(model, Vector3.new(20,10,10), CFrame.new(cx, FY+5, gateZ-6), COL_ROCK, nil, 1, true)
	exitZone.Name = "ExitZone"
end

-- ── Run ───────────────────────────────────────────────────────────────
for id in pairs(Config.CAVES) do buildCave(id) end
for idA, data in pairs(Config.CAVES) do
	for _, idB in ipairs(data.connections) do buildTunnel(idA, idB) end
end
buildExitGate()

print("[CaveBuilder] Done — organic diamond mine built")
