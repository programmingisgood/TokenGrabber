
local kJumpTimeMin = 0.5
local kJumpTimeMax = 2

local kJumpSpeedMin = 92
local kJumpSpeedMax = 130
local kSlowDownRate = 59.5

local kClampSpeedAt = 90

JumpAroundMixin = { type = "JumpAround" }

function JumpAroundMixin:__initmixin()

    self.timeToJump = RandomFloatBetween(kJumpTimeMin, kJumpTimeMax)
    self.velocity = vec2(0, 0)
    self:SetRotation(RandomAngle())
    
end

function JumpAroundMixin:Update(dt)

    self.timeToJump = self.timeToJump - dt
    if self.timeToJump <= 0 then
    
        self.timeToJump = RandomFloatBetween(kJumpTimeMin, kJumpTimeMax)
        self:OnJump()
        self.velocity = vec2(RandomClamped(), RandomClamped()):Normalize():Mul(RandomFloatBetween(kJumpSpeedMin, kJumpSpeedMax))
        self:SetRotation(self.velocity:ToAngle())
        
    end
    
    self:SetPosition(self:GetPosition():Add(self.velocity:Mul(dt)))
    
    self.velocity = self.velocity:Mul(kSlowDownRate * dt)
    
    if self.velocity:LengthSquared() <= (kClampSpeedAt * kClampSpeedAt) then
        self.velocity = vec2(0, 0)
    end
    
    -- When jumping, they look to be above the ground.
    self:SetScale(vec2(1, 1))
    if self.velocity:LengthSquared() > 0 then
        self:SetScale(vec2(1.3, 1.3))
    end
    
end