local RepStorage = game:GetService("ReplicatedStorage")
local bulletsFolder = game.Workspace:WaitForChild("BulletsFolder")
local availableBullets = bulletsFolder:WaitForChild("AvailableBullets")
local busyBullets = bulletsFolder:WaitForChild("BusyBullets")
local bulletHolesFolder = game.Workspace:WaitForChild("BulletHolesFolder")
local availableBulletHoles = bulletHolesFolder:WaitForChild("AvailableBulletHoles")
local busyBulletHoles = bulletHolesFolder:WaitForChild("BusyBulletHoles")
local gunModelsFolder = game:GetService("ReplicatedStorage"):WaitForChild("Guns"):WaitForChild("Models")

local module = {}

module.gun = {
	player = nil;

	weaponName = "";
	weaponType = "";

	headshotDamage = 0;
	bodyshotDamage = 0;

	aimDirection = nil;
	aimOrigin = nil;

	holdAnim = nil;
	aimAnim = nil;
	reloadAnim = nil;
	shootAnim = nil;

	equipped = nil;
	reloading = nil;
    ammo = nil;
    magAmmo = nil;

	remote = nil;
}

function module.gun:Equip()
	local gun = gunModelsFolder:WaitForChild(self.weaponName):Clone()
	local handle = gun.GunComponents.Handle
	local aim = gun.GunComponents.Aim
	local handle6D = Instance.new("Motor6D",self.player.Character.RightLowerArm)

	for i,v in pairs(gun:GetDescendants()) do
		if v:IsA("BasePart") and v ~= handle and v ~= aim then
			local motor = Instance.new("Motor6D")
			motor.Name = v.Name
			motor.Part0 = handle
			motor.Part1 = v
			motor.C0 = motor.Part0.CFrame:inverse() * motor.Part1.CFrame
			motor.Parent = handle
		end
	end

	handle6D.Name = "Handle6D"
	gun.Parent = self.player.Character
	handle6D.Part0 = self.player.Character.RightLowerArm
	handle6D.Part1 = aim

	self.holdAnim:Play()

	self.equipped.Value = true
	self.remote:FireClient(self.player,"Equip")

	if self.weaponType == "Sniper" then
		local shootAnimation = game:GetService("ReplicatedStorage"):WaitForChild("Guns"):WaitForChild("Animations"):WaitForChild(self.weaponName.."_Animations"):WaitForChild("Shoot_Char")
		self.shootAnim = self.player.Character.Humanoid:LoadAnimation(shootAnimation)
	end
end

function module.gun:Unequip()
	self:AimHand()
	self.holdAnim:Stop()
	self.reloadAnim:Stop()
	self.aimAnim:Stop()

	if self.shootAnim then
		self.shootAnim:Stop()
	end

	self.player.Character:FindFirstChild(self.weaponName):Destroy()
	self.equipped.Value = false
	self.remote:FireClient(self.player,"Unequip")
end

function module.gun:Reload()
	if self.ammo.Value < self.magAmmo.Value and self.reloading.Value == false then
		self.reloading.Value = true
		local character = self.player.Character
		local reloadSound = character:FindFirstChild(self.weaponName).GunComponents.Handle.ReloadSound

		self:AimHand()
		self.reloadAnim:Play()
		reloadSound:Play()

		wait(self.reloadAnim.Length)

		self.ammo.Value = self.magAmmo.Value
		self.reloading.Value = false
	end
end

function module.gun:Shoot()
	if self.ammo.Value > 0 and self.reloading.Value == false then
		local character = self.player.Character
		local barrel = character:FindFirstChild(self.weaponName).GunComponents.Barrel
		local shootSound = barrel.ShootSound

		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		raycastParams.FilterDescendantsInstances = {character,busyBulletHoles:GetDescendants()}
		raycastParams.IgnoreWater = true

		local raycastResult = game.Workspace:Raycast(self.aimOrigin.Value,self.aimDirection.Value * 1000,raycastParams)

		self.ammo.Value -= 1
		if self.weaponType == "Sniper" then
			self:AimHand()
			self.shootAnim:Play()
			shootSound:Play()
		else
			shootSound:Play()
		end
		self:ShootBullet()
		if raycastResult then
			self:Hit(raycastResult.Instance,raycastResult.Position,raycastResult.Normal,{character})		
		else
			raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
			raycastParams.FilterDescendantsInstances = {self.player.Character}
			raycastParams.IgnoreWater = false

			raycastResult = game.Workspace:Raycast(self.aimOrigin.Value,self.aimDirection.Value * 1000,raycastParams)
		end
	else
		if self.ammo.Value == 0 and self.reloading.Value == false then
			self:Reload()
		end
	end
