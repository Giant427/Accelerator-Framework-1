local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer
local camera = game.Workspace.CurrentCamera
local DOF = game.Lighting:WaitForChild("DepthOfField")

RunService.Heartbeat:Connect(function()
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {player.Character:GetDescendants(),camera:GetDescendants()}
    raycastParams.IgnoreWater = true

    local raycastResult = game.Workspace:Raycast(camera.CFrame.Position,camera.CFrame.LookVector * 1000,raycastParams)
    if raycastResult then
        DOF.FocusDistance = (raycastResult.Position - camera.CFrame.Position).Magnitude
    end
    print(DOF.FocusDistance.."\n"..raycastResult.Position.Magnitude)
end)