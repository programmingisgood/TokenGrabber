
UsableMixin = { type = "Usable" }

function UsableMixin:__initmixin(timeToUse, timeLostRate, usableDistance, drawBar)

    self.timeToUse = timeToUse or 0.5
    self.timeLostRate = timeLostRate or 0.2
    self.timeUsed = 0
    self.usableDistance = usableDistance or 16
    self.drawBar = true
    if drawBar ~= nil then
        self.drawBar = drawBar
    end
    
end

function UsableMixin:GetUseDistance()
    return self.usableDistance
end

function UsableMixin:GetUseProgress()
    return self.timeUsed / self.timeToUse
end

function UsableMixin:Use(dt)

    if self.timeUsed == 0 and self.OnUseBegin then
        self:OnUseBegin()
    end
    
    self.timeUsed = self.timeUsed + dt
    if self.OnUseProgress then
        self:OnUseProgress(self:GetUseProgress())
    end
    
    if self.timeUsed >= self.timeToUse then
    
        self.timeUsed = 0
        if self.OnUseEnd then
            self:OnUseEnd()
        end
        
    end
    
end

function UsableMixin:Update(dt)
    self.timeUsed = math.max(0, self.timeUsed - self.timeLostRate * dt)
end

function UsableMixin:Draw()

    local progress = self:GetUseProgress()
    if self.drawBar and progress > 0 then
    
        local barWidth = 24
        local barHeight = 8
        local pos = self:GetPosition():Sub(vec2(barWidth / 2, barHeight / 2))
        if HasMixin(self, "Sprite") then
            pos.y = pos.y - self:GetHeight()
        end
        love.graphics.setColor(200, 200, 200, 255)
        love.graphics.rectangle("fill", pos.x, pos.y, barWidth, barHeight)
        love.graphics.setColor(80, 180, 80, 255)
        love.graphics.rectangle("fill", pos.x, pos.y, barWidth * progress, barHeight)
        
    end
    
end