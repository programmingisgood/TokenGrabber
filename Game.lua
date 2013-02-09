
require("Utils")

require("Mixins")

require("MovableMixin")

require("SpriteMixin")

require("JumpAroundMixin")

require("Socket")

local SimpleInput = require("SimpleInput")



local HiveLib = require("Hive")


local kArtDir = "art/"

local kImageType = ".png"



local function GetImagePath(name)

    return kArtDir .. name .. kImageType

end



local kMoveSpeed = 100



local kTestMap =

{

    2, 2, 2, 2, 2, 2, 2, 2, 2, 2,

    2, 1, 2, 1, 2, 2, 1, 2, 1, 2,

    2, 2, 2, 2, 2, 2, 2, 2, 2, 2,

    2, 1, 2, 2, 1, 1, 2, 2, 1, 2,

    2, 2, 2, 1, 1, 1, 1, 2, 2, 2,

    2, 2, 2, 1, 1, 1, 1, 2, 2, 2,

    2, 1, 2, 2, 1, 1, 2, 2, 1, 2,

    2, 2, 2, 2, 2, 2, 2, 2, 2, 2,

    2, 1, 2, 1, 2, 2, 1, 2, 1, 2,

    2, 2, 2, 2, 2, 2, 2, 2, 2, 2

}



local kMapRows = 10

local kMapCols = 10

local kMapImageTileWidth = 32

local kMapImageTileHeight = 32

local kMapTileWidth = 64

local kMapTileHeight = 64



-- How much spacing between bugs on the select screen.

local kBugSpacing = 10



local kBugSelectorSpeed = 0.25

local kFont = love.graphics.newFont("art/press-start-2p/PressStart2P.ttf", 24)



local kBugTypes = { }

table.insert(kBugTypes, "ant")

table.insert(kBugTypes, "roly_poly")

table.insert(kBugTypes, "lady_bug")

table.insert(kBugTypes, "scorpion")



-- Base set of animations for all bugs.

local kIdleAnim = { { frame = 1, time = -1 } }

local kMoveAnim = { { frame = 2, time = 0.1 }, { frame = 3, time = 0.1 } }

local kActionAnim = { { frame = 4, time = 0.2} }



local function InitBugAnimations(bug)



    bug:AddAnimation("idle", kIdleAnim)

    bug:AddAnimation("move", kMoveAnim)

    bug:AddAnimation("action", kActionAnim)

    

end



local kBugDefs = { }

kBugDefs["ant"] = { SeekFoodMixin }

kBugDefs["roly_poly"] = {  }

kBugDefs["lady_bug"] = {  }

kBugDefs["scorpion"] = {  }



local function CreateBug(bugType)



    local newBug = { }

    InitMixin(newBug, MovableMixin)

    

    InitMixin(newBug, SpriteMixin)

    newBug:SetImage(GetImagePath(bugType), 4, 4)

    newBug:SetScale(vec2(2, 2))

    InitBugAnimations(newBug)

    

    for m = 1, #kBugDefs[bugType] do

        InitMixin(newBug, kBugDefs[bugType][m])

    end

    

    return newBug

    

end



