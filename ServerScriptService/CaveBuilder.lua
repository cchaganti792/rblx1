-- CaveBuilder.lua
-- Script → ServerScriptService
-- Builds realistic diamond mine caves: rock walls, dirt floors, torches, plants, stalactites.

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

-- Y layout: floor Part center=0, top=2; wall center=12, height=24; ceiling center=24
local FLOOR_CY = 0
local CEIL_CY  = 24
local WALL_CY  = 12
local WALL_H   = 24

-- Materials & colors
local MAT_ROCK   = Enum.Material.Rock
local MAT_GROUND = Enum.Material.Ground
local MAT_WOOD   = Enum.Material.Wood
local MAT_NEON   = Enum.Material.Neon
local MAT_SLATE  = Enum.Material.Slate
local MAT_GRASS  = Enum.Material.Grass

local COL_ROCK   = BrickColor.new("Dark stone grey")
local COL_DIRT   = BrickColor.new("Reddish brown")
local COL_WOOD   = BrickColor.new("Reddish brown")
local COL_FLAME  = BrickColor.new("Bright orange")
local COL_PLANT  = BrickColor.new("Bright green")
local COL_STONE  = BrickColor.new("Medium stone grey")
local COL_DIAM   = BrickColor.new("Cyan")

local CaveFolder = Instance.new("Folder")
CaveFolder.Name  = "Caves"
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
    part.Parent       = parent
    return part
end

-- ── Torch model ───────────────────────────────────────────────────────
local function makeTorch(parent, position, facingDir)
    -- Wall bracket
    local bracket = p(parent, Vector3.new(0.5,0.5,0.5),
        CFrame.new(position), COL_STONE, MAT_SLATE)
    bracket.Name = "TorchBracket"

    -- Wooden stick (angled slightly outward)
    local stickPos = position + Vector3.new(0, 0.8, 0) + facingDir * 0.3
    local stick = p(parent, Vector3.new(0.3, 1.4, 0.3),
        CFrame.new(stickPos) * CFrame.Angles(0, 0, math.rad(15) * (facingDir.X ~= 0 and facingDir.X or facingDir.Z)),
        COL_WOOD, MAT_WOOD)
    stick.Name = "TorchStick"

    -- Flame (neon orange sphere)
    local flamePos = stickPos + Vector3.new(0, 1, 0)
    local flame = p(parent, Vector3.new(0.6, 0.8, 0.6),
        CFrame.new(flamePos), COL_FLAME, MAT_NEON)
    flame.Name  = "TorchFlame"
    flame.Shape = Enum.PartType.Ball

    -- Point light on flame
    local light = Instance.new("PointLight")
    light.Brightness = 3
    light.Range      = 24
    light.Color      = Color3.fromRGB(255, 140, 40)
    light.Parent     = flame
end

-- ── Place torches on cave walls ────────────────────────────────────────
local function placeTorches(model, cx, cz)
    local y = FY + 5
    -- North wall, left and right of center
    makeTorch(model, Vector3.new(cx - 22, y, cz - HW + 1), Vector3.new(0,0,1))
    makeTorch(model, Vector3.new(cx + 22, y, cz - HW + 1), Vector3.new(0,0,1))
    -- South wall
    makeTorch(model, Vector3.new(cx - 22, y, cz + HW - 1), Vector3.new(0,0,-1))
    makeTorch(model, Vector3.new(cx + 22, y, cz + HW - 1), Vector3.new(0,0,-1))
    -- West wall
    makeTorch(model, Vector3.new(cx - HD + 1, y, cz - 22), Vector3.new(1,0,0))
    makeTorch(model, Vector3.new(cx - HD + 1, y, cz + 22), Vector3.new(1,0,0))
    -- East wall
    makeTorch(model, Vector3.new(cx + HD - 1, y, cz - 22), Vector3.new(-1,0,0))
    makeTorch(model, Vector3.new(cx + HD - 1, y, cz + 22), Vector3.new(-1,0,0))
end

-- ── Rock formations (jagged rocks sticking out of walls/floor) ────────
local function placeRocks(model, cx, cz)
    local rockPositions = {
        Vector3.new(cx - 30, FY + 1, cz - 30),
        Vector3.new(cx + 28, FY + 1, cz - 25),
        Vector3.new(cx - 26, FY + 1, cz + 32),
        Vector3.new(cx + 32, FY + 2, cz + 28),
        Vector3.new(cx - 10, FY + 1, cz - 35),
    }
    for _, pos in ipairs(rockPositions) do
        local sz = Vector3.new(
            math.random(2, 5), math.random(2, 6), math.random(2, 5))
        local rock = p(model, sz, CFrame.new(pos) * CFrame.Angles(
            math.rad(math.random(-15,15)),
            math.rad(math.random(0,360)),
            math.rad(math.random(-15,15))
        ), COL_ROCK, MAT_ROCK)
        rock.Name = "Rock"
    end
