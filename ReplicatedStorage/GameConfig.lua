-- GameConfig.lua
-- ModuleScript → ReplicatedStorage

local Config = {}

-- ── Cave geometry ──────────────────────────────────────────────────────
Config.CAVE_W       = 80
Config.CAVE_D       = 80
Config.CAVE_H       = 22
Config.WALL_T       = 4
Config.TUNNEL_W     = 20
Config.TUNNEL_H     = 14
Config.SPACING      = 150
Config.FLOOR_Y      = 2
Config.CEIL_Y       = 22

-- ── Cave layout: 3×3 grid ──────────────────────────────────────────────
local S = Config.SPACING
Config.CAVES = {
    [1] = { center=Vector3.new(-S,0,-S), guarded=false, connections={2,4},     copCount=0, weaponTier=1 },
    [2] = { center=Vector3.new( 0,0,-S), guarded=true,  connections={1,3,5},   copCount=2, weaponTier=2 },
    [3] = { center=Vector3.new( S,0,-S), guarded=false, connections={2,6},     copCount=0, weaponTier=1 },
    [4] = { center=Vector3.new(-S,0, 0), guarded=true,  connections={1,5,7},   copCount=2, weaponTier=2 },
    [5] = { center=Vector3.new( 0,0, 0), guarded=false, connections={2,4,6,8}, copCount=0, weaponTier=1 },
    [6] = { center=Vector3.new( S,0, 0), guarded=true,  connections={3,5,9},   copCount=3, weaponTier=3 },
    [7] = { center=Vector3.new(-S,0, S), guarded=false, connections={4,8},     copCount=0, weaponTier=1 },
    [8] = { center=Vector3.new( 0,0, S), guarded=true,  connections={5,7,9},   copCount=3, weaponTier=3 },
    [9] = { center=Vector3.new( S,0, S), guarded=true,  connections={6,8},     copCount=5, weaponTier=3, isDiamond=true },
}

-- ── Cop settings ───────────────────────────────────────────────────────
Config.COP_SPEED         = 10   -- patrol walk speed (studs/sec)
Config.COP_CHASE_SPEED   = 22   -- chase speed (studs/sec)
Config.COP_PATROL_RANGE  = 28
Config.COP_DETECT_RANGE  = 60
Config.COP_SHOOT_RANGE   = 55
Config.COP_BASE_DAMAGE   = 35
Config.COP_FIRE_RATE     = 2.0
Config.COP_ROTATE_MIN    = 25
Config.COP_ROTATE_MAX    = 55
Config.COP_REGEN_TIME    = 30   -- seconds before a killed cop respawns

-- ── Weapon tiers ───────────────────────────────────────────────────────
Config.WEAPONS = {
    [1] = { name="Pistol",  damage=20, range=70,  fireRate=1.1 },
    [2] = { name="Shotgun", damage=50, range=55,  fireRate=0.7 },
    [3] = { name="Rifle",   damage=75, range=120, fireRate=0.35 },
}

-- ── Chest / item settings ──────────────────────────────────────────────
Config.CHESTS_PER_CAVE   = 2

-- ── Player settings ────────────────────────────────────────────────────
Config.MAX_HEALTH        = 100
Config.SPAWN_CAVES       = {1, 3, 7}

-- ── Diamond / win ──────────────────────────────────────────────────────
Config.DIAMONDS_IN_CAVE  = 5
Config.DIAMONDS_TO_WIN   = 3

-- Exit zone north of cave 1
Config.EXIT_POS = Vector3.new(-S, Config.FLOOR_Y, -S - 130)

return Config