local function CreateMap(self)



    local mapImage = love.graphics.newImage("art/bug_tiles.png")

    mapImage:setFilter("nearest", "nearest")

    self.map = love.graphics.newSpriteBatch(mapImage, #kTestMap)

    for i = 1, #kTestMap do

    

        local quadX = ((kTestMap[i] - 1) % kMapCols) * kMapImageTileWidth

        local quadY = math.modf(((kTestMap[i] - 1) / kMapRows)) * kMapImageTileHeight

        local quad = love.graphics.newQuad(quadX, quadY, kMapImageTileWidth, kMapImageTileHeight, mapImage:getWidth(), mapImage:getHeight())

        self.map:addq(quad, math.modf((i - 1) % kMapCols) * kMapTileWidth, math.modf((i - 1) / kMapRows) * kMapTileHeight, 0, 2, 2)

        

    end

    

end


local function Init(self)



    --CreateMap(self)

    

    self.selectBugs = true

    

    self.selectScreenBugs = { }

    for _, bugType in pairs(kBugTypes) do

    

        local bug = { }

        InitMixin(bug, MovableMixin)

        InitMixin(bug, SpriteMixin)

        bug:SetImage(GetImagePath(bugType), 4, 4)

        bug:SetScale(vec2(4, 4))

        

        InitBugAnimations(bug)

        

        table.insert(self.selectScreenBugs, bug)

        

    end

    

    self.aphids = { }

    

    self.players = { }

    table.insert(self.players, { color = color(255, 0, 0, 255), bugIndex = 1, bug = nil, input = SimpleInput.Create(1), spawnZone = 0.25 })

    table.insert(self.players, { color = color(0, 0, 255, 255), bugIndex = 2, bug = nil, input = SimpleInput.Create(2), spawnZone = 0.75 })

    

    self.allPlayerControlsDetected = false
    
end



local function CreateAphid()



    local newAphid = { }

    InitMixin(newAphid, MovableMixin)

    

    InitMixin(newAphid, SpriteMixin)

    newAphid:SetImage(GetImagePath("aphid"), 1, 2)

    

    InitMixin(newAphid, JumpAroundMixin)

    function newAphid:OnJump()

        self:SetAnimation("jump")

    end

    

    newAphid:AddAnimation("idle", { { frame = 1, time = 0 } })

    newAphid:AddAnimation("jump", { { frame = 2, time = 0.3, callback = function() newAphid:SetAnimation("idle") end } })

    

    newAphid:SetAnimation("idle")

    

    return newAphid

    

end



local function OnGameStart(self)



    local screenW, screenH = GetScreenDims()

    

    for a = 1, 10 do

    

        local aphid = CreateAphid()

        aphid:SetPosition(vec2(screenW / 2, screenH / 2))

        table.insert(self.aphids, aphid)

        

    end

    

    self.hive1 = HiveLib.CreateHive()

    self.hive1:SetPosition(vec2(screenW / 2, 60))

    

    self.hive2 = HiveLib.CreateHive()

    self.hive2:SetPosition(vec2(screenW / 2, screenH - 60))

    

end


local function UpdateSelectScreen(self, dt)



    for i = 1, #self.selectScreenBugs do

        self.selectScreenBugs[i]:Update(dt)

    end

    

    local allPlayersSelected = true

    for i, player in ipairs(self.players) do

    

        if not player.bug then

        

            allPlayersSelected = false

            

            player.lastSelectTime = player.lastSelectTime or kBugSelectorSpeed

            

            local selectDir = player.input:GetInputState("X")

            local newBugIndex = player.bugIndex

            if selectDir < -0.5 then

                newBugIndex = player.bugIndex - 1

            elseif selectDir > 0.5 then

                newBugIndex = player.bugIndex + 1

            end

            

            newBugIndex = Clamp(newBugIndex, 1, #self.selectScreenBugs)

            if newBugIndex ~= player.bugIndex and player.lastSelectTime >= kBugSelectorSpeed then

            

                player.bugIndex = newBugIndex

                player.lastSelectTime = 0

                

            else

                player.lastSelectTime = player.lastSelectTime + dt

            end

            

        end

        

        if not player.bug and player.input:GetInputState("A") >= 0.5 then

        

            local screenW, screenH = GetScreenDims()

            player.bug = CreateBug(kBugTypes[player.bugIndex])

            player.bug:SetPosition(vec2(screenW * player.spawnZone, screenH / 2))

            

        end

        

    end

    

    -- Check if we should switch to game mode.

    if allPlayersSelected then

    

        self.selectBugs = false

        OnGameStart(self)

        

    end

    

end



local function UpdateGameScreen(self, dt)



    for a = 1, #self.aphids do

        self.aphids[a]:Update(dt)

    end

    

    for p = 1, #self.players do

    

        local player = self.players[p]

        local controls = vec2(0, 0)
        controls.x = player.input:GetInputState("X")
        controls.y = player.input:GetInputState("Y")

        

        controls.x = math.abs(controls.x) < 0.2 and 0 or controls.x

        controls.y = math.abs(controls.y) < 0.2 and 0 or controls.y

        
        local moving = math.abs(controls.x) > 0 or math.abs(controls.y) > 0

        

        if moving then

            player.bug:SetRotation(controls:ToAngle())

        end

        
        player.bug:SetPosition(player.bug:GetPosition():Add(controls:Mul(dt * kMoveSpeed)))

        

        player.bug:Update(dt)

        

    end

    

end


local function Update(self, dt)


    if self.selectBugs then

        UpdateSelectScreen(self, dt)

    else

        UpdateGameScreen(self, dt)

    end
    
end


local function DrawSelectScreen(self)



    local screenW, screenH = GetScreenDims()

    

    love.graphics.setColorMode("replace")

    love.graphics.setColor(0, 0, 0, 180)

    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    

    love.graphics.setFont(kFont)
    love.graphics.printf("SELECT", screenW / 2, screenH / 6, 0, "center")

    

    love.graphics.push()

    

    local bugWidth = self.selectScreenBugs[1]:GetWidth()

    local bugHeight = self.selectScreenBugs[1]:GetHeight()

    local numBugs = #self.selectScreenBugs - 1

    love.graphics.translate((screenW / 2) - (((numBugs * bugWidth) + (numBugs * kBugSpacing)) / 2), screenH / 2)

    

    for i, bug in ipairs(self.selectScreenBugs) do

    

        local backgroundW = bugWidth + 4

        local backgroundH = bugHeight + 4

        love.graphics.setColor(255, 255, 255, 140)

        love.graphics.rectangle("fill", -backgroundW / 2, -backgroundH / 2, backgroundW, backgroundH)

        

        local bugSelected = false

        

        for _, player in pairs(self.players) do

        

            if i == player.bugIndex then

            

                love.graphics.setColor(player.color:unpack())

                love.graphics.setLineWidth(4)

                drawMode = "line"

                if player.bug ~= nil then

                

                    drawMode = "fill"

                    bug:SetAnimation("action")

                    

                else

                    bug:SetAnimation("move")

                end

                love.graphics.rectangle(drawMode, -backgroundW / 2, -backgroundH / 2, backgroundW, backgroundH)

                bugSelected = true

                break

                

            end

            

        end

        

        if not bugSelected then

            bug:SetAnimation("idle")

        end

        

        bug:Draw()

        

        love.graphics.translate(bugWidth + kBugSpacing, 0)

        

    end

    

    love.graphics.pop()

    

end



local function DrawGameScreen(self)



    self.hive1:Draw()

    self.hive2:Draw()

    

    for a = 1, #self.aphids do

        self.aphids[a]:Draw()

    end

    

    for p = 1, #self.players do

        self.players[p].bug:Draw()

    end

    

end


local function Draw(self)


    love.graphics.setBackgroundColor(176, 176, 176)

    love.graphics.clear()

    

    if self.map then

        love.graphics.draw(self.map, 0, 0)

    end

    

    if self.selectBugs then

        DrawSelectScreen(self)

    else

        DrawGameScreen(self)
    end
    
end

local function Game()

    local game = { }
    
    Init(game)
    
    game.Update = Update
    game.Draw = Draw
    
    return game

end

return Game()