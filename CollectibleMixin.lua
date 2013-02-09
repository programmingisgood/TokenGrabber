
CollectibleMixin = { type = "Collectible" }

function CollectibleMixin:__initmixin()

    -- The OnCollected callback should be implemented.
    assert(self.OnCollected)
    
    self.collectible = true
    
end

function CollectibleMixin:SetIsCollectible(collectible)
    self.collectible = collectible
end

function CollectibleMixin:GetIsCollectible()
    return self.collectible
end