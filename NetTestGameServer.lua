
require("Utils")
require("Mixins")
require("MovableMixin")
require("SpriteMixin")

local function Init(self)

    self.udp = require("socket.udp")
    local result = self.udp:setsockname("*", 15555)
    assert(result == 1)
    
end

local function Update(self, dt)

    local data, address, port = self.udp:receivefrom()
    if data then
    
        local connection = true
        
    end
    
end

local function NetTestGameServer()

    local game = { }
    
    Init(game)
    
    game.Update = Update
    
    return game

end

return NetTestGameServer()