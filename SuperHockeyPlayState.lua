
local SimpleInput = require("SimpleInput")
local Camera = require("Camera")
local World = require("World")
local IMGUI = require("IMGUI")
local Sound = require("Sound")

require("DebugDrawer")
require("PhysicsMixin")

local kWorldWidth = 800
local kWorldHeight = 1600

local kPlayerMass = 1
local kMovingDamping = 0.05
local kStandingDamping = 1
local kMaxSpeed = 230
local kMoveForce = 90000

local kNetMass = 10

local kPuckMass = 0.002

local kCollisionCategories = { }
kCollisionCategories.player = 1
kCollisionCategories.net = 2
kCollisionCategories.puck = 3

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

local function CreateNet(world, physicsWorld, atPos)

    local net = { }
    InitMixin(net, MovableMixin)
    InitMixin(net, SpriteMixin)
    
    net:SetImage("art/SuperHockey/Goal.png", 1, 2)
    net:SetScale(vec2(2, 2))
    net:SetPosition(atPos)

    InitMixin(net, PhysicsMixin)
    
    net:SetupPhysics(physicsWorld, kNetMass, 0, love.physics.newRectangleShape(net:GetWidth(), net:GetHeight()))
    net:SetCollisionCategory(kCollisionCategories.net)
    net:SetLinearDamping(2)
    net:SetMaxSpeed(10)
    
    world:Add(net, { "Draws", "Updates" })

end

local function CreatePuck(world, physicsWorld, atPos)

    local puck = { }
    InitMixin(puck, MovableMixin)
    InitMixin(puck, SpriteMixin)

    puck:SetImage("art/SuperHockey/Puck.png", 1, 1)
    puck:SetScale(vec2(2, 2))
    puck:SetPosition(atPos)

    InitMixin(puck, PhysicsMixin)

    puck:SetupPhysics(physicsWorld, kPuckMass, 0, love.physics.newCircleShape(puck:GetWidth()))
    puck:SetCollisionCategory(kCollisionCategories.puck)
    puck:SetLinearDamping(0.005)
    puck:SetMaxSpeed(300)

    world:Add(puck, { "Draws", "Updates" })

end

local function Init(self)

    math.randomseed(os.time())
    
    self.world = World.Create()
    self.physicsWorld = love.physics.newWorld(0, 0, true)
    
    InitWorldBounds(self.physicsWorld)
    
    local spawnPoint = vec2(kWorldWidth / 2, kWorldHeight / 2)
    
    self.player = { }
    InitMixin(self.player, MovableMixin)
    InitMixin(self.player, SpriteMixin)
    
    self.player:SetImage("art/SuperHockey/HockeyPlayer.png", 3, 5)
    self.player:SetScale(vec2(2, 2))
    self.player:SetPosition(spawnPoint)

    InitPlayerAnimations(self.player)
    self.player:SetAnimation("idle_up")

    self.player.input = SimpleInput.Create(1)
    
    InitMixin(self.player, PhysicsMixin)
    
    self.player:SetupPhysics(self.physicsWorld, kPlayerMass, 0, love.physics.newRectangleShape(self.player:GetWidth(), self.player:GetHeight()))
    self.player:SetCollisionCategory(kCollisionCategories.player)
    --self.player:SetCollisionMask(kCollisionCategories.coin)
    self.player:SetLinearDamping(kStandingDamping)
    self.player:SetMaxSpeed(kMaxSpeed)
    
    self.world:Add(self.player, { "Draws" })
    
    CreateNet(self.world, self.physicsWorld, vec2(kWorldWidth / 2, 100))

    CreatePuck(self.world, self.physicsWorld, vec2(kWorldWidth / 2, kWorldHeight / 2 + 100))

    self.staticBackground = love.graphics.newCanvas(kWorldWidth, kWorldHeight)
    
    CreateBackground(self.staticBackground)
    
    self.camera = Camera.Create()
    self.camera:SetWorldExtents(kWorldWidth, kWorldHeight)
    self.camera:SetFocusObject(self.player)
    
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

local kMaxSkateMarkStrength = 200
local function UpdateSkateMarks(staticBackground, player, dt)

    local playerVel = player:GetLinearVelocity()
    player.skateMarkVel = player.skateMarkVel or playerVel

    local markStrength = playerVel:Sub(player.skateMarkVel):Length()
    player.skateMarkVel = player.skateMarkVel:Add(playerVel:Sub(player.skateMarkVel):Mul(0.99 * dt))

    markStrength = math.min(markStrength, kMaxSkateMarkStrength)
    local markStrengthPercent = (markStrength / kMaxSkateMarkStrength)

    if markStrength >= kMaxSkateMarkStrength / 2 then

        staticBackground:renderTo(
        function()

            love.graphics.setColor(250, 250, 250, 10 * markStrengthPercent)
            love.graphics.setLineStyle("smooth")
            love.graphics.setLineWidth(2)

            local pos = player:GetPosition():Add(vec2(8, player:GetHeight() / 2))
            local lastPos = pos:Sub(player:GetLinearVelocity():Mul(dt))

            love.graphics.line(pos.x, pos.y, lastPos.x, lastPos.y)

            pos = player:GetPosition():Add(vec2(-8, player:GetHeight() / 2))
            lastPos = pos:Sub(player:GetLinearVelocity():Mul(dt))
            
            love.graphics.line(pos.x, pos.y, lastPos.x, lastPos.y)

        end)

    end

end

local function UpdateMovement(player, dt)

    local controls = vec2(0, 0)
    controls.x = player.input:GetInputState("X")
    controls.y = player.input:GetInputState("Y")
    controls = ClampInput(controls)

    local moving = math.abs(controls.x) > 0 or math.abs(controls.y) > 0

    UpdatePlayerAnimation(player, moving, controls)

    if moving then
    
        player:SetLinearDamping(kMovingDamping)
        player:ApplyForce(controls:Mul(dt * kMoveForce))
        
    else
        player:SetLinearDamping(kStandingDamping)
    end
    
end

local function Update(self, dt)

    self.world:IterateTag("Updates", function(object) object:Update(dt) end)
    
    UpdateMovement(self.player, dt)
    UpdateSkateMarks(self.staticBackground, self.player, dt)

    self.player:Update(dt)
    
    self.physicsWorld:update(dt)
    
end

local function DrawWorld(self)
    love.graphics.draw(self.staticBackground)
end

local function WorldDrawerSorter(a, b)
    return a:GetPosition().y < b:GetPosition().y
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