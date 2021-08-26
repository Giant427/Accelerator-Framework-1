local folder = game:GetService("ServerStorage"):WaitForChild("WeaponStats")
local replicatedStorage = game:GetService("ReplicatedStorage")
local characterUpdate = replicatedStorage:WaitForChild("CharacterUpdate")

game.Players.PlayerAdded:Connect(function(player)
	local playerVars = Instance.new("Folder", player)
	playerVars.Name = "PlayerVars"
	for i, v in ipairs(folder:GetChildren()) do
		local clone = v:Clone()
		clone.Parent = playerVars
	end
end)

characterUpdate.OnServerEvent:Connect(function(player,task,theta)
	if task == "Setup" then
		local tiltPart = Instance.new("Part")
		tiltPart.Size = Vector3.new(.1, .1, .1)
		tiltPart.Transparency = 1
		tiltPart.CanCollide = false
		tiltPart.Name = "tiltPart"
		tiltPart.Parent = player.Character

		local bodyPos = Instance.new("BodyPosition")
		bodyPos.Parent = tiltPart
		bodyPos.D = 5000
		bodyPos.P = 1000000
		bodyPos.MaxForce = Vector3.new(1000000,1000000,1000000)
		
		local neck = player.Character.Head.Neck
		local waist = player.Character.UpperTorso.Waist
		local rShoulder = player.Character.RightUpperArm.RightShoulder
		local lShoulder = player.Character.LeftUpperArm.LeftShoulder

		local neckC0 = neck.C0
		local waistC0 = waist.C0
		local rShoulderC0 = rShoulder.C0
		local lShoulderC0 = lShoulder.C0

		game:GetService("RunService").Heartbeat:Connect(function(dt)
			local value = tiltPart.Position.X
			neck.C0 = neckC0 * CFrame.fromEulerAnglesYXZ(value*0.5, 0, 0)
			waist.C0 = waistC0 * CFrame.fromEulerAnglesYXZ(value*0.5, 0, 0)
			rShoulder.C0 = rShoulderC0 * CFrame.fromEulerAnglesYXZ(value*0.5, 0, 0)
			lShoulder.C0 = lShoulderC0 * CFrame.fromEulerAnglesYXZ(value*0.5, 0, 0)
		end)
	end

	if task == "Update" then
		local aimVars = player:WaitForChild("PlayerVars"):WaitForChild("Aim")
		local aimDirection = aimVars:WaitForChild("AimDirection")
		local aimOrigin = aimVars:WaitForChild("AimOrigin")
		local tPart = player.Character:WaitForChild("tiltPart")
		if tPart then
			tPart.BodyPosition.Position = Vector3.new(math.asin(theta.LookVector.Y), 0, 0)
		end
		if aimDirection then
			aimDirection.Value = theta.LookVector
		end
		if aimOrigin then
			aimOrigin.Value = theta.Position
		end
	end
end)