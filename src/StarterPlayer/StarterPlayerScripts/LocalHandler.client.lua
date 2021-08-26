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
local cameraCFrame = camera.CFrame

local function updateViewmodel(dt)
	-- swaying
	local function swayViewmodel()
		local sway = CFrame.new(0,0,0)
		local mult = 1
		local rotation = game.Workspace.CurrentCamera.CFrame:ToObjectSpace(cameraCFrame)
		local x,y,z = rotation:ToOrientation()
		sway = sway:Lerp(CFrame.Angles(math.sin(x) * mult,math.sin(y) * mult,0), 0.1)
		viewmodel.HumanoidRootPart.CFrame = camera.CFrame * sway
		cameraCFrame = game.Workspace.CurrentCamera.CFrame
	end
	-- bobbing
	local function bobViewmodel()
		local currentCFrame = camera.CFrame
		local t = tick()
		local x = math.cos(t * 10) * 0.05
		local y = math.abs(math.sin(t * 10)) * 0.05
		local cframe = currentCFrame * CFrame.new(x, y, 0)
		viewmodel.HumanoidRootPart.CFrame = cframe
	end

	swayViewmodel()
	if localPlayer.Character.Humanoid.MoveDirection ~= Vector3.new(0,0,0) and localPlayer.Character.Humanoid.WalkSpeed >= 16 then
		bobViewmodel()
	end
end

local function shootBullet(playerName,hitPosition,barrel)
	local bullet = availableBullets:FindFirstChild("Bullet")
	if playerName == localPlayer.Name then
		-- viewmodel shoot
		local origin = viewmodel:FindFirstChildWhichIsA("Model"):WaitForChild("GunComponents").Barrel
		local cframe = origin.CFrame

		bullet.Parent = busyBullets
		bullet.Anchored = false
		bullet.BodyPosition.Position = hitPosition
		bullet.BodyGyro.CFrame = cframe
		bullet.CFrame = cframe
		origin.MuzzleEffect:Emit()
		origin.Smoke:Emit()
	else
		-- character shoot
		local cframe = CFrame.new(barrel.Position, hitPosition)

		bullet.Parent = busyBullets
		bullet.Anchored = false
		bullet.BodyPosition.Position = hitPosition
		bullet.BodyGyro.CFrame = cframe
		bullet.CFrame = cframe
		barrel.MuzzleEffect:Emit()
		barrel.Smoke:Emit()
	end

	task.wait(0.1)

	bullet.Anchored = true
	bullet.CFrame = CFrame.new(Vector3.new(0, -100, 0), Vector3.new(0, 0, 0))
	bullet.Parent = availableBullets
end

viewmodel.Parent = game.Workspace.CurrentCamera
game:GetService("RunService").RenderStepped:Connect(updateViewmodel)
characterUpdateRemote:FireServer("Setup")
shootBulletRemote.OnClientEvent:Connect(shootBullet)
while wait() do
	wait(0.1)
	characterUpdateRemote:FireServer("Update",viewmodel.HumanoidRootPart.CFrame)
end