
CollectorMixin = { type = "Collector" }

function CollectorMixin:__initmixin(world, collectRange)

    assert(world)
    
    self.world = world
    self.collectRange = collectRange or 16
    
end

function CollectorMixin:Update(dt)

    local nearbyCollectibles = self.world:Query("Collectible", self:GetPosition(), self.collectRange)
    for c = 1, #nearbyCollectibles do
    
        local collectible = nearbyCollectibles[c]
        if collectible:GetIsCollectible() then
            nearbyCollectibles[c]:OnCollected(self)
        end
        
    end
    
end