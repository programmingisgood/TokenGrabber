
PhysicsMixin = { type = "Physics" }

function PhysicsMixin:__initmixin()

    self.body = nil
    self.maxSpeed = math.huge
    
end

function PhysicsMixin:SetupPhysics(world, setMass, setRotInertia, optionalShape)

    if self.body then
    
        self.body:destroy()
        self.body = nil
        
    end
    
    local pos = self:GetPosition()
    self.body = love.physics.newBody(world, pos.x, pos.y, "dynamic")
    self.body:setMassData(0, 0, setMass, setRotInertia)
    
    if optionalShape then
        self.fixture = love.physics.newFixture(self.body, optionalShape)
    end
    
end

function PhysicsMixin:SetPhysicsType(setType)
    self.body:setType(setType)
end

function PhysicsMixin:SetCollisionCategory(...)

    if self.fixture then
        self.fixture:setCategory(...)
    end
    
end

-- This object will collide with the following categories.
function PhysicsMixin:SetCollisionMask(...)

    if self.fixture then
        self.fixture:setMask(...)
    end
    
end

function PhysicsMixin:SetPosition(newPos)

    if not self.physicsLock then
        self.body:setPosition(newPos.x, newPos.y)
    end
    
end

function PhysicsMixin:GetPhysicsRotation()
    return self.body:getAngle()
end

function PhysicsMixin:ApplyForce(forceVec)
    self.body:applyForce(forceVec.x, forceVec.y)
end

function PhysicsMixin:ApplyLinearImpulse(impulseVec)
    self.body:applyLinearImpulse(impulseVec.x, impulseVec.y)
end

function PhysicsMixin:GetLinearVelocity()

    local x, y = self.body:getLinearVelocity()
    return vec2(x, y)
    
end

function PhysicsMixin:SetLinearVelocity(setVel)
    self.body:setLinearVelocity(setVel.x, setVel.y)
end

function PhysicsMixin:SetLinearDamping(setDamping)
    self.body:setLinearDamping(setDamping)
end

function PhysicsMixin:SetMaxSpeed(setMaxSpeed)
    self.maxSpeed = setMaxSpeed
end

function PhysicsMixin:Update()

    local maxSpeedSq = self.maxSpeed * self.maxSpeed
    local currentLinVel = self:GetLinearVelocity()
    local currentSpeedSq = currentLinVel:LengthSquared()
    if currentSpeedSq > maxSpeedSq then
        self:SetLinearVelocity(currentLinVel:Mul(maxSpeedSq / currentSpeedSq))
    end
    
    local x, y = self.body:getPosition()
    self.physicsLock = true
    self:SetPosition(vec2(x, y))
    self.physicsLock = false
    
end