repeat
	task.wait()
until game:IsLoaded()

local uis = game:GetService("UserInputService")
local cas = game:GetService("ContextActionService")
local runService = game:GetService("RunService")
local gunModelsFolder = game:GetService("ReplicatedStorage"):WaitForChild("Guns"):WaitForChild("Models")
local tweenService = game:GetService("TweenService")
local tweeningInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, 0, false)

local module = {}

-- gun object properties
module.gun = {
	player = nil,
	mouse = nil,
	viewmodel = nil,

	-- weapon details
	weaponName = "",
	weaponType = "",
	weaponOffset = CFrame.new(),

	-- stats for the gun
	delay = 0,
	headshotDamage = 0,
	bodyshotDamage = 0,
	curshot = 0,
	lastClick = tick(),
	recoilReset = 1,
	recoilPattern = {
		{3,   4,   4, 0.77, 1},
		{6, 0.1, 0.1, 0.4, -40},
		{9,   4,   4, 0.77, -1},
		{12, 0.1, 0.1, 0.4, 40},
		{15,   4,   4, 0.77, 1},
		{18, 0.1, 0.1, 0.4, -40},
		{21,   4,   4, 0.77, -1},
		{24, 0.1, 0.1, 0.4, 40},
		{27,   4,   4, 0.77, 1},
		{30, 0.1, 0.1, 0.4, -40},
	},
	--[[
		{10,   4,   4, 0.77, 0.1},
		{20, 0.1, 0.1, 0.77, -80},
		{30, 0.1, 0.1, 0.77,  80},
	]]--
	-- animations
	holdAnim = nil,
	shootAnim = nil,
	reloadAnim = nil,

	-- values in playerVars used for moderation
	equipped = nil,
	reloading = nil,
	ammo = nil,
	magAmmo = nil,

	-- used for combat
	playerHoldingMouse = false,
	canFire = true,
	processedAim = true,

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
	self:AimHand()
	self.viewmodel:WaitForChild("HumanoidRootPart").Handle.C0 = self.weaponOffset
	self.equipped.Value = true
	self:ChangeViewmodelTransparency(0)

	-----------------------------------------------------------------------------------------------------------------------------------------------------

	self:EnableInput()
	runService.Heartbeat:Connect(function(dt)
		self:heartbeat(dt)
	end)
end

function module.gun:Unequip()
	-- invis the viewmodel
	self:ChangeViewmodelTransparency(1)

	self.equipped.Value = false

	self.holdAnim:Stop()
	self.reloadAnim:Stop()
	if self.shootAnim then
		self.shootAnim:Stop()
	end

	-- remove welds
	self.viewmodel:WaitForChild("HumanoidRootPart").Handle.Part1 = nil
	self.viewmodel:WaitForChild("HumanoidRootPart").right.Part0 = self.viewmodel:WaitForChild("HumanoidRootPart")
	self.viewmodel:WaitForChild("HumanoidRootPart").left.Part0 = self.viewmodel:WaitForChild("HumanoidRootPart")

	self.viewmodel:WaitForChild(self.weaponName):Destroy()

	-- unbinding actions
	cas:UnbindAction("Reload")
	cas:UnbindAction("MouseButton1")
	cas:UnbindAction("MouseButton2")

	self.mouse.Icon = ""
	self.player.PlayerGui.Crosshair.Frame.Visible = false
	self.player.PlayerGui.Crosshair.ScopeFrame.Visible = false
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
						task.wait(self.delay)
						self.canFire = true
					end
				end

				-- burst configuration
				if self.weaponType == "Burst" then
					if self.canFire then
						self.canFire = false
						self:BurstShoot()
						task.wait(self.delay)
						self.canFire = true
					end
				end

				-- sniper configuration
				if self.weaponType == "Sniper" then
					if self.canFire then
						self.canFire = false
						self:SniperShoot()
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
		task.wait(self.reloadAnim.Length)
		self.reloading.Value = false
		self.canFire = true
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

	task.spawn(function()
		ShootRecoil()
		local num = 0
		local coil = 2
		local cframe = 0
		while math.abs(num - coil) > 0.01 do
			num = lerp(num, coil, 0.77)
			local rec = num / 1
			cframe += rec
			self.viewmodel.HumanoidRootPart.Handle.C0 = self.viewmodel.HumanoidRootPart.Handle.C0 * CFrame.new(0, 0, math.rad(rec))
			Run.RenderStepped:Wait()
		end
		self.viewmodel.HumanoidRootPart.Handle.C0 = self.viewmodel.HumanoidRootPart.Handle.C0 * CFrame.new(0, 0, -math.rad(cframe))
	end)
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
		end
	end
	if self.ammo.Value == 0 and self.reloading.Value == false then
		self:Reload()
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
		task.wait(0.1)
		if self.ammo.Value == 0 and self.reloading.Value == false then
			self:Reload()
		end
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
		task.wait(self.shootAnim.Length)
		self.canFire = true
	else
		if self.ammo.Value == 0 and self.reloading.Value == false then
			self:Reload()
			return
		end
	end
	if self.ammo.Value == 0 and self.reloading.Value == false then
		self:Reload()
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
	repeat
		task.wait()
	until self.processedAim == true
	self.processedAim = false
	self.player.PlayerGui.Crosshair.Frame.Visible = false
	self.remote:FireServer("AimSight")
	tweenService:Create(self.viewmodel.HumanoidRootPart.Handle,tweeningInfo,{C0 = CFrame.new(0,0,0, 1,0,0, 0,1,0, 0,0,1)}):Play()
	runService.RenderStepped:Wait()

	if self.weaponType == "Sniper" then
		tweenService:Create(game.Workspace.CurrentCamera,tweeningInfo,{FieldOfView = 40}):Play()
		task.wait(tweeningInfo.Time)
		self:ChangeViewmodelTransparency(1)
		self.player.PlayerGui.Crosshair.ScopeFrame.Visible = true
	else
		tweenService:Create(game.Workspace.CurrentCamera,tweeningInfo,{FieldOfView = 60}):Play()
		task.wait(tweeningInfo.Time)
	end

	self.player.PlayerScripts.DynamicBlur.Disabled = false
	if game.Lighting:FindFirstChild("DepthOfField") then
		game.Lighting:WaitForChild("DepthOfField").Enabled = true
	end
	self.processedAim = true
end

function module.gun:AimHand()
	repeat
		task.wait()
	until self.processedAim == true
	self.processedAim = false

	if game.Lighting:FindFirstChild("DepthOfField") then
		game.Lighting:WaitForChild("DepthOfField").Enabled = false
	end
	self.player.PlayerScripts.DynamicBlur.Disabled = true
	runService.RenderStepped:Wait()
	self.player.PlayerGui.Crosshair.ScopeFrame.Visible = false
	self.remote:FireServer("AimHand")
	if self.weaponType == "Sniper" then
		self:ChangeViewmodelTransparency(0)
	else
		self.player.PlayerGui.Crosshair.Frame.Visible = true
	end
	tweenService:Create(game.Workspace.CurrentCamera,tweeningInfo,{FieldOfView = 70}):Play()
	tweenService:Create(self.viewmodel.HumanoidRootPart.Handle,tweeningInfo,{C0 = self.weaponOffset}):Play()
	task.wait(tweeningInfo.Time)

	self.processedAim = true
end

return module