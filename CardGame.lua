
require("Utils")
require("Mixins")
require("MovableMixin")
require("SpriteMixin")

local MenuState = require("CardGameMenuState")

local kArtDir = "art/"
local kImageType = ".png"

local function GetImagePath(name)
    return kArtDir .. name .. kImageType
end

local kFont = love.graphics.newFont("art/press-start-2p/PressStart2P.ttf", 24)

local function SetGameState(self, state)
    self.gameState = state
end

local function OnGameStart(self)
    SetGameState(self, MenuState.Create(kFont))
end

local function OnKeyPressed(self, keyPressed)

    if self.gameState.OnKeyPressed then
        self.gameState:OnKeyPressed(keyPressed)
    end
    
end

local function OnKeyReleased(self, keyReleased)

    if self.gameState.OnKeyReleased then
        self.gameState:OnKeyReleased(keyReleased)
    end
    
end

local function Update(self, dt)

    local changeState = self.gameState:Update(dt)
    if changeState then
        SetGameState(self, changeState)
    end
    
end

local function Draw(self)
    self.gameState:Draw()
end

local function Init(self)
    OnGameStart(self)
end

local function CardGame()

    local game = { }
    
    Init(game)
    
    game.OnKeyPressed = OnKeyPressed
    game.OnKeyReleased = OnKeyReleased
    game.Update = Update
    game.Draw = Draw
    
    return game
    
end

return CardGame()