
local GUIBorderMixin = { type = "GUIBorder" }

function GUIBorderMixin:Draw()

    love.graphics.setColor(255, 255, 255, 255)
    
    local topLeft, bottomRight = self:GetExtents()
    
    love.graphics.rectangle("line", topLeft.x, topLeft.y, bottomRight.x - topLeft.x, bottomRight.y - topLeft.y)
    
end

return GUIBorderMixin