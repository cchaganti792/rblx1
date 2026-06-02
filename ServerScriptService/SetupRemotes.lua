-- SetupRemotes.lua
-- Script → ServerScriptService  (runs first, creates all RemoteEvents)

local RS = game:GetService("ReplicatedStorage")

local names = {
    "RE_TakeDamage",     -- Server → Client  : number damage, number newHealth
    "RE_PickupWeapon",   -- Server → Client  : number tier, string name
    "RE_PickupDiamond",  -- Server → Client  : number totalHeld
    "RE_GameWon",        -- Server → Client  : (no args)
    "RE_GameLost",       -- Server → Client  : (no args)
    "RE_UpdateHUD",      -- Server → Client  : number health, number diamonds, number caveId
    "RE_ShootWeapon",    -- Client → Server  : Vector3 origin, Vector3 direction, number tier
    "RE_CopFlash",       -- Server → Client  : Vector3 copPos (muzzle flash effect)
    "RE_TorchState",     -- Client → Server  : bool torchOn
}

for _, name in ipairs(names) do
    if not RS:FindFirstChild(name) then
        local re = Instance.new("RemoteEvent")
        re.Name = name
        re.Parent = RS
    end
end

print("[SetupRemotes] All RemoteEvents ready")
