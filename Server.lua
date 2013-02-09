
local socket = require("socket")

local function Update(self)

    local newClient = self.serverSocket:accept()
    if newClient then
    
        newClient:settimeout(0.001)
        local clientTable = { c = newClient }
        table.insert(self.clients, clientTable)
        if self.clientConnectedCallback then
            self.clientConnectedCallback(clientTable)
        end
        
    end
    
    for c = #self.clients, 1, -1 do
    
        local client = self.clients[c]
        local message, err = client.c:receive()
        if err == "closed" then
        
            client.c:close()
            RemoveValue(self.clients, client)
            if self.clientDisconnectedCallback then
                self.clientDisconnectedCallback(client)
            end
            
        elseif err == nil then
        
            local messageTypePos = string.find(message, " ")
            local messageType = string.sub(message, 1, messageTypePos - 1)
            local callback = self.messageCallbacks[messageType]
            if callback then
            
                local messageBody = string.sub(message, messageTypePos + 1)
                callback(client, messageBody)
                
            end
            
        end
        
    end
    
end

local function SetMessageCallback(self, messageType, callback)

    assert(type(messageType) == "string")
    assert(type(callback) == "function")
    
    self.messageCallbacks[messageType] = callback
    
end

local function SetClientCallbacks(self, connectedCallback, disconnectedCallback)

    assert(type(connectedCallback) == "function")
    assert(type(disconnectedCallback) == "function")
    
    self.clientConnectedCallback = connectedCallback
    self.clientDisconnectedCallback = disconnectedCallback
    
end

local function SendAll(self, messageType, messageBody)

    assert(type(messageType) == "string")
    assert(type(messageBody) == "string")
    
    for c = 1, #self.clients do
        self.clients[c].c:send(messageType .. " " .. messageBody .. "\n")
    end
    
end

local function Send(self, client, messageType, messageBody)

    assert(type(messageType) == "string")
    assert(type(messageBody) == "string")
    
    client.c:send(messageType .. " " .. messageBody .. "\n")
    
end

local function Create(listenPort, maxNumOfClients)

    local server = { }
    assert(type(listenPort) == "number")
    assert(type(maxNumOfClients) == "number")
    
    server.listenPort = listenPort
    server.maxNumOfClients = maxNumOfClients
    server.clients = { }
    server.messageCallbacks = { }
    
    server.serverSocket = socket.bind("*", server.listenPort, server.maxNumOfClients)
    server.serverSocket:settimeout(0.001)
    
    server.Update = Update
    server.SetMessageCallback = SetMessageCallback
    server.SetClientCallbacks = SetClientCallbacks
    server.SendAll = SendAll
    server.Send = Send
    
    return server
    
end

return { Create = Create }