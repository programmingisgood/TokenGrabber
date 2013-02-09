
require("Utils")
require("Mixins")
require("MovableMixin")
require("SpriteMixin")
require("PhysicsMixin")

local SimpleInput = require("SimpleInput")

local kArtDir = "art/"
local kImageType = ".png"

local function GetImagePath(name)
    return kArtDir .. name .. kImageType
end

local kPlayAreaStartRadius = 280

local kMoveSpeed = 100
local kRollSpeedMod = 2

local kMaxRollingSpeed = 1000
local kRollingDamping = 0.01

local kMaxWalkingSpeed = 200
local kWalkingDamping = 2.9

local kFallRate = 3

local kBugMass = 10
local kBugRotInertia = 2

local kFont = love.graphics.newFont("art/press-start-2p/PressStart2P.ttf", 24)

-- Base set of animations for all bugs.

local kIdleAnim = { { frame = 1, time = -1 } }

local kMoveAnim = { { frame = 2, time = 0.1 }, { frame = 3, time = 0.1 } }

local kActionAnim = { { frame = 4, time = 0.2} }

local function InitBugAnimations(bug)

    bug:AddAnimation("idle", kIdleAnim)
    bug:AddAnimation("move", kMoveAnim)
    bug:AddAnimation("action", kActionAnim)
    
end


local function CreateRolyPoly(self)

    local newBug = { }
    
    InitMixin(newBug, MovableMixin)
    InitMixin(newBug, SpriteMixin)
    InitMixin(newBug, PhysicsMixin)
    
    newBug:SetImage(GetImagePath("roly_poly"), 4, 4)
    newBug:SetScale(vec2(2, 2))
    
    newBug:SetupPhysics(self.physicsWorld, kBugMass, kBugRotInertia)
    
    InitBugAnimations(newBug)
    
    return newBug
    
end

local function OnGameStart(self)

    self.playAreaRadius = kPlayAreaStartRadius
    
    local screenW, screenH = GetScreenDims()
    for p = 1, #self.players do
    
        local player = self.players[p]
        player.bug:SetPosition(vec2(screenW * player.spawnZone, screenH / 2))
        local toCenter = player.bug:GetPosition():Sub(GetScreenCenter()):ToAngle()
        player.bug:SetRotation(toCenter)
        
    end
    
    self.losers = { }
    
end

local function UpdateResults(self, dt)

    if not self.resultsEffect then
    
        local particleImageData = love.image.newImageData(1, 1)
        particleImageData:setPixel(0, 0, 255, 0, 0, 255)
        local particleImage = love.graphics.newImage(particleImageData)
        self.resultsEffect = love.graphics.newParticleSystem(particleImage, 250)
        
        self.resultsEffect:setGravity(15, 25)
        self.resultsEffect:setColor(255, 255, 255, 255, 255, 255, 255, 0)
        self.resultsEffect:setEmissionRate(30)
        self.resultsEffect:setParticleLife(1, 5)
        self.resultsEffect:setSpeed(30, 60)
        self.resultsEffect:setSpread(math.pi / 4)
        self.resultsEffect:setDirection(-math.pi / 2)
        self.resultsEffect:setLifetime(-1)
        self.resultsEffect:setSize(5, 15, 0.5)
        self.resultsEffect:start()
        
    end
    
    self.resultsEffect:update(dt)
    
end

local function CheckEndGame(self)

    if #self.losers >= (#self.players - 1) then
        self.gameState = self.resultsState
    end
    
end

local function UpdatePlayerFalling(player, game, dt)

    local scale = player.bug:GetScale()
    if scale:Length() <= 0.1 then
    
        table.insert(game.losers, player)
        player.visible = false
        
    else
        scale = scale:Sub(vec2(dt * kFallRate, dt * kFallRate))
    end
    
    player.bug:SetScale(scale)
    
    -- Spin around while falling! Yeah!
    local rot = player.bug:GetRotation()
    player.bug:SetRotation(rot + (dt * (math.pi / 0.2)))
    
    local newVel = player.bug:GetPosition():Sub(GetScreenCenter()):Normalize():Mul(100)
    player.bug:SetLinearVelocity(newVel)
    