end

-- ── Stalactites (hanging from ceiling) ────────────────────────────────
local function placeStalactites(model, cx, cz)
    for i = 1, 6 do
        local sx = cx + math.random(-35, 35)
        local sz = cz + math.random(-35, 35)
        local sh = math.random(2, 6)
        local stalactite = p(model,
            Vector3.new(math.random(1,2), sh, math.random(1,2)),
            CFrame.new(sx, Config.CEIL_Y - sh/2, sz),
            COL_STONE, MAT_SLATE)
        stalactite.Name = "Stalactite"
    end
end

-- ── Cave plants (ferns/moss near floor) ───────────────────────────────
local function placePlants(model, cx, cz)
    local plantSpots = {
        Vector3.new(cx - 28, FY, cz - 28),
        Vector3.new(cx + 24, FY, cz + 30),
        Vector3.new(cx - 15, FY, cz + 22),
    }
    for _, pos in ipairs(plantSpots) do
        -- Stem
        p(model, Vector3.new(0.3, 2, 0.3),
            CFrame.new(pos + Vector3.new(0,1,0)), COL_PLANT, MAT_GRASS)
        -- Leaf blobs
        for j = 1, 3 do
            local angle = (j/3) * math.pi * 2
            local lx = pos.X + math.cos(angle) * 1.2
            local lz = pos.Z + math.sin(angle) * 1.2
            local leaf = p(model, Vector3.new(1.5, 1, 1.5),
                CFrame.new(lx, FY + 1.8, lz), COL_PLANT, MAT_GRASS)
            leaf.Shape = Enum.PartType.Ball
        end
    end
end

-- ── Ore veins on walls (diamond/coal streaks) ─────────────────────────
local function placeOreVeins(model, cx, cz, isDiamond)
    local oreCol = isDiamond and COL_DIAM or BrickColor.new("Really black")
    local oreMat = isDiamond and MAT_NEON  or Enum.Material.SmoothPlastic
    for i = 1, (isDiamond and 8 or 3) do
        local face = math.random(1,4)
        local veinPos
        if face == 1 then veinPos = Vector3.new(cx + math.random(-30,30), FY + math.random(2,8), cz - HW + 1)
        elseif face == 2 then veinPos = Vector3.new(cx + math.random(-30,30), FY + math.random(2,8), cz + HW - 1)
        elseif face == 3 then veinPos = Vector3.new(cx - HW + 1, FY + math.random(2,8), cz + math.random(-30,30))
        else veinPos = Vector3.new(cx + HW - 1, FY + math.random(2,8), cz + math.random(-30,30)) end

        p(model, Vector3.new(math.random(1,3), math.random(1,3), 0.3),
            CFrame.new(veinPos), oreCol, oreMat, isDiamond and 0 or 0.1)
    end
end

-- ── Get which sides have tunnel openings ─────────────────────────────
local function getOpenSides(caveId)
    local data = Config.CAVES[caveId]
    local open = { N=false, S=false, E=false, W=false }
    local cx, cz = data.center.X, data.center.Z
    for _, connId in ipairs(data.connections) do
        local c = Config.CAVES[connId]
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

