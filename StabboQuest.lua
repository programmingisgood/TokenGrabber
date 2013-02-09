
local Dialog = require("Dialog")

local kQuestOptions = { "Accept", "Decline" }
local kQuests = { }
table.insert(kQuests, { title = "I want coins.", body = "Get me 5 coins.\nI will give you 4 coins in exchange.", options = kQuestOptions })

local function Create(world, atPos, font)

    local questGiver = { }
    
    questGiver.quest = kQuests[math.random(#kQuests)]
    questGiver.quest.font = font
    
    function questGiver:OnUseBegin()
    
        local dialog = Dialog.Create(self.quest)
        world:Add(dialog, { "Dialog" })
        
    end
    
    InitMixin(questGiver, MovableMixin)
    InitMixin(questGiver, SpriteMixin)
    InitMixin(questGiver, UsableMixin, 0, 0, kRobDistance)
    
    questGiver:SetImage("art/Stabbo/Villager" .. math.random(1, 2) .. ".png", 1, 1)
    questGiver:SetScale(vec2(2, 2))
    questGiver:SetPosition(atPos)
    
    local questIcon = { }
    InitMixin(questIcon, MovableMixin)
    InitMixin(questIcon, SpriteMixin)
    questIcon:SetImage("art/Stabbo/Quest.png", 1, 4)
    local idleAnim = { { frame = 1, time = 0.1 },
                       { frame = 2, time = 0.1 },
                       { frame = 3, time = 0.1 },
                       { frame = 4, time = 0.2 },
                       { frame = 3, time = 0.1 },
                       { frame = 2, time = 0.1 } }
    questIcon:AddAnimation("idle", idleAnim)
    questIcon:SetAnimation("idle")
    questIcon:SetPosition(atPos:Sub(vec2(0, questGiver:GetHeight())))
    questGiver.icon = questIcon
    
    world:Add(questGiver, { "Draws", "Updates", "QuestGiver" })
    world:Add(questIcon, { "Draws2", "Updates", "QuestIcon" })
    
    return questGiver
    
end

return { Create = Create }