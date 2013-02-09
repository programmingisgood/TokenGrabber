
local SimpleInput = require("SimpleInput")
local Camera = require("Camera")
local World = require("World")
local IMGUI = require("IMGUI")
local Sound = require("Sound")

require("DebugDrawer")
require("PhysicsMixin")

local kWorldWidth = 1280
local kWorldHeight = 720

local kPlayerMass = 10
local kPlayerMovingDamping = 1
local kPlayerStandingDamping = 5
local kMaxSpeed = 230
local kMoveForce = 100000
local kMoveForce2 = 256

local kCollisionCategories = { }
kCollisionCategories.player = 1

local function RandomPointInWorld()
    return vec2(RandomFloatBetween(100, kWorldWidth - 100), RandomFloatBetween(100, kWorldHeight - 100))
end

local function InitWorldBounds(physicsWorld)

    local leftBody = love.physics.newBody(physicsWorld)
    local leftShape = love.physics.newEdgeShape(0, 0, 0, kWorldHeight)
    love.physics.newFixture(leftBody, leftShape)
    
    local rightBody = love.physics.newBody(physicsWorld)
    local rightShape = love.physics.newEdgeShape(kWorldWidth, 0, kWorldWidth, kWorldHeight)
    love.physics.newFixture(rightBody, rightShape)
    
    local topBody = love.physics.newBody(physicsWorld)
    local topShape = love.physics.newEdgeShape(0, 0, kWorldWidth, 0)
    love.physics.newFixture(topBody, topShape)
    
    local bottomBody = love.physics.newBody(physicsWorld)
    local bottomShape = love.physics.newEdgeShape(0, kWorldHeight, kWorldWidth, kWorldHeight)
    love.physics.newFixture(bottomBody, bottomShape)
    
end

local function CreateBackground(staticBackground)

    staticBackground:renderTo(
    function()

        -- White background.
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.rectangle("fill", 0, 0, kWorldWidth, kWorldHeight)

        love.graphics.setLineStyle("smooth")
        love.graphics.setLineWidth(8)

        -- Middle circle.
        love.graphics.setColor(0, 0, 255, 255)
        love.graphics.circle("line", kWorldWidth / 2, kWorldHeight / 2, kWorldWidth / 4, 128)

        -- Middle line.
        love.graphics.setColor(255, 0, 0, 255)
        love.graphics.line(0, kWorldHeight / 2, kWorldWidth, kWorldHeight / 2)

    end)

end

local function InitPlayerAnimations(player)

    local animations = { }
    animations["idle_up"] = { { frame = 1, time = 0 } }
    animations["idle_down"] = { { frame = 6, time = 0 } }
    animations["skate_up_sr"] = { { frame = 2, time = 0.2 }, { frame = 3, time = 0.2 } }
    animations["skate_up_sl"] = { { frame = 4, time = 0.2 }, { frame = 5, time = 0.2 } }
    animations["skate_down_sr"] = { { frame = 9, time = 0.2 }, { frame = 10, time = 0.2 } }
    animations["skate_down_sl"] = { { frame = 7, time = 0.2 }, { frame = 8, time = 0.2 } }

    for name, anim in pairs(animations) do
        player:AddAnimation(name, anim)
    end

end

local function Init(self)

    math.randomseed(os.time())
    
    self.world = World.Create()
    self.physicsWorld = love.physics.newWorld(0, 0, true)
    
    InitWorldBounds(self.physicsWorld)
    
    local spawnPoints = { }
    table.insert(spawnPoints, vec2(kWorldWidth / 2 - 100, kWorldHeight / 2 - 100))
    table.insert(spawnPoints, vec2(kWorldWidth / 2 + 100, kWorldHeight / 2 - 100))
    table.insert(spawnPoints, vec2(kWorldWidth / 2 - 100, kWorldHeight / 2 + 100))
    table.insert(spawnPoints, vec2(kWorldWidth / 2 + 100, kWorldHeight / 2 + 100))
    
    self.players = { }
    for p = 1, 4 do
    
        local player = { }
        InitMixin(player, MovableMixin)
        InitMixin(player, SpriteMixin)
        
        player:SetImage("art/SuperHockey/HockeyPlayer.png", 3, 5)
        player:SetScale(vec2(2, 2))
        player:SetPosition(spawnPoints[p])

        InitPlayerAnimations(player)
        player:SetAnimation("idle_up")

        player.input = SimpleInput.Create(p)
        
        InitMixin(player, PhysicsMixin)
        
        player:SetupPhysics(self.physicsWorld, kPlayerMass, 0, love.physics.newRectangleShape(player:GetWidth(), player:GetHeight()))
        player:SetCollisionCategory(kCollisionCategories.player)
        --player:SetCollisionMask(kCollisionCategories.coin)
        player:SetLinearDamping(kPlayerStandingDamping)
        player:SetMaxSpeed(kMaxSpeed)
        
        self.world:Add(player, { "Draws" })
        
        table.insert(self.players, player)
        
    end
    
    self.staticBackground = love.graphics.newCanvas(kWorldWidth, kWorldHeight)
    
    CreateBackground(self.staticBackground)
    
    self.camera = Camera.Create()
    self.camera:SetWorldExtents(kWorldWidth, kWorldHeight)
    
