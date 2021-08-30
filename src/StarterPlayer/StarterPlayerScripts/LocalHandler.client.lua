repeat
	wait()
until game:IsLoaded()

local characterUpdateRemote = game:GetService("ReplicatedStorage"):WaitForChild("CharacterUpdate")
local shootBulletRemote = game:GetService("ReplicatedStorage"):WaitForChild("ShootBullet")

local bulletsFolder = game.Workspace:WaitForChild("BulletsFolder")
local availableBullets = bulletsFolder:WaitForChild("AvailableBullets")
local busyBullets = bulletsFolder:WaitForChild("BusyBullets")

local camera = game.Workspace.CurrentCamera
local localPlayer = game.Players.LocalPlayer
local viewmodel = game:GetService("ReplicatedStorage"):WaitForChild("Viewmodel"):Clone()

local springModule = require(game:GetService("ReplicatedStorage"):WaitForChild("ClientModules"):WaitForChild("Spring"))
local walkCycleSpring = springModule:New()
local swaySpring = springModule:New()

-- getBobbing
local function getBobbing(addition,speed,modifier)
	return math.sin(tick()*addition*speed)*modifier
end

local function updateViewmodel(dt)
	local velocity = localPlayer.Character.HumanoidRootPart.Velocity
	local mouseDelts = game:GetService("UserInputService"):GetMouseDelta()
	swaySpring:shove(Vector3.new(mouseDelts.X / 200, mouseDelts.Y / 200))

	local speed = 0.8
	local modifier = 0.1
	local movementSway = Vector3.new(getBobbing(10,speed,modifier),getBobbing(5,speed,modifier),getBobbing(5,speed,modifier))
	walkCycleSpring:shove((movementSway / 25) * dt * 60 * velocity.Magnitude)

	local sway = swaySpring:update(dt)
	local walkCycle = walkCycleSpring:update(dt)

	viewmodel.HumanoidRootPart.CFrame = camera.CFrame
	viewmodel.HumanoidRootPart.CFrame = viewmodel.HumanoidRootPart.CFrame:ToWorldSpace(CFrame.new(walkCycle.x / 2,walkCycle.y / 2,0))

	viewmodel.HumanoidRootPart.CFrame = viewmodel.HumanoidRootPart.CFrame * CFrame.Angles(0,sway.x,sway.y)
	viewmodel.HumanoidRootPart.CFrame = viewmodel.HumanoidRootPart.CFrame * CFrame.Angles(walkCycle.x / 2,walkCycle.y / 2,0)
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