local characterUpdate = game:GetService("ReplicatedStorage"):WaitForChild("CharacterUpdate")
local camera = game.Workspace.CurrentCamera
local yLookVector = camera.CFrame.LookVector.Y
local viewmodel = game:GetService("ReplicatedStorage"):WaitForChild("Viewmodel"):Clone()
viewmodel.Parent = game.Workspace.CurrentCamera
local localPlayer = game.Players.LocalPlayer
local mouse = localPlayer:GetMouse()
local crosshair = localPlayer.PlayerGui:WaitForChild("Crosshair").Frame

local function updateViewmodel()
    if camera:FindFirstChild("Viewmodel") then
		camera.Viewmodel.HumanoidRootPart.CFrame = camera.CFrame
	end
	crosshair.Position = UDim2.new(0,mouse.X,0,mouse.Y)
end

for _,v in pairs(viewmodel:GetDescendants()) do
	if v:IsA("BasePart") then
		v.Transparency = 1
	end
end

game:GetService("RunService").RenderStepped:Connect(updateViewmodel)

characterUpdate:FireServer("Setup")

while wait() do
	wait(0.1)
	characterUpdate:FireServer("Update",camera.CFrame)
end