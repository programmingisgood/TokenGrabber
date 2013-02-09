
LiveMixin = { type = "Live" }

function LiveMixin:__initmixin()

    self.health = 100
    self.maxHealth = 100
    self.alive = true
    
end

function LiveMixin:SetHealth(setHealth, setMaxHealth)

    self.health = setHealth
    self.maxHealth = setMaxHealth
    
end

function LiveMixin:TakeDamage(amount)

    self.health = math.max(0, self.health - amount)
    if self.alive and self.health == 0 then
    
        self.alive = false
        if self.OnKilled then
            self:OnKilled()
        end
        
    end
    
end