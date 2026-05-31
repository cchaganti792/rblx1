-- LightingSetup.lua
-- Script → ServerScriptService
-- Removes all ambient light so caves are pitch dark

local Lighting = game:GetService("Lighting")

Lighting.Ambient        = Color3.fromRGB(0, 0, 0)
Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
Lighting.Brightness     = 0
Lighting.GlobalShadows  = true
Lighting.FogColor       = Color3.fromRGB(0, 0, 0)
Lighting.FogStart       = 15
Lighting.FogEnd         = 100

-- Remove sky box so there is no sky ambient contribution
local sky = Lighting:FindFirstChildOfClass("Sky")
if sky then sky:Destroy() end

print("[LightingSetup] Darkness applied")
