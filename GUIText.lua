
local function GetExtents(self)

    local textHalfWidth = math.max(self.minWidth, self.font:getWidth(self.text) / 2)
    local textHalfHeight = self.font:getHeight() / 2
    
    return vec2(self.pos.x - textHalfWidth, self.pos.y - textHalfHeight),
           vec2(self.pos.x + textHalfWidth, self.pos.y + textHalfHeight)
    
end

local function GetText(self)
    return self.text
end

local function SetText(self, text)
    self.text = text
end

local function Clear(self)
    self.text = ""
end

local function SetReadOnly(self, setReadOnly)
    self.readOnly = setReadOnly
end

local function OnFocus(self)
    self.focused = true
end

local function OnBlur(self)
    self.focused = false
end

local function OnKeyPressed(self, keyPressed)

    if not self.readOnly then
    
        if keyPressed == "backspace" then
            self.text = string.sub(self.text, 1, #self.text - 1)
        elseif string.len(keyPressed) == 1 then
            self.text = self.text .. keyPressed
        end
        
    end
    
end

local function Draw(self)

    love.graphics.setFont(self.font)
    
    if self.focused then
        love.graphics.setColor(255, 255, 255, 255)
    else
        love.graphics.setColor(200, 200, 200, 255)
    end
    
    local textWidth = self.font:getWidth(self.text)
    local textHeight = self.font:getHeight()
    
    love.graphics.print(self.text, self.pos.x - textWidth / 2, self.pos.y - textHeight / 2)
    
end

local function Create(font, text, pos, minWidth)

    local newText = { }
    
    newText.font = font
    newText.text = text
    newText.pos = pos
    newText.minWidth = minWidth or 0
    newText.focused = false
    newText.readOnly = false
    newText.GetExtents = GetExtents
    newText.GetText = GetText
    newText.SetText = SetText
    newText.Clear = Clear
    newText.SetReadOnly = SetReadOnly
    newText.OnFocus = OnFocus
    newText.OnBlur = OnBlur
    newText.OnKeyPressed = OnKeyPressed
    newText.Draw = Draw
    
    return newText
    
end

return { Create = Create }