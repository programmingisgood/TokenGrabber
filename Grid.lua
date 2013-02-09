
local function Add(self, gridObject)

    assert(gridObject ~= nil)
    assert(HasMixin(gridObject, "Movable"))
    assert(HasMixin(gridObject, "Grid"))
    
    self.objects[gridObject] = true
    
end

local function Remove(self, gridObject)
    self.objects[gridObject] = nil
end

local function GetGridPosition(self, worldPos)

    local gridPos = vec2(0, 0)
    gridPos.x = Round(worldPos.x / self.pointWidth) * self.pointWidth
    gridPos.y = Round(worldPos.y / self.layerHeight) * self.layerHeight
    return gridPos
    
end

local function GetLayerAt(self, atPos)

    local layer = 0
    local gridPos = GetGridPosition(self, atPos)
    
    for obj, _ in pairs(self.objects) do
    
        if obj:GetGridPosition():Equals(gridPos) then
            layer = math.max(obj:GetGridLayer(), layer)
        end
        
    end
    
    return layer
    
end

local function ConvertGridToWorld(self, gridPos, gridLayer)

    local worldPos = vec2(gridPos.x, gridPos.y)
    worldPos.y = worldPos.y - ((gridLayer - 1) * self.layerHeight)
    return worldPos
    
end

local function GetObjectAtGridPoint(self, gridPoint)

    for obj, _ in pairs(self.objects) do
    
        if obj:GetGridPosition():Equals(gridPoint) then
            return obj
        end
        
    end
    
    return nil
    
end

local function Draw(self)

    -- Sort into rows based on y coordinate.
    local rows = { }
    -- Find all the objects that cause other objects to be semitransparent.
    local viewingObjects = { }
    for obj, _ in pairs(self.objects) do
    
        local yCoord = obj:GetGridPosition().y
        rows[yCoord] = rows[yCoord] or { }
        table.insert(rows[yCoord], obj)
        if obj:GetGridViewer() then
            table.insert(viewingObjects, obj)
        end
        
    end
    
    local rowsSorted = { }
    for _, row in pairs(rows) do table.insert(rowsSorted, row) end
    table.sort(rowsSorted, function(a, b) return a[1]:GetGridPosition().y < b[1]:GetGridPosition().y end)
    
    for _, row in ipairs(rowsSorted) do
    
        -- Sort based on grid position.
        table.sort(row, function(a, b) return a:GetGridLayer() < b:GetGridLayer() end)
        for _, obj in ipairs(row) do
        
            local usesGridPosition = obj:GetUsesGridPositionForRendering()
            local savedPos = obj:GetPosition()
            if usesGridPosition then
                obj:SetPosition(ConvertGridToWorld(self, obj:GetGridPosition(), obj:GetGridLayer()))
            end
            
            local savedColor = obj:GetColor()
            
            if not obj:GetGridViewer() then
            
                for v = 1, #viewingObjects do
                
                    viewer = viewingObjects[v]
                    if viewer:GetGridPosition().x == obj:GetGridPosition().x then
                    
                        local yDiff = obj:GetGridPosition().y - viewer:GetGridPosition().y 
                        if yDiff > 0 and yDiff <= 2 * self.pointHeight then
                        
                            local newColor = color(savedColor:unpack())
                            newColor.a = 100
                            obj:SetColor(newColor)
                            
                        end
                        
                    end
                    
                end
                
            end
            
            obj:Draw()
            
            obj:SetColor(savedColor)
            
            if usesGridPosition then
                obj:SetPosition(savedPos)
            end
            
        end
        
    end
    
end

local function Create(worldWidth, worldHeight, pointWidth, pointHeight, numLayers, layerHeight)

    local grid = { }
    
    grid.worldWidth = worldWidth
    grid.worldHeight = worldHeight
    grid.pointWidth = pointWidth
    grid.pointHeight = pointHeight
    grid.numLayers = numLayers
    grid.layerHeight = layerHeight
    
    grid.Add = Add
    grid.Remove = Remove
    grid.GetGridPosition = GetGridPosition
    grid.GetLayerAt = GetLayerAt
    grid.ConvertGridToWorld = ConvertGridToWorld
    grid.GetObjectAtGridPoint = GetObjectAtGridPoint
    grid.Draw = Draw
    
    grid.objects = { }
    -- Only retain a weak reference to the objects.
    local gridMT = { mode = "k" }
    setmetatable(grid.objects, gridMT)
    
    return grid
    
end

return { Create = Create }