
local socket = require("socket")

local function Connect(self, address, port)

    local result, err = self.clientSocket:connect(address, port)
    return result, err
    
end

local function Update(self)

    local message, err = self.clientSocket:receive()
    if err == "closed" then
    
        self.clientSocket:close()
        assert(false, err)
        
    elseif err == nil then
    
        local messageTypePos = string.find(message, " ")
        local messageType = string.sub(message, 1, messageTypePos - 1)
        local callback = self.messageCallbacks[messageType]
        if callback then
        
            local messageBody = string.sub(message, messageTypePos + 1)
            callback(messageBody)
            
        end
        
    end
    
end

local function SetMessageCallback(self, messageType, callback)

    assert(type(messageType) == "string")
    assert(type(callback) == "function")
    
    self.messageCallbacks[messageType] = callback
    
end

local function Send(self, messageType, messageBody)

    assert(type(messageType) == "string")
    assert(type(messageBody) == "string")
    
    self.clientSocket:send(messageType .. " " .. messageBody .. "\n")
    
end

local function Create()

    local client = { }
    
    client.clientSocket = socket.tcp()
    client.clientSocket:settimeout(0.001)
    client.messageCallbacks = { }
    client.Connect = Connect
    client.Update = Update
    client.SetMessageCallback = SetMessageCallback
    client.Send = Send
    
    return client
    
end

return { Create = Create }