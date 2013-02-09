
require("MovableMixin")
require("SpriteMixin")

local hiveLib = { }

local hiveMeta = { }

hiveMeta.__index = function(t, key) return hiveMeta[key] end

function hiveMeta:Draw()

    love.graphics.push()
    
    local pos = self:GetPosition()
    love.graphics.translate(pos.x, pos.y)
    
    for s = 1, #self.sections do
        self.sections[s]:Draw()
    end
    
    love.graphics.pop()
    
end

local function AddSection(self)

    local section = { }
    InitMixin(section, MovableMixin)
    InitMixin(section, SpriteMixin)
    
    section:SetImage("art/hive_block.png", 1, 1)
    section:SetColor(color(255, 255, 0, 255))
    
    local numSections = #self.sections
    local row = math.modf(numSections / 3)
    local col = numSections % 3
    section:SetPosition(vec2(col * section:GetWidth(), row * section:GetHeight()))
    
    table.insert(self.sections, section)
    
end

function hiveLib.CreateHive()

    local newHive = { }
    InitMixin(newHive, MovableMixin)
    
    setmetatable(newHive, hiveMeta)
    
    newHive.sections = { }
    
    for s = 1, 9 do
        AddSection(newHive)
    end
    
    return newHive
    
end

return hiveLib