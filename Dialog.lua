
local IMGUI = require("IMGUI")

local kSpaceBetweenOptions = 20

local function Create(def)

    local dialog = { }
    
    dialog.title = def.title
    dialog.body = def.body
    dialog.options = def.options
    dialog.font = def.font
    dialog.currentOption = 1
    
    function dialog:SelectNext()
        dialog.currentOption = Wrap(dialog.currentOption, 1, 1, #self.options)
    end
    
    function dialog:SelectPrevious()
        dialog.currentOption = Wrap(dialog.currentOption, -1, 1, #self.options)
    end
    
    return dialog
    
end

local function Draw(dialog)

    local screenCenter = GetScreenCenter()
    local width, height = GetScreenDims()
    
    -- Background.
    IMGUI.Rect({ pos = screenCenter, size = vec2(GetScreenDims()), color = color(0, 0, 0, 200) })
    
    -- Title area.
    local titlePos = vec2(width / 2, 100)
    local titleWidth = dialog.font:getWidth(dialog.title)
    local titleHeight = dialog.font:getHeight()
    local size = vec2(titleWidth, titleHeight)
    IMGUI.Rect({ pos = titlePos, size = size, color = color(100, 100, 100, 255), style = "fill" })
    IMGUI.Rect({ pos = titlePos, size = size, color = White, style = "line" })
    IMGUI.Text({ text = dialog.title, font = dialog.font, pos = titlePos, scale = vec2(0.75, 0.75), color = color(255, 255, 255, 255) })
    
    -- Body area.
    IMGUI.Text({ text = dialog.body, font = dialog.font, pos = GetScreenCenter(), scale = vec2(0.5, 0.5), color = color(255, 255, 255, 255) })
    
    -- Options.
    if #dialog.options > 0 then
    
        local totalOptionWidth = 0
        Iterate(dialog.options, function(option) totalOptionWidth = totalOptionWidth + dialog.font:getWidth(option) end)
        totalOptionWidth = totalOptionWidth + kSpaceBetweenOptions * (#dialog.options - 1)
        
        local remainingScreenSpace = width - totalOptionWidth
        local currentX = remainingScreenSpace / 2
        
        for o = 1, #dialog.options do
        
            local option = dialog.options[o]
            
            local optionWidth = dialog.font:getWidth(option)
            local optionHeight = dialog.font:getHeight()
            local size = vec2(optionWidth, optionHeight)
            
            local optionPos = vec2(currentX + optionWidth / 2, height - 100)
            
            local useColor = White
            local textScale = vec2(0.5, 0.5)
            if dialog.currentOption == o then
            
                size = size:Mul(1.1)
                textScale = vec2(0.6, 0.6)
                useColor = color(255, 255, 0, 255)
                
            end
            
            IMGUI.Rect({ pos = optionPos, size = size, color = color(100, 100, 100, 255), style = "fill" })
            IMGUI.Rect({ pos = optionPos, size = size, color = useColor, style = "line" })
            IMGUI.Text({ text = option, font = dialog.font, pos = optionPos, scale = textScale, color = useColor })
            
            currentX = currentX + optionWidth + kSpaceBetweenOptions
            
        end
        
    end
    
end

return { Create = Create, Draw = Draw }