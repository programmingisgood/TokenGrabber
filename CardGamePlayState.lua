
local GUI = require("GUI")
local GUIButton = require("GUIButton")
local GUIText = require("GUIText")
local GUIBorderMixin = require("GUIBorderMixin")
local Deck = require("Deck")

local function Init(self)

    self.gui = GUI.Create()
    local screenWidth, screenHeight = GetScreenDims()
    
    self.chatInput = GUIText.Create(self.font, "Chat", vec2(screenWidth / 2, screenHeight / 2 + 150), 10)
    InitMixin(self.chatInput, GUIBorderMixin)
    self.gui:Add(self.chatInput)
    
    self.chatOutput = GUIText.Create(self.font, "", vec2(screenWidth / 2, screenHeight / 2 + 250), 10)
    self.chatOutput:SetReadOnly(true)
    self.gui:Add(self.chatOutput)
    
    self.client:SetMessageCallback("chat", function(message) self.chatOutput:SetText(message) end)
    self.client:SetMessageCallback("card", function(message) self.chatOutput:SetText("Got Card: " .. message) end)
    
    if self.server then
    
        self.clients = { }
        self.server:SetClientCallbacks(function(c) table.insert(self.clients, c) end,
                                       function(c) RemoveValue(self.clients, c) end)
        
        local moneyCards = { }
        for p = 1, 5 do
        
            for m = 1, 10 do
                table.insert(moneyCards, "$" .. m .. " p" .. p)
            end
            
        end
        self.moneyDeck = Deck.Create(moneyCards)
        
        local function OnChatReceived(client, message)
        
            if string.lower(message) == "ready" then
                client.ready = true
            else
                self.server:SendAll("chat", message)
            end
            
        end
        self.server:SetMessageCallback("chat", OnChatReceived)
        
        self.serverGameState = "waiting"
        
    end
    
end

local function OnKeyPressed(self, keyPressed)

    if keyPressed == "return" then
    
        local text = self.chatInput:GetText()
        self.chatInput:Clear()
        self.client:Send("chat", text)
        
    end
    
    self.gui:OnKeyPressed(keyPressed)
    
end

local function OnKeyReleased(self, keyReleased)
    self.gui:OnKeyReleased(keyReleased)
end

local function UpdateServerLogic(self, dt)

    if self.serverGameState == "waiting" then
    
        if #self.clients > 0 then
        
            local allReady = true
            for c = 1, #self.clients do
            
                if not self.clients[c].ready then
                
                    allReady = false
                    break
                    
                end
                
            end
            
            if allReady then
                self.serverGameState = "deal"
            end
            
        end
        
    elseif self.serverGameState == "deal" then
    
        for c = 1, #self.clients do
        
            local card = self.moneyDeck:Deal(1)
            self.server:Send(self.clients[c], "card", card[1])
            self.clients[c].ready = false
            
        end
        
        self.serverGameState = "waiting"
        
    end
    
end

local function Update(self, dt)

    self.gui:Update(dt)
    
    self.client:Update()
    
    if self.server then
    
        UpdateServerLogic(self, dt)
        self.server:Update()
        
    end
    
    return nil
    
end

local function Draw(self)
    self.gui:Draw()
end

local function Create(useFont, client, server)

    local state = { }
    
    state.font = useFont
    state.client = client
    state.server = server
    state.OnKeyPressed = OnKeyPressed
    state.OnKeyReleased = OnKeyReleased
    state.Update = Update
    state.Draw = Draw
    Init(state)
    
    return state
    
end

return { Create = Create }