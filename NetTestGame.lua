
require("Utils")
require("Mixins")
require("MovableMixin")
require("SpriteMixin")
require("Socket")

local function Init(self)
end

local function Update(self, dt)
end

local function Draw(self)

    love.graphics.setBackgroundColor(176, 176, 176)
    love.graphics.clear()
    
end

local function NetTestGame()

    local game = { }
    
    Init(game)
    
    game.Update = Update
    game.Draw = Draw
    
    return game

end

return NetTestGame()