end

local function OnKeyPressed(self, keyPressed)

    if keyPressed == "escape" then
    
        
        
    end
    
end

local function OnKeyReleased(self, keyReleased)
end

local function UpdatePlayerAnimation(player, moving, controls)

    local animType = moving and "skate" or "idle"
    if math.abs(controls.y) >= 0.1 then
        player.animDir = controls.y < 0 and "up" or "down"
    end

    if player.animDir then

        local animName = animType .. "_" .. player.animDir
        if moving then
            animName = animName .. (controls.x < 0 and "_sl" or "_sr")
        end
        if player:GetAnimation() ~= animName then
            player:SetAnimation(animName)
        end

    end

end

local function ClampInput(controls)

    controls.x = math.abs(controls.x) < 0.2 and 0 or controls.x
    controls.y = math.abs(controls.y) < 0.2 and 0 or controls.y
    return controls

end

local function UpdateMovement(player, dt)

    local controls = vec2(0, 0)
    controls.x = player.input:GetInputState("X")
    controls.y = player.input:GetInputState("Y")
    controls = ClampInput(controls)

    local moving = math.abs(controls.x) > 0 or math.abs(controls.y) > 0

    UpdatePlayerAnimation(player, moving, controls)

    if moving then
    
        --player:SetPosition(player:GetPosition():Add(controls:Mul(dt * kMoveForce2)))
        player:ApplyForce(controls:Mul(dt * kMoveForce))
        player:SetLinearDamping(kPlayerMovingDamping)
        
    else
        player:SetLinearDamping(kPlayerStandingDamping)
    end
    
end

local function Update(self, dt)

    self.world:IterateTag("Updates", function(object) object:Update(dt) end)
    
    for p = 1, #self.players do
    
        local player = self.players[p]
        UpdateMovement(player, dt)

        player:Update(dt)
        
    end
    
    self.physicsWorld:update(dt)
    
end

local function DrawWorld(self)
    love.graphics.draw(self.staticBackground)
end

local function WorldDrawerSorter(a, b)
    return a:GetPosition().y < b:GetPosition().y
end

local function DrawStats(self)

    DebugDrawer.DrawText(tostring(love.timer.getFPS()), vec2(10, 10), 0, color(0, 255, 0), "screen")
    self.lastTimeTimeDrawn = self.lastTimeTimeDrawn or 0
    if love.timer.getTime() - self.lastTimeTimeDrawn > 1 then
    
        DebugDrawer.DrawText(tostring(love.timer.getDelta()), vec2(10, 30), 1, color(0, 255, 0), "screen")
        self.lastTimeTimeDrawn = love.timer.getTime()
        
    end
    
end

local function Draw(self)

    love.graphics.setColor(255, 255, 255, 255)

    love.graphics.push()
    
    self.camera:Draw()
    
    DrawWorld(self)
    
    local worldDrawers = self.world:CollectAllWithTag("Draws")
    table.sort(worldDrawers, WorldDrawerSorter)
    Iterate(worldDrawers, function(object) object:Draw() end)
    
    worldDrawers = self.world:CollectAllWithTag("Draws2")
    table.sort(worldDrawers, WorldDrawerSorter)
    Iterate(worldDrawers, function(object) object:Draw() end)

    DrawStats(self)
    
    DebugDrawer.Draw("world")

    love.graphics.pop()

    DebugDrawer.Draw("screen")

end

local function Create(useFont, client, server)

    local state = { }
    
    state.font = useFont
    state.OnKeyPressed = OnKeyPressed
    state.OnKeyReleased = OnKeyReleased
    state.Update = Update
    state.Draw = Draw
    state.GetBlocksEscape = function() return false end
    Init(state)
    
    return state
    
end

return { Create = Create }