end

local function UpdatePlayerPlaying(player, game, dt)

    local controls = vec2(0, 0)
    controls.x = player.input:GetInputState("X")
    controls.y = player.input:GetInputState("Y")
    
    controls.x = math.abs(controls.x) < 0.2 and 0 or controls.x
    controls.y = math.abs(controls.y) < 0.2 and 0 or controls.y
    
    local moving = math.abs(controls.x) > 0 or math.abs(controls.y) > 0
    
    local rolling = player.input:GetInputState("A") > 0.5
    
    local moveSpeed = dt * kMoveSpeed * (rolling and kRollSpeedMod or 1)
    
    if moving then
    
        player.bug:ApplyForce(controls:Mul(moveSpeed):Mul(10))
        player.bug:SetRotation(controls:ToAngle())
        player.bug:SetAnimation(rolling and "action" or "move")
        
    else
        player.bug:SetAnimation("idle")
    end
    
    local velocity = player.bug:GetLinearVelocity()
    local maxSpeed = rolling and kMaxRollingSpeed or kMaxWalkingSpeed
    
    if not moving then
        maxSpeed = 50
    end
    
    if velocity:Length() > maxSpeed then
        player.bug:SetLinearVelocity(velocity:Normalize():Mul(maxSpeed))
    end
    
    player.bug:SetLinearDamping(rolling and kRollingDamping or kWalkingDamping)
    
    if player.bug:GetPosition():Sub(GetScreenCenter()):Length() > game.playAreaRadius then
        player.state = UpdatePlayerFalling
    end
    
end

local function UpdatePlay(self, dt)

    self.playAreaRadius = self.playAreaRadius - dt
    
    for p = 1, #self.players do
    
        local player = self.players[p]
        
        player:state(game, dt)
        
        player.bug:Update(dt)
        
    end
    
    CheckEndGame(self)
    
    self.physicsWorld:update(dt)
    
end

local function Update(self, dt)
    self.gameState.update(self, dt)
end

local function DrawResults(self)

    if self.resultsEffect then
    
        local screenW, screenH = GetScreenDims()
        love.graphics.draw(self.resultsEffect, screenW / 2, screenH / 2, 0, 1, 1, 0, 0)
        
    end
    
end

local function DrawPlay(self)

    love.graphics.setColor(255, 255, 255, 255)
    local screenW, screenH = GetScreenDims()
    love.graphics.circle("fill", screenW / 2, screenH / 2, self.playAreaRadius, 50)
    
    for p = 1, #self.players do
    
        local player = self.players[p]
        if player.visible ~= false then
            player.bug:Draw()
        end
        
    end
    
end

local function Draw(self)

    love.graphics.setBackgroundColor(126, 126, 126)
    love.graphics.clear()
    
    self.gameState.draw(self)
    
    DrawFramerate()
    
end

local function Init(self)

    self.physicsWorld = love.physics.newWorld(-1000, 1000, -1000, 1000)
    
    self.playState = { update = UpdatePlay, draw = DrawPlay }
    self.resultsState = { update = UpdateResults, draw = DrawResults }
    self.gameState = self.playState
    
    self.players = { }
    
    table.insert(self.players, { color = color(255, 0, 0, 255), bugIndex = 1,
                                 bug = CreateRolyPoly(self),
                                 input = SimpleInput.Create(1),
                                 spawnZone = 0.25,
                                 state = UpdatePlayerPlaying })
    table.insert(self.players, { color = color(0, 0, 255, 255), bugIndex = 2,
                                 bug = CreateRolyPoly(self),
                                 input = SimpleInput.Create(2),
                                 spawnZone = 0.75,
                                 state = UpdatePlayerPlaying })
    
    OnGameStart(self)
    
end

local function RolyPolyPushGame()

    local game = { }
    
    Init(game)
    
    game.Update = Update
    game.Draw = Draw
    
    return game
    
end

return RolyPolyPushGame()