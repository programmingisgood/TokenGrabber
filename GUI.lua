
local function GetContains(point, topLeft, bottomRight)

    return point.x >= topLeft.x and point.x <= bottomRight.x and
           point.y >= topLeft.y and point.y <= bottomRight.y
    
end

local function OnKeyPressed(self, keyPressed)

    if self.focusedItem and self.focusedItem.OnKeyPressed then
        self.focusedItem:OnKeyPressed(keyPressed)
    end
    
end

local function OnKeyReleased(self, keyReleased)

    if self.focusedItem and self.focusedItem.OnKeyReleased then
        self.focusedItem:OnKeyReleased(keyReleased)
    end
    
end

local function Update(self, dt)

    local mouseX, mouseY = love.mouse.getPosition()
    
    for g = 1, #self.guiList do
    
        local guiItem = self.guiList[g]
        local mouseOver = GetContains(vec2(mouseX, mouseY), guiItem:GetExtents())
        
        if guiItem.SetHighlighted then
            guiItem:SetHighlighted(mouseOver)
        end
        
        if mouseOver and love.mouse.isDown("l") then
        
            if self.focusedItem ~= guiItem then
            
                if self.focusedItem and self.focusedItem.OnBlur then
                    self.focusedItem:OnBlur()
                end
                
                if guiItem.OnFocus then
                    guiItem:OnFocus()
                end
                
                self.focusedItem = guiItem
                
            end
            
            if guiItem.OnClick then
                guiItem:OnClick()
            end
            
        end
        
    end
    
end

local function Draw(self)

    for g = 1, #self.guiList do
        self.guiList[g]:Draw()
    end
    
end

local function Add(self, addGUI)
    table.insert(self.guiList, addGUI)
end

local function Create()

    local gui = { }
    
    gui.focusedItem = nil
    gui.guiList = { }
    gui.OnKeyPressed = OnKeyPressed
    gui.OnKeyReleased = OnKeyReleased
    gui.Update = Update
    gui.Draw = Draw
    gui.Add = Add
    
    return gui
    
end

return { Create = Create }