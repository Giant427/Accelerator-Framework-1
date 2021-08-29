repeat
	wait()
until game:IsLoaded()

local characterUpdateRemote = game:GetService("ReplicatedStorage"):WaitForChild("CharacterUpdate")
local shootBulletRemote = game:GetService("ReplicatedStorage"):WaitForChild("ShootBullet")
local bulletsFolder = game.Workspace:WaitForChild("BulletsFolder")
local availableBullets = bulletsFolder:WaitForChild("AvailableBullets")
local busyBullets = bulletsFolder:WaitForChild("BusyBullets")
local camera = game.Workspace.CurrentCamera
local viewmodel = game:GetService("ReplicatedStorage"):WaitForChild("Viewmodel"):Clone()
local localPlayer = game.Players.LocalPlayer

-- swaying
local function swayViewmodel()
	local sway = CFrame.new(0,0,0)
	local mult = 1
	local rotation = game.Workspace.CurrentCamera.CFrame:ToObjectSpace(camera.CFrame)
	local x,y,z = rotation:ToOrientation()
	sway = sway:Lerp(CFrame.Angles(math.sin(x) * mult,math.sin(y) * mult,0), 0.5)
	viewmodel.HumanoidRootPart.CFrame = camera.CFrame * sway
end

-- bobbing
local function bobViewmodel(mult,alpha)
	local t = tick()
	local x = math.cos(t * mult) * alpha
	local y = math.abs(math.sin(t * mult)) * alpha
	viewmodel.HumanoidRootPart.CFrame = viewmodel.HumanoidRootPart.CFrame * CFrame.new(x, y, 0)
end

local function updateViewmodel(dt)
	swayViewmodel()
	if localPlayer.Character.Humanoid.MoveDirection ~= Vector3.new(0,0,0) then
		if localPlayer.Character.Humanoid.WalkSpeed >= 16 then
			bobViewmodel(5,0.3)
		elseif localPlayer.Character.Humanoid.WalkSpeed < 16 then
			bobViewmodel(5,0.05)
		end
	end
end

local function shootBullet(playerName,hitPosition,barrel,bullet)
	bullet.Parent = busyBullets
	if playerName == localPlayer.Name then
		-- viewmodel shoot
		local origin = viewmodel:FindFirstChildWhichIsA("Model"):WaitForChild("GunComponents").Barrel
		local cframe = CFrame.new(origin.Position,hitPosition)
		bullet.Anchored = false
		bullet.BodyPosition.Position = hitPosition
		bullet.Transparency = 0
		bullet.BodyGyro.CFrame = cframe
		bullet.CFrame = cframe
		origin.MuzzleEffect:Emit()
		origin.Smoke:Emit()
	else
		-- character shoot
		local cframe = CFrame.new(barrel.Position,hitPosition)
		bullet.Anchored = false
		bullet.BodyPosition.Position = hitPosition
		bullet.Transparency = 0
		bullet.BodyGyro.CFrame = cframe
		bullet.CFrame = cframe
		barrel.MuzzleEffect:Emit()
		barrel.Smoke:Emit()
	end

	task.wait(0.1)
	bullet.Transparency = 1
	bullet.Anchored = true
	bullet.CFrame = CFrame.new(Vector3.new(0, -100, 0), Vector3.new(0, 0, 0))
	bullet.Parent = availableBullets
end

viewmodel.Parent = game.Workspace.CurrentCamera
for _,v in pairs(viewmodel:GetDescendants()) do
	if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" and v.Name ~= "CameraBone" then
		v.Transparency = 1
	end
end
game:GetService("RunService").RenderStepped:Connect(updateViewmodel)
characterUpdateRemote:FireServer("Setup")
shootBulletRemote.OnClientEvent:Connect(shootBullet)
while wait() do
	wait(0.1)
	characterUpdateRemote:FireServer("Update",viewmodel.HumanoidRootPart.CFrame)
end