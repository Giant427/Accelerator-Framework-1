repeat
	wait()
until game:IsLoaded()

local localPlayer = game.Players.LocalPlayer
local mouse = localPlayer:GetMouse()

--[[
	----------------------------------------------------------------
		IMPORTANT	IMPORTANT	IMPORTANT	IMPORTANT	IMPORTANT
	----------------------------------------------------------------
	]]--
	local weaponName = "AWP"
    local weaponType = "Sniper" -- ("Burst","Sniper","SemiAuto","FullAuto") --
	--[[
	----------------------------------------------------------------
		IMPORTANT	IMPORTANT	IMPORTANT	IMPORTANT	IMPORTANT
	----------------------------------------------------------------
]]--

local weaponVars = localPlayer:WaitForChild("PlayerVars"):WaitForChild(weaponName)
local equipped = weaponVars.Equipped
local reloading = weaponVars.Reloading
local ammo = weaponVars.Ammo
local magAmmo = weaponVars.MagAmmo

local clientModule = require(game:GetService("ReplicatedStorage"):WaitForChild("MainModuleClient"))
local weaponData = game:GetService("ReplicatedStorage"):WaitForChild("WeaponData"):WaitForChild(weaponName)

local holdAnimation = game:GetService("ReplicatedStorage"):WaitForChild(weaponName.."_Animations"):WaitForChild("Viewmodel_Hold")
local reloadAnimation = game:GetService("ReplicatedStorage"):WaitForChild(weaponName.."_Animations"):WaitForChild("Viewmodel_Reload")
local aimAnimation = game:GetService("ReplicatedStorage"):WaitForChild(weaponName.."_Animations"):WaitForChild("Viewmodel_Aim")

local remote = game:GetService("ReplicatedStorage"):WaitForChild(weaponName.."_Comms")

local gun = clientModule.gun:New({
    player = localPlayer;
    mouse = mouse;
    viewmodel = game.Workspace.CurrentCamera:WaitForChild("Viewmodel");

    weaponName = weaponName;
    weaponType = weaponType;

    delay = weaponData.Delay.Value;
    headshotDamage = weaponData.HeadshotDamage.Value;
    bodyshotDamage = weaponData.BodyshotDamage.Value;
    recoil = weaponData.Recoil.Value / 100;

    holdAnim = game.Workspace.CurrentCamera:WaitForChild("Viewmodel").AnimationController:LoadAnimation(holdAnimation);
    aimAnim = game.Workspace.CurrentCamera:WaitForChild("Viewmodel").AnimationController:LoadAnimation(aimAnimation);
    reloadAnim = game.Workspace.CurrentCamera:WaitForChild("Viewmodel").AnimationController:LoadAnimation(reloadAnimation);
    shootAnim = nil;

	equipped = equipped;
	reloading = reloading;
    ammo = ammo;
    magAmmo = magAmmo;

    remote = remote;
})

remote.OnClientEvent:Connect(function(task)
    if task == "Equip" then
        gun:Equip()
    end
    if task == "Unequip" then
        gun:Unequip()
    end
end)