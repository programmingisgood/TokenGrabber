
local cachedImages = { }
local function GetCachedImage(path)

    local cachedImage = cachedImages[path]
    if not cachedImage then
    
        cachedImage = love.graphics.newImage(path)
        cachedImage:setFilter("nearest", "nearest")
        cachedImages[path] = cachedImage
        
    end
    
    return cachedImage
    
end

local function Image(settings)

    love.graphics.reset()
    
    love.graphics.setColorMode("modulate")
    if settings.color then
        love.graphics.setColor(settings.color:unpack())
    end
    
    local drawImage = GetCachedImage(settings.path)
    
    local offsetX = drawImage:getWidth() / 2
    local offsetY = drawImage:getHeight() / 2
    love.graphics.draw(drawImage, settings.pos.x, settings.pos.y, 0, settings.scale.x, settings.scale.y, offsetX, offsetY)
    
    love.graphics.reset()
    
end

local function Text(settings)

    love.graphics.reset()
    
    love.graphics.setFont(settings.font)
    love.graphics.setColor(settings.color:unpack())
    local width = settings.font:getWidth(settings.text) * settings.scale.x
    local height = settings.font:getHeight() * settings.scale.y
    love.graphics.print(settings.text, settings.pos.x - width / 2, settings.pos.y - height / 3, 0, settings.scale.x, settings.scale.y)
    
    love.graphics.reset()
    
end

local function Rect(settings)

    love.graphics.reset()
    
    local posX = settings.pos.x - settings.size.x / 2
    if settings.alignx == "min" then
        posX = settings.pos.x
    elseif settings.alignx == "max" then
        posX = settings.pos.x - settings.size.x
    end
    
    love.graphics.setColor(settings.color:unpack())
    love.graphics.rectangle(settings.style or "fill", posX, settings.pos.y - settings.size.y / 2, settings.size.x, settings.size.y)
    
    love.graphics.reset()
    
end

return { Image = Image, Text = Text, Rect = Rect }