-- ── Build wall face with optional tunnel opening ───────────────────────
local function buildWallFace(model, side, cx, cz, open)
    local facePos = {
        N = Vector3.new(cx, WALL_CY, cz-HD),
        S = Vector3.new(cx, WALL_CY, cz+HD),
        E = Vector3.new(cx+HW, WALL_CY, cz),
        W = Vector3.new(cx-HW, WALL_CY, cz),
    }
    local isEW = (side == "E" or side == "W")
    local fullSz = isEW and Vector3.new(WT, WALL_H, D) or Vector3.new(W, WALL_H, WT)

    if not open[side] then
        local wall = p(model, fullSz, CFrame.new(facePos[side]), COL_ROCK, MAT_SLATE)
        wall.Name = "Wall"
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
    model.Name  = "Cave_" .. id .. (data.isDiamond and "_DIAMOND" or "")
    model.Parent = CaveFolder

    -- Dirt floor
    p(model, Vector3.new(W, WT, D), CFrame.new(cx, FLOOR_CY, cz), COL_DIRT, MAT_GROUND).Name = "Floor"

    -- Rock ceiling
    p(model, Vector3.new(W, WT, D), CFrame.new(cx, CEIL_CY, cz), COL_ROCK, MAT_SLATE).Name = "Ceiling"

    -- Walls
    local open = getOpenSides(id)
    for _, side in ipairs({"N","S","E","W"}) do
        buildWallFace(model, side, cx, cz, open)
    end

    -- Invisible cave trigger for tracking player location
    local det = p(model, Vector3.new(W-4, 2, D-4), CFrame.new(cx, 2, cz), COL_ROCK, nil, 1, true)
    det.Name = "CaveTrigger"
    local tag = Instance.new("IntValue")
    tag.Name = "CaveId" ; tag.Value = id ; tag.Parent = det

    -- Torches instead of lights
    placeTorches(model, cx, cz)

    -- Rock formations, stalactites, plants
    placeRocks(model, cx, cz)
    placeStalactites(model, cx, cz)
    placePlants(model, cx, cz)

    -- Ore veins
    placeOreVeins(model, cx, cz, data.isDiamond)

    -- Diamond pickups
    if data.isDiamond then
        for i = 1, Config.DIAMONDS_IN_CAVE do
            local angle = (i / Config.DIAMONDS_IN_CAVE) * math.pi * 2
            local gem = p(model,
                Vector3.new(2, 3, 2),
                CFrame.new(cx + math.cos(angle)*10, FY + 2.5, cz + math.sin(angle)*10),
                COL_DIAM, MAT_NEON)
            gem.Name  = "Diamond"
            gem.Shape = Enum.PartType.Ball
            local glow = Instance.new("PointLight")
            glow.Brightness = 2 ; glow.Range = 12 ; glow.Color = Color3.fromRGB(0,200,255)
            glow.Parent = gem
            local pp = Instance.new("ProximityPrompt")
            pp.ActionText = "Take Diamond"
            pp.KeyboardKeyCode = Enum.KeyCode.E
            pp.MaxActivationDistance = 8
            pp.Parent = gem
        end
    end

    -- Hideout crates (two corners)
    local hideouts = {
        Vector3.new(cx - HW + 8, FY + 2, cz - HD + 8),
        Vector3.new(cx + HW - 8, FY + 2, cz + HD - 8),
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

    local aPos = Config.CAVES[idA].center
    local bPos = Config.CAVES[idB].center
    local midX = (aPos.X + bPos.X) / 2
    local midZ = (aPos.Z + bPos.Z) / 2
    local tunnelLen = SP - W  -- 70 studs

    local model = Instance.new("Model")
    model.Name = ("Tunnel_%d_%d"):format(math.min(idA,idB), math.max(idA,idB))
    model.Parent = CaveFolder

    -- Nook dimensions
    local NOOK_W = 10                    -- opening width (studs)
    local NOOK_D = 6                     -- depth beyond outer wall face
    local PAR_H  = 4                     -- parapet height (cover barrier)
    local halfN  = NOOK_W / 2            -- = 5
    local segLen = (tunnelLen - NOOK_W) / 2  -- each wall segment beside nook = 30
    local nDT    = NOOK_D + WT           -- total nook depth coverage = 10

    local isEW = math.abs(aPos.X - bPos.X) >= math.abs(aPos.Z - bPos.Z)

    if isEW then
        -- Shared floor + ceiling
        p(model, Vector3.new(tunnelLen, WT, TW), CFrame.new(midX, FLOOR_CY, midZ), COL_DIRT, MAT_GROUND).Name = "Floor"
        p(model, Vector3.new(tunnelLen, WT, TW), CFrame.new(midX, CEIL_CY,  midZ), COL_ROCK, MAT_SLATE).Name  = "Ceiling"

        -- ── North wall + nook ─────────────────────────────────────────
        local nInZ   = midZ - TW/2                 -- inner face = midZ-10
        local nCenZ  = nInZ - WT/2                 -- wall center = midZ-12
        local nNookZ = nInZ - nDT/2                -- nook cover center = midZ-15
        local nBackZ = nInZ - nDT - WT/2           -- back wall center = midZ-22

        -- Wall segments either side of nook gap
        p(model, Vector3.new(segLen, H, WT), CFrame.new(midX - halfN - segLen/2, H/2+2, nCenZ), COL_ROCK, MAT_SLATE).Name = "Wall"
        p(model, Vector3.new(segLen, H, WT), CFrame.new(midX + halfN + segLen/2, H/2+2, nCenZ), COL_ROCK, MAT_SLATE).Name = "Wall"
        -- Nook side walls
        p(model, Vector3.new(WT, H, nDT), CFrame.new(midX - halfN - WT/2, H/2+2, nNookZ), COL_ROCK, MAT_SLATE).Name = "NookSide"
        p(model, Vector3.new(WT, H, nDT), CFrame.new(midX + halfN + WT/2, H/2+2, nNookZ), COL_ROCK, MAT_SLATE).Name = "NookSide"
        -- Nook back wall
        p(model, Vector3.new(NOOK_W + WT*2, H, WT), CFrame.new(midX, H/2+2, nBackZ), COL_ROCK, MAT_SLATE).Name = "NookBack"
        -- Nook floor + ceiling
        p(model, Vector3.new(NOOK_W, WT, nDT), CFrame.new(midX, FLOOR_CY, nNookZ), COL_DIRT, MAT_GROUND).Name = "NookFloor"
        p(model, Vector3.new(NOOK_W, WT, nDT), CFrame.new(midX, CEIL_CY,  nNookZ), COL_ROCK, MAT_SLATE).Name  = "NookCeiling"
        -- Parapet: low stone barrier inside tunnel at nook entrance
        p(model, Vector3.new(NOOK_W, PAR_H, WT), CFrame.new(midX, FY + PAR_H/2, nInZ + WT/2), COL_STONE, MAT_SLATE).Name = "NookParapet"
        makeTorch(model, Vector3.new(midX, FY+5, nInZ - nDT), Vector3.new(0,0,1))

        -- ── South wall + nook ─────────────────────────────────────────
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
        -- Shared floor + ceiling
        p(model, Vector3.new(TW, WT, tunnelLen), CFrame.new(midX, FLOOR_CY, midZ), COL_DIRT, MAT_GROUND).Name = "Floor"
        p(model, Vector3.new(TW, WT, tunnelLen), CFrame.new(midX, CEIL_CY,  midZ), COL_ROCK, MAT_SLATE).Name  = "Ceiling"

        -- ── West wall + nook ──────────────────────────────────────────
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

        -- ── East wall + nook ──────────────────────────────────────────
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

-- ── Exit zone with stone archway ──────────────────────────────────────
local function buildExit()
    local ep = Config.EXIT_POS

    -- Glowing floor tile
    local tile = p(workspace, Vector3.new(40, 1, 40),
        CFrame.new(ep.X, ep.Y - 0.5, ep.Z),
        BrickColor.new("Bright yellow"), MAT_NEON, 0.5, true)
    tile.Name = "ExitZone"

    -- Stone archway pillars
    p(workspace, Vector3.new(4, 14, 4), CFrame.new(ep.X - 12, ep.Y + 7, ep.Z), COL_STONE, MAT_SLATE).Name = "ArchPillar"
    p(workspace, Vector3.new(4, 14, 4), CFrame.new(ep.X + 12, ep.Y + 7, ep.Z), COL_STONE, MAT_SLATE).Name = "ArchPillar"
    p(workspace, Vector3.new(28, 4, 4), CFrame.new(ep.X, ep.Y + 14, ep.Z), COL_STONE, MAT_SLATE).Name = "ArchTop"

    -- Exit sign
    local bg = Instance.new("BillboardGui")
    bg.Size = UDim2.new(0, 200, 0, 60)
    bg.StudsOffset = Vector3.new(0, 10, 0)
    bg.Parent = tile
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1,0,1,0)
    tl.BackgroundTransparency = 1
    tl.Text = "★ EXIT ★\nCarry 3 diamonds here to win!"
    tl.TextColor3 = Color3.new(1,1,0)
    tl.Font = Enum.Font.GothamBold
    tl.TextScaled = true
    tl.Parent = bg

    -- Torches on archway pillars
    local tl2 = Instance.new("PointLight")
    tl2.Brightness = 4 ; tl2.Range = 30 ; tl2.Color = Color3.fromRGB(255,200,80)
    tl2.Parent = tile
end

-- ── Run ───────────────────────────────────────────────────────────────
for id in pairs(Config.CAVES) do buildCave(id) end
for idA, data in pairs(Config.CAVES) do
    for _, idB in ipairs(data.connections) do buildTunnel(idA, idB) end
end
buildExit()

print("[CaveBuilder] Done — realistic diamond mine built")