end

function module.gun:MakeBulletHole(Task,hitPosition,hitPart,normal)
	local bulletHole = availableBulletHoles:FindFirstChild("BulletHole")
	bulletHole.Parent = busyBulletHoles
	bulletHole.CFrame = CFrame.new(hitPosition, hitPosition + normal)

	if Task == "Hurt" then
		local waitTime = 0
		if hitPart.Name == "Head" then
			bulletHole.HitHeadshotSound:Play()
			waitTime = bulletHole.HitHeadshotSound.TimeLength
		else
			bulletHole.HitBodyshotSound:Play()
			waitTime = bulletHole.HitHeadshotSound.TimeLength
		end

		task.wait(waitTime)
		bulletHole.CFrame = CFrame.new(Vector3.new(0,-100,0), Vector3.new(0,0,0))
		bulletHole.Parent = availableBulletHoles
	end
	if Task == "Hit" then
		bulletHole.Image.Transparency = 0
		bulletHole.Smoke:Emit()
		if hitPart.Material == Enum.Material.CorrodedMetal or hitPart.Material == Enum.Material.Metal then
			bulletHole.HitMetalSound:Play()
		else
			bulletHole.HitMaterialSound:Play()
		end
		task.wait(10)
		bulletHole.Image.Transparency = 1
		bulletHole.CFrame = CFrame.new(Vector3.new(0,-100,0), Vector3.new(0,0,0))
		bulletHole.Parent = availableBulletHoles
	end


end

function module.gun:ShootBullet()
	local shootBulletRemote = RepStorage:WaitForChild("ShootBullet")
	local character = self.player.Character
	local barrel = character:FindFirstChild(self.weaponName).GunComponents.Barrel
	local bullet = availableBullets:FindFirstChild("Bullet")

	for i,v in pairs(game.Players:GetPlayers()) do
		bullet.Anchored = false
		bullet:SetNetworkOwner(v)
		shootBulletRemote:FireClient(v,self.player.Name,barrel,bullet)
	end
end

function module.gun:Kill(hitPart)
	if hitPart.Name == "Head" then
		hitPart.Parent.Humanoid:TakeDamage(self.headshotDamage)
	else
		hitPart.Parent.Humanoid:TakeDamage(self.bodyshotDamage)
	end
end

function module.gun:Hit(hitPart,hitPosition,normal,invincible)
	local cantHit = invincible

	local function bulletHole(Task)
		self:MakeBulletHole(Task,hitPosition,hitPart,normal)
	end

	if hitPart:FindFirstAncestorWhichIsA("Model"):FindFirstChildWhichIsA("Humanoid") then
		task.spawn(bulletHole,"Hurt")
		self:Kill(hitPart)
	else
		task.spawn(bulletHole,"Hit")
		if hitPart.Material == Enum.Material.Glass or hitPart.Material == Enum.Material.Plastic or hitPart.Material == Enum.Material.SmoothPlastic or hitPart.Material == Enum.Material.Wood or hitPart.Material == Enum.Material.WoodPlanks then
			table.insert(cantHit,hitPart)
			self:Wallbang(hitPosition,cantHit)
		end
	end
end

function module.gun:Wallbang(hitPosition,invincible)
	local invincible_2 = invincible
	table.insert(invincible_2,busyBulletHoles:GetDescendants())
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = invincible_2
	raycastParams.IgnoreWater = true

	local raycastResult = game.Workspace:Raycast(hitPosition,self.aimDirection.Value * 1000,raycastParams)
	if raycastResult then
		self:Hit(raycastResult.Instance,raycastResult.Position,raycastResult.Normal,invincible_2)
	else
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		raycastParams.FilterDescendantsInstances = {self.player.Character}
		raycastParams.IgnoreWater = false

		raycastResult = game.Workspace:Raycast(self.aimOrigin.Value,self.aimDirection.Value * 1000,raycastParams)
	end
end

function module.gun:AimSight()
	self.aimAnim:Play()
	self.player.Character.Humanoid.WalkSpeed = 10
end

function module.gun:AimHand()
	self.aimAnim:Stop()
	self.player.Character.Humanoid.WalkSpeed = 16
end

function module.gun:New(t)
	t = t or {}
	setmetatable(t, self)
	self.__index = self
	return t
end

return module