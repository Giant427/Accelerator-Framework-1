local characterUpdate = game:GetService("ReplicatedStorage"):WaitForChild("CharacterUpdate")
local camera = game.Workspace.CurrentCamera
local viewmodel = game:GetService("ReplicatedStorage"):WaitForChild("Viewmodel"):Clone()
viewmodel.Parent = game.Workspace.CurrentCamera

local localPlayer = game.Players.LocalPlayer
local mouse = localPlayer:GetMouse()
local crosshair = localPlayer.PlayerGui:WaitForChild("Crosshair").Frame

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
		local currentCFrame = game.Workspace.CurrentCamera.CFrame
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
	
	crosshair.Position = UDim2.new(0,mouse.X,0,mouse.Y)
end

game:GetService("RunService").RenderStepped:Connect(updateViewmodel)
characterUpdate:FireServer("Setup")
while wait() do
	wait(0.1)
	local camCframe = camera.CFrame
	characterUpdate:FireServer("Update",viewmodel.HumanoidRootPart.CFrame)
end