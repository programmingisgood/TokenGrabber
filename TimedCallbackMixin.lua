
TimedCallbackMixin = { type = "TimedCallback" }

function TimedCallbackMixin:__initmixin()
    self.timedCallbacks = { }
end

function TimedCallbackMixin:AddTimedCallback(addFunction, callRate)
    table.insert(self.timedCallbacks, { Function = addFunction, Rate = callRate, Time = 0 })
end

local function RemoveCallbacks(self, removeCallbacks)

    for _, removeCallback in ipairs(removeCallbacks) do
    
        for index, timedCallback in ipairs(self.timedCallbacks) do
        
            if timedCallback == removeCallback then
                table.remove(self.timedCallbacks, index)
            end
            
        end
        
    end
    
end

function TimedCallbackMixin:Update(dt)

    local removeCallbacks = { }
    for index, callback in ipairs(self.timedCallbacks) do
    
        callback.Time = callback.Time + dt
        local numberOfIterations = 0
        while callback.Time >= callback.Rate and numberOfIterations < 3 do
        
            callback.Time = callback.Time - callback.Rate
            local continueCallback = callback.Function(self, callback.Rate)
            
            if continueCallback == false then
            
                table.insert(removeCallbacks, callback)
                break
                
            end
            numberOfIterations = numberOfIterations + 1
            
        end
        
    end
    
    RemoveCallbacks(self, removeCallbacks)
    
end