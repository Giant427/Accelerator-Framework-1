local tool = script.Parent
local localPlayer = tool.Parent.Parent

--[[
	----------------------------------------------------------------
		IMPORTANT	IMPORTANT	IMPORTANT	IMPORTANT	IMPORTANT
	----------------------------------------------------------------
	]]--
	local weaponName = "M4A4"
    local weaponType = "FullAuto" -- ("Burst","Sniper","SemiAuto","FullAuto") --
	--[[
	----------------------------------------------------------------
		IMPORTANT	IMPORTANT	IMPORTANT	IMPORTANT	IMPORTANT
	----------------------------------------------------------------
]]--

local gunsFolder = game:GetService("ReplicatedStorage"):WaitForChild("Guns")
local animations = gunsFolder:WaitForChild("Animations"):WaitForChild(weaponName.."_Animations")
local holdAnimation = animations:WaitForChild("Hold_Char")
local aimAnimation = animations:WaitForChild("Aim_Char")
local reloadAnimation = animations:WaitForChild("Reload_Char")
local shootAnimation = nil

repeat
	wait()
until localPlayer.Character.Parent == game.Workspace

local holdAnim = localPlayer.Character.Humanoid:LoadAnimation(holdAnimation)
local aimAnim = localPlayer.Character.Humanoid:LoadAnimation(aimAnimation)
local reloadAnim = localPlayer.Character.Humanoid:LoadAnimation(reloadAnimation)
local shootAnim = nil

if weaponType == "Sniper" then
	shootAnimation = animations:WaitForChild("Shoot_Char")
	shootAnim = localPlayer.Character.Humanoid:LoadAnimation(shootAnimation)
end

local remote = gunsFolder:WaitForChild("Remotes"):WaitForChild(weaponName.."_Comms")
local weaponData = game:GetService("ReplicatedStorage"):WaitForChild("WeaponData"):WaitForChild(weaponName)

local weaponVars = localPlayer:WaitForChild("PlayerVars"):WaitForChild(weaponName)

local reloading = weaponVars.Reloading
local ammo = weaponVars.Ammo
local magAmmo = weaponVars.MagAmmo
local equipped = weaponVars.Equipped

local aimVars = localPlayer:WaitForChild("PlayerVars"):WaitForChild("Aim")
local aimDirection = aimVars:WaitForChild("AimDirection")
local aimOrigin = aimVars:WaitForChild("AimOrigin")

local serverModule = require(game.ServerScriptService:WaitForChild("MainModuleServer"))

local gun = serverModule.gun:New({
	player = localPlayer,

	weaponName = weaponName,
	weaponType = weaponType,

	headshotDamage = weaponData.HeadshotDamage.Value,
	bodyshotDamage = weaponData.BodyshotDamage.Value,

	aimDirection = aimDirection,
	aimOrigin = aimOrigin,

	holdAnim = holdAnim,
	aimAnim = aimAnim,
	reloadAnim = reloadAnim,
	shootAnim = shootAnim,

	equipped = equipped,
	reloading = reloading,
    ammo = ammo,
    magAmmo = magAmmo,

	remote = remote,
})

local function equip()
	gun:Equip()
end

local function unequip()
	gun:Unequip()
end

remote.OnServerEvent:Connect(function(player,task,endposition,cCframe)
	if player == localPlayer then
		if task == "Shoot" then
			gun:Shoot()
		end
		if task == "Reload" then
			gun:Reload()
		end
		if task == "AimSight" then
			gun:AimSight()
		end
		if task == "AimHand" then
			gun:AimHand()
		end
	end
end)

tool.Equipped:Connect(equip)
tool.Unequipped:Connect(unequip)
localPlayer.Character.Humanoid.Died:Connect(unequip)