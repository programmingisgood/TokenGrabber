
SeekFoodMixin = { type = "SeekFood" }

function SeekFoodMixin:__initmixin()
end

local function SearchForFood(self)

end

local function SearchForScent(self)

end

local function MoveRandomly(self, dt)

end

function SeekFoodMixin:Update(dt)

    -- Look for nearby food.
    local foundFood = SearchForFood(self)
    
    -- If that fails, look for scent trail.
    if not foundFood then
    
        local foundScent = SearchForScent(self)
        
        -- If that fails, move around randomly.
        if not foundScent then
            MoveRandomly(self, dt)
        end
        
    end
    
end