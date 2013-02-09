
local GUI = require("GUI")
local GUIButton = require("GUIButton")
local GUIText = require("GUIText")
local GUIBorderMixin = require("GUIBorderMixin")
local Client = require("Client")
local Server = require("Server")
local PlayState = require("CardGamePlayState")

local QGUI = require("Quickie")

local kConnectText = "connect"
local kHostText = "host"

local kPort = 15555
local kMaxNumOfClients = 6

local function ConnectToServer(self, serverAddress)

    assert(type(serverAddress) == "string")
    
    self.client = Client.Create()
    self.connected = self.client:Connect(serverAddress, kPort)
    
end

local function Init(self)

    QGUI.group.default.size[1] = 150
    QGUI.group.default.size[2] = 25
    QGUI.group.default.spacing = 5
    
    self.gui = GUI.Create()
    local screenWidth, screenHeight = GetScreenDims()
    
    local connectButton = GUIButton.Create(self.font, kConnectText, vec2(screenWidth / 2, screenHeight / 2 - 120))
    self.gui:Add(connectButton)
    
    local connectText = GUIText.Create(self.font, "localhost", vec2(screenWidth / 2, screenHeight / 2 - 150), 10)
    InitMixin(connectText, GUIBorderMixin)
    self.gui:Add(connectText)
    
    local hostButton = GUIButton.Create(self.font, kHostText, vec2(screenWidth / 2, screenHeight / 2 + 20))
    self.gui:Add(hostButton)
    
    function connectButton.OnClick()
        ConnectToServer(self, connectText:GetText())
    end
    
    function hostButton.OnClick()
    
        self.server = Server.Create(kPort, kMaxNumOfClients)
        ConnectToServer(self, "localhost")
        
    end
    
end

local function OnKeyPressed(self, keyPressed)

    self.gui:OnKeyPressed(keyPressed)
    QGUI.keyboard.pressed(key, code)
    
end

local function OnKeyReleased(self, keyReleased)
    self.gui:OnKeyReleased(keyReleased)
end

local function Update(self, dt)

    self.gui:Update(dt)
    
    local sw, sh = GetScreenDims()
    
    QGUI.group.push{grow = "down", size = { 100, 50 }, pos = { sw / 2, sh / 2 }}
    if QGUI.Button{text = "Menu"} then
        assert(false)
    end
    QGUI.group.pop{}
    
    return self.connected and PlayState.Create(self.font, self.client, self.server) or nil
    
end

local function Draw(self)

    self.gui:Draw()
    QGUI.core.draw()
    
end

local function Create(useFont)

    local state = { }
    
    state.connected = false
    state.font = useFont
    state.OnKeyPressed = OnKeyPressed
    state.OnKeyReleased = OnKeyReleased
    state.Update = Update
    state.Draw = Draw
    Init(state)
    
    return state
    
end

return { Create = Create }