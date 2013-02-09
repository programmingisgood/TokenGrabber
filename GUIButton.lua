
local function GetExtents(self)

    local textHalfWidth = self.font:getWidth(self.text) / 2
    local textHalfHeight = self.font:getHeight() / 2
    
    return vec2(self.pos.x - textHalfWidth, self.pos.y - textHalfHeight),
           vec2(self.pos.x + textHalfWidth, self.pos.y + textHalfHeight)
    
end

local function SetHighlighted(self, highlighted)
    self.highlighted = highlighted
end

local function Draw(self)

    love.graphics.setFont(self.font)
    
    if self.highlighted then
        love.graphics.setColor(255, 255, 255, 255)
    else
        love.graphics.setColor(200, 200, 200, 200)
    end
    
    local textWidth = self.font:getWidth(self.text)
    local textHeight = self.font:getHeight()
    
    --love.graphics.rectangle("line", self.pos.x - textWidth / 2, self.pos.y - textHeight / 2, textWidth, textHeight)
    
    love.graphics.print(self.text, self.pos.x - textWidth / 2, self.pos.y - textHeight / 2)
    
end

local function Create(font, text, pos)

    local button = { }
    
    button.font = font
    button.text = text
    button.pos = pos
    button.highlighted = false
    button.GetExtents = GetExtents
    button.SetHighlighted = SetHighlighted
    button.Draw = Draw
    
    return button
    
end

return { Create = Create }