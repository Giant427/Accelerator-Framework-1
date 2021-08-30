local ITERATIONS = 8
local SPRING = {
    Target = Vector3.new();
    Position = Vector3.new();
    Velocity = Vector3.new();

    Mass = 5;
    Force = 50;
    Damping	= 4;
    Speed = 4;
}

-- creating a new spring
function SPRING:New(t)
	t = t or {}
	setmetatable(t, self)
	self.__index = self
	return t
end

-- shoving the spring
function SPRING:shove(force)
    local x, y, z = force.X, force.Y, force.Z
    if x ~= x or x == math.huge or x == -math.huge then
        x = 0
    end
    if y ~= y or y == math.huge or y == -math.huge then
        y = 0
    end
    if z ~= z or z == math.huge or z == -math.huge then
        z = 0
    end
    self.Velocity = self.Velocity + Vector3.new(x, y, z)
end

-- updating the spring
function SPRING:update(dt)
    local scaledDeltaTime = math.min(dt,1) * self.Speed / ITERATIONS

    for i = 1, ITERATIONS do
        local iterationForce = self.Target - self.Position
        local acceleration = (iterationForce * self.Force) / self.Mass

        acceleration = acceleration - self.Velocity * self.Damping

        self.Velocity = self.Velocity + acceleration * scaledDeltaTime
        self.Position = self.Position + self.Velocity * scaledDeltaTime
    end

    return self.Position
end

return SPRING