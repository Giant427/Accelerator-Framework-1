repeat
	wait()
until game:IsLoaded()

local uis = game:GetService("UserInputService")
local cas = game:GetService("ContextActionService")
local runService = game:GetService("RunService")
local gunModelsFolder = game:GetService("ReplicatedStorage"):WaitForChild("Guns"):WaitForChild("Models")

local module = {}

-- gun object properties
module.gun = {
	player = nil,
	mouse = nil,
	viewmodel = nil,

	-- weapon details
	weaponName = "",
	weaponType = "",

	-- stats for the gun
	delay = 0,
	headshotDamage = 0,
	bodyshotDamage = 0,
	curshot = 0,
	lastClick = tick(),
	recoilReset = 1,
	recoilPattern = {
		{10,   4,   4, 0.77, 0.1},
		{20, 0.1, 0.1, 0.77, -80},
		{30, 0.1, 0.1, 0.77,  80},
	},

	-- animations
	holdAnim = nil,
	aimAnim = nil,
	shootAnim = nil,
	reloadAnim = nil,

	-- values in playerVars used for moderation
	equipped = nil,
	reloading = nil,
	ammo = nil,
	magAmmo = nil,

	-- used for full auto configuration
	playerHoldingMouse = false,
	canFire = true,

	remote = nil,
}

-- create a new gun object with given properties
function module.gun:New(t)
	t = t or {}
	setmetatable(t, self)
	self.__index = self
	return t
end

-- remote event functions
function module.gun:Equip()
	local gun = gunModelsFolder:WaitForChild(self.weaponName):Clone()
	local handle = gun:WaitForChild("GunComponents").Handle
	local aim = gun:WaitForChild("GunComponents").Aim

	-- make viewmodel visible
	for _,v in pairs(self.viewmodel:GetDescendants()) do
		if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" and v.Name ~= "CameraBone" then
			v.Transparency = 0
		end
	end

	self.mouse.Icon = game:GetService("ReplicatedStorage"):WaitForChild("InvisibleCrosshair").Image
	self.player.PlayerGui.Crosshair.Frame.Visible = true

	-- no crosshair for snipers
	if self.weaponType == "Sniper" then
		local shootAnimation = game:GetService("ReplicatedStorage"):WaitForChild("Guns"):WaitForChild("Animations"):WaitForChild(self.weaponName.."_Animations"):WaitForChild("Viewmodel_Shoot")
		self.player.PlayerGui.Crosshair.Frame.Visible = false
		self.shootAnim = self.viewmodel:WaitForChild("AnimationController"):LoadAnimation(shootAnimation)
	end

	-- weld gun model
	for _,v in pairs(gun:GetDescendants()) do
		if v:IsA("BasePart") and v ~= handle and v ~= aim then
			local newMotor = Instance.new("Motor6D")
			newMotor.Name = v.Name
			newMotor.Part0 = handle
			newMotor.Part1 = v
			newMotor.C0 = newMotor.Part0.CFrame:inverse() * newMotor.Part1.CFrame -- attach in place
			newMotor.Parent = handle
		end
	end
	gun.Parent = self.viewmodel

	-- weld gun model to viewmodel
	self.viewmodel:WaitForChild("HumanoidRootPart").Handle.Part1 = aim
	self.viewmodel:WaitForChild("HumanoidRootPart").right.Part0 = handle
	self.viewmodel:WaitForChild("HumanoidRootPart").left.Part0 = handle
	self.holdAnim:Play()

	self.equipped.Value = true

	-----------------------------------------------------------------------------------------------------------------------------------------------------

	self:EnableInput()
	runService.Heartbeat:Connect(function(dt)
		self:heartbeat(dt)
	end)
end

function module.gun:Unequip()
	self.equipped.Value = false
	self.holdAnim:Stop()
	self.player.PlayerGui.Crosshair.Frame.Visible = false
	self.mouse.Icon = ""

	-- unbinding actions
	cas:UnbindAction("Reload")
	cas:UnbindAction("MouseButton1")
	cas:UnbindAction("MouseButton2")

	-- remove welds
	self.viewmodel:WaitForChild("HumanoidRootPart").Handle.Part1 = nil
	self.viewmodel:WaitForChild("HumanoidRootPart").right.Part0 = self.viewmodel:WaitForChild("HumanoidRootPart")
	self.viewmodel:WaitForChild("HumanoidRootPart").left.Part0 = self.viewmodel:WaitForChild("HumanoidRootPart")

	self.viewmodel:WaitForChild(self.weaponName):Destroy()

	-- invis the viewmodel
	for _,v in pairs(self.viewmodel:GetDescendants()) do
		if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" and v.Name ~= "CameraBone" then
			v.Transparency = 1
		end
	end
end

-- player input
function module.gun:EnableInput()
	local reload = "Reload"
	local mouse1 = "MouseButton1"
	local mouse2 = "MouseButton2"

	local function handleInput(actionName, inputState, inputObject)
		-- reload
		if actionName == reload and inputState == Enum.UserInputState.Begin then
			if self.reloading.Value == false and self.ammo.Value < self.magAmmo.Value then
				self:Reload()
			end
		end

		-- mouse button 1
		if actionName == mouse1 then
			-- begin
			if inputState == Enum.UserInputState.Begin then
				-- full auto configuration
				if self.weaponType == "FullAuto" then
					self.playerHoldingMouse = true
				end

				-- semi auto configuration
				if self.weaponType == "SemiAuto" then
					if self.canFire then
						self.canFire = false
						self:Shoot()
						wait(self.delay)
						self.canFire = true
					end
				end

				-- burst configuration
				if self.weaponType == "Burst" then
					if self.canFire then
						self.canFire = false
						self:BurstShoot()
						wait(self.delay)
						self.canFire = true
					end
				end

				-- sniper configuration
				if self.weaponType == "Sniper" then
					if self.canFire then
						self.canFire = false
						self:SniperShoot()
						wait(self.delay)
						self.canFire = true
					end
				end
			end

			-- end
			if inputState == Enum.UserInputState.End then
				-- full auto configuration
				if self.weaponType == "FullAuto" then
					self.playerHoldingMouse = false
				end
			end
		end

		-- mouse button 2
		if actionName == mouse2 then
			-- begin
			if inputState == Enum.UserInputState.Begin then
				if self.reloading.Value == false then
					self:AimSight()
				end
			end

			-- end
			if inputState == Enum.UserInputState.End then
				if self.reloading.Value == false then
					self:AimHand()
				end
			end
		end
	end

	-- reload
	cas:BindAction(reload, handleInput, true, Enum.KeyCode.R)
	cas:SetTitle(reload,"Reload")
	-- mouse button 1
	cas:BindAction(mouse1, handleInput, true, Enum.UserInputType.MouseButton1)
	cas:SetTitle(mouse1,"Shoot")
	-- mouse button 2
	cas:BindAction(mouse2, handleInput, true, Enum.UserInputType.MouseButton2)
	cas:SetTitle(mouse2,"Aim")
end

function module.gun:heartbeat(dt)
	if self.equipped.Value == true then
		if self.playerHoldingMouse == true then
			if self.canFire == true then
				self.canFire = false
				self:Shoot()
				task.wait(self.delay)
				self.canFire = true
			end
		end

		-- ammo gui
		self.player.PlayerGui.Ammo.Ammo.Text = self.ammo.Value.."/"..self.magAmmo.Value
	end
end

-- reload function
function module.gun:Reload()
	if self.ammo.Value < self.magAmmo.Value and self.reloading.Value == false then
		self.reloading.Value = true
		self:AimHand()
		self.remote:FireServer("Reload")
		self.reloadAnim:Play()
		wait(self.reloadAnim.Length)
		self.reloading.Value = false
	end
end

-- shoot and bullet functions
function module.gun:Recoil()
	local Run = game:GetService("RunService")
	local Camera = game.Workspace.CurrentCamera

	local function lerp(a, b, t)
		return a * (1 - t) + (b * t)
	end

	local function ShootRecoil()
		self.curshot = (tick() - self.lastClick > self.recoilReset and 1 or self.curshot + 1) -- Either reset or increase the current shot we're at
		self.lastClick = tick()

		for i, v in pairs(self.recoilPattern) do
			if self.curshot <= v[1] then -- Found the current recoil we're at
				task.spawn(function()
					local num = 0
					while math.abs(num - v[2]) > 0.01 do
						num = lerp(num, v[2], v[4])
						local rec = num / 10
						Camera.CFrame = Camera.CFrame * CFrame.Angles(math.rad(rec), math.rad(rec * v[5]), 0)
						Run.RenderStepped:Wait()
					end
					while math.abs(num - v[3]) > 0.01 do
						num = lerp(num, v[3], v[4])
						local rec = num / 10
						Camera.CFrame = Camera.CFrame * CFrame.Angles(math.rad(rec), math.rad(rec * v[5]), 0)
						Run.RenderStepped:Wait()
					end
				end)
				break
			end
		end
	end

	local originalCFrame = self.viewmodel.HumanoidRootPart.CFrame
	self.viewmodel.HumanoidRootPart.CFrame = self.viewmodel.HumanoidRootPart.CFrame * CFrame.new(0,0,-1)
	ShootRecoil()
	task.wait()
	self.viewmodel.HumanoidRootPart.CFrame = originalCFrame
end

-- used for semi auto and full auto configurations
function module.gun:Shoot()
	if self.ammo.Value > 0 and self.reloading.Value == false then
		self.remote:FireServer("Shoot")
		self:Recoil()
		self.ammo.Value -= 1
	else
		if self.ammo.Value == 0 and self.reloading.Value == false then
			self:Reload()
			return
		end
	end
end

-- burst configurations
function module.gun:BurstShoot()
	-- shoot 3 bullets
	for i = 1,3,1 do
		if self.ammo.Value > 0 and self.reloading.Value == false then
			self.remote:FireServer("Shoot")
			self:Recoil()
			self.ammo.Value -= 1
		else
			if self.ammo.Value == 0 and self.reloading.Value == false then
				self:Reload()
				return
			end
		end
		wait(0.1)
	end
end

-- sniper configuration
function module.gun:SniperShoot()
	if self.ammo.Value > 0 and self.reloading.Value == false then
		self.remote:FireServer("Shoot")
		self:Recoil()
		self.ammo.Value -= 1
		self:AimHand()
		self.shootAnim:Play()
	else
		if self.ammo.Value == 0 and self.reloading.Value == false then
			self:Reload()
			return
		end
	end
end

-- used to change the transparency of the viewmodel
function module.gun:ChangeViewmodelTransparency(value)
	for i,v in pairs(self.viewmodel:GetChildren()) do
		-- arms
		if v:IsA("Folder") then
			for _,child in pairs(v:GetChildren()) do
				if child:IsA("BasePart") then
					child.Transparency = value
				end
			end
		end
		-- gun
		if v:IsA("Model") then
			for _,child in pairs(v:GetChildren()) do
				if child:IsA("BasePart") then
					child.Transparency = value
				end
			end
		end
	end
end

-- aim functions
function module.gun:AimSight()
	self.player.PlayerGui.Crosshair.Frame.Visible = false
	self.aimAnim:Play()
	self.remote:FireServer("AimSight")
	if self.weaponType == "Sniper" then
		game.Workspace.CurrentCamera.FieldOfView = 40
		self:ChangeViewmodelTransparency(1)
		self.player.PlayerGui.Crosshair.ScopeFrame.Visible = true
	else
		game.Workspace.CurrentCamera.FieldOfView = 60
	end
end

function module.gun:AimHand()
	game.Workspace.CurrentCamera.FieldOfView = 70
	self.aimAnim:Stop()
	self.holdAnim:Play()
	self.remote:FireServer("AimHand")

	if self.weaponType == "Sniper" then
		self.player.PlayerGui.Crosshair.ScopeFrame.Visible = false
		self:ChangeViewmodelTransparency(0)
	else
		self.player.PlayerGui.Crosshair.Frame.Visible = true
	end
end

return module