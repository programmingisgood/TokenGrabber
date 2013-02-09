
local SimpleInput = require("SimpleInput")
local World = require("World")
local Grid = require("Grid")
local IMGUI = require("IMGUI")
local Sound = require("Sound")
local Tween = require("Tween")
require("DebugDrawer")

require("GridMixin")
require("LiveMixin")

local kWorldWidth = 1280
local kWorldHeight = 720

local function RandomPointInWorld()
    return vec2(RandomFloatBetween(100, kWorldWidth - 100), RandomFloatBetween(100, kWorldHeight - 100))
end

local kMoveSpeed = 100
local kArrowSpeed = 400

local kStepSoundRate = 0.3

local kBlockTypes = { }
table.insert(kBlockTypes, { name = "sand" })
table.insert(kBlockTypes, { name = "wood" })
table.insert(kBlockTypes, { name = "stone" })

local kPointWidth = 32
local kPointHeight = 32
local kNumLayers = 5
local kLayerHeight = 16

local kBuildTime = 45

local kMonstersPerRoundPerPlayer = 10
local kMonsterSpawnRate = 2

local kArrowSpawnRate = 0.5

local function Init(self)

    math.randomseed(os.time())
    
    self.world = World.Create()
    self.grid = Grid.Create(kWorldWidth, kWorldHeight, kPointWidth, kPointHeight, kNumLayers, kLayerHeight)
    
    -- Create inputs for each player.
    self.inputs = { }
    table.insert(self.inputs, SimpleInput.Create(1))
    table.insert(self.inputs, SimpleInput.Create(2))
    table.insert(self.inputs, SimpleInput.Create(3))
    table.insert(self.inputs, SimpleInput.Create(4))
    
    self.staticBackground = love.graphics.newFramebuffer(kWorldWidth, kWorldHeight)
    
    local cobbleTile = love.graphics.newImage("art/CastleBuilder/cobble.png")
    cobbleTile:setFilter("nearest", "nearest")
    local cobbleTileWidth = cobbleTile:getWidth() * 2
    local cobbleTileHeight = cobbleTile:getHeight() * 2
    local numTilesWide = kWorldWidth / cobbleTileWidth
    local numTilesHigh = kWorldHeight / cobbleTileHeight
    self.staticBackground:renderTo(
    function()
    
        for w = 0, numTilesWide do
        
            for h = 0, numTilesHigh do
                love.graphics.draw(cobbleTile, w * cobbleTileWidth, h * cobbleTileHeight, 0, 2, 2)
            end
            
        end
        
    end)
    
    self.buildMusic = Sound.Create("art/CastleBuilder/loop1.mp3", "stream")
    self.buildMusic:SetLooping(true)
    self.buildMusic:SetVolume(0.05)
    self.buildMusic:Play()
    
    self.attackMusic = Sound.Create("art/CastleBuilder/loop2.mp3", "stream")
    self.attackMusic:SetLooping(true)
    self.attackMusic:SetVolume(0.05)
    
    self.treasure = { }
    InitMixin(self.treasure, MovableMixin)
    InitMixin(self.treasure, SpriteMixin)
    self.treasure:SetPosition(vec2(kWorldWidth / 2, 64))
    self.treasure:SetImage("art/CastleBuilder/treasure.png", 1, 1)
    self.world:Add(self.treasure, { "Treasure", "Draws" })
    
    self.gameState = "waiting"
    self.gameStateTime = Now()
    
    self.monstersToSpawn = 0
    
    self.currentRound = 1
    
end

local function OnKeyPressed(self, keyPressed)

    -- For testing only!
    if keyPressed == "p" then
        self.gameStateTime = self.gameStateTime - 100
    end
    
end

local function OnKeyReleased(self, keyReleased)
end

local function GetBlockSpriteName(blockType)
    return "art/CastleBuilder/block_" .. kBlockTypes[blockType].name .. ".png"
end

local function UpdateSpawnBlock(block, dt)

    if block.blockType ~= block.owner.blockType then
    
        block.blockType = block.owner.blockType
        block:SetImage(GetBlockSpriteName(block.blockType), 1, 1)
        
    end
    
    block.alpha = 255--180 + CosAnim(10) * 50
    
end

local function SpawnWorldBlock(atPos, blockType, world, grid)

    local gridLayer = grid:GetLayerAt(atPos)
    if gridLayer >= kNumLayers then
        return
    end
    
    local worldBlock = { }
    InitMixin(worldBlock, MovableMixin)
    InitMixin(worldBlock, SpriteMixin)
    worldBlock:SetImage(GetBlockSpriteName(blockType), 1, 1)
    world:Add(worldBlock, { "WorldBlock" })
    
    InitMixin(worldBlock, GridMixin)
    worldBlock:SetPosition(atPos)
    worldBlock:SetGridPosition(atPos)
    worldBlock:SetGridLayer(gridLayer + 1)
    grid:Add(worldBlock)
    
    InitMixin(worldBlock, LiveMixin)
    worldBlock:SetHealth(1, 1)
    function worldBlock:OnKilled()
    
        world:Remove(self)
        grid:Remove(self)
        
    end
    
    worldBlock:SetPosition(grid:ConvertGridToWorld(atPos, gridLayer))
    
    Sound.Play("art/CastleBuilder/" .. kBlockTypes[blockType].name .. "-build.wav")
    
end

local function CheckMonsterHitByArrow(monster, arrow)

    if arrow:GetBoundingBox():Overlaps(monster:GetBoundingBox()) then
    
        monster.world:Remove(monster)
        monster.grid:Remove(monster)
        arrow.world:Remove(arrow)
        
    end
    
end

local function UpdateArrow(self, dt)

    local arrowPos = self:GetPosition()
    
    self:SetPosition(arrowPos:Add(self.dir:Mul(dt * kArrowSpeed)))
    
    self.world:IterateTag("Monster", Bind(CheckMonsterHitByArrow, self))
    
    if not self:GetBoundingBox():Overlaps(GetScreenBoundingBox()) then
        self.world:Remove(self)
    end
    
end

local function SpawnArrow(atPos, dir, world)

    local arrow = { }
    arrow.Update = UpdateArrow
    arrow.world = world
    InitMixin(arrow, MovableMixin)
    InitMixin(arrow, SpriteMixin)
    arrow:SetImage("art/CastleBuilder/arrow.png", 1, 1)
    arrow:SetScale(vec2(1, 1))
    arrow:SetPosition(atPos)
    arrow:SetRotation(dir:ToAngle())
    arrow.dir = dir
    arrow.world:Add(arrow, { "Arrow", "Updates", "Draws" })
    
end

local function UpdatePlayer(player, dt)

    local controls = vec2(0, 0)
    controls.x = player.input:GetInputState("X")
    controls.y = player.input:GetInputState("Y")
    controls.x = math.abs(controls.x) < 0.2 and 0 or controls.x
    controls.y = math.abs(controls.y) < 0.2 and 0 or controls.y
    
    local moving = math.abs(controls.x) > 0 or math.abs(controls.y) > 0
    
    if moving then
    
        player.lastStepTime = player.lastStepTime or 0
        if Now() - player.lastStepTime >= kStepSoundRate then
        
            player.lastStepTime = Now()
            Sound.Play("art/CastleBuilder/footstep1.wav", 0.2)
            
        end
        
        local facingDir = controls:Normalize()
        player.arrowDir = vec2(facingDir.x, facingDir.y)
        
        if facingDir.x < -0.5 then
            player.facingDir = "West"
        elseif facingDir.x >= 0.5 then
            player.facingDir = "East"
        end
        
        if facingDir.y < -0.5 then
            player.facingDir = "North"
        elseif facingDir.y >= 0.5 then
            player.facingDir = "South"
        end
        
        player:SetAnimation("Walk" .. player.facingDir)
        
    else
        player:SetAnimation("Idle" .. player.facingDir)
    end
    
    -- Control the block spawn point.
    local blockStick = vec2(player.input:GetInputState("V"), player.input:GetInputState("W"))
    blockStick = blockStick:Normalize()
    if blockStick:Length() > 0.9 then
        --player.lastMoveDir = blockStick
    end
    
    local newPos = player:GetPosition():Add(controls:Mul(dt * kMoveSpeed))
    newPos.x = Clamp(newPos.x, player:GetWidth(), kWorldWidth - player:GetWidth())
    newPos.y = Clamp(newPos.y, player:GetHeight(), kWorldHeight - player:GetHeight())
    -- Use the feet of the player as the origin in the grid.
    local feetPos = newPos:Add(vec2(0, player:GetHeight() / 2))
    local gridPos = player.grid:GetGridPosition(feetPos)
    
    local gridObj = player.grid:GetObjectAtGridPoint(gridPos)
    if gridObj == nil or gridObj == player then
    
        player:SetPosition(newPos)
        player:SetGridPosition(gridPos)
        
    end
    
    local inBuildState = player.game.gameState == "build"
    
    -- Switch block type.
    if player.bNotPressed and player.input:GetInputState("B") > 0.5 then
        player.blockType = (player.blockType + 1 <= #kBlockTypes) and player.blockType + 1 or 1
    end
    player.bNotPressed = not (player.input:GetInputState("B") > 0.5)
    
    player.spawnBlock:SetColor(color(255, 255, 255, player.spawnBlock.alpha))
    local blockPos = player:GetPosition():Add(vec2(player.lastMoveDir.x * 48, player.lastMoveDir.y * 48))
    -- Lock to grid.
    blockPos = player.grid:GetGridPosition(blockPos)
    -- Move spawn block up the stack of blocks.
    local adjustedBlockPos = player.grid:ConvertGridToWorld(blockPos, player.grid:GetLayerAt(blockPos) + 1)
    player.spawnBlock:SetPosition(adjustedBlockPos)
    
    -- Check if we want to spawn a block.
    if player.aNotPressed and player.input:GetInputState("A") > 0.5 then
    
        if inBuildState then
            SpawnWorldBlock(blockPos, player.blockType, player.world, player.grid)
        else
        
            player.spawnArrowTime = player.spawnArrowTime or 0
            if Now() - player.spawnArrowTime >= kArrowSpawnRate then
            
                player.spawnArrowTime = Now()
                SpawnArrow(player:GetPosition(), player.arrowDir, player.world)
                
            end
            
        end
        
    end
    player.aNotPressed = not (player.input:GetInputState("A") > 0.5)
    
end

local function SpawnPlayer(self, index, input)

    local player = { }
    player.Update = UpdatePlayer
    player.input = input
    player.world = self.world
    player.grid = self.grid
    player.game = self
    player.lastMoveDir = vec2(0, 1)
    player.arrowDir = vec2(0, 1)
    InitMixin(player, MovableMixin)
    InitMixin(player, SpriteMixin)
    
    player:SetImage("art/CastleBuilder/player_" .. index .. ".png", 1, 12)
    player:AddAnimation("IdleSouth", { { frame = 1, time = 1 } })
    player:AddAnimation("IdleNorth", { { frame = 4, time = 1 } })
    player:AddAnimation("IdleWest", { { frame = 7, time = 1 } })
    player:AddAnimation("IdleEast", { { frame = 10, time = 1 } })
    
    local walkSouth = { { frame = 1, time = 0.2 }, { frame = 2, time = 0.2 }, { frame = 3, time = 0.2 } }
    player:AddAnimation("WalkSouth", walkSouth)
    local walkNorth = { { frame = 4, time = 0.2 }, { frame = 5, time = 0.2 }, { frame = 6, time = 0.2 } }
    player:AddAnimation("WalkNorth", walkNorth)
    local walkWest = { { frame = 7, time = 0.2 }, { frame = 8, time = 0.2 }, { frame = 9, time = 0.2 } }
    player:AddAnimation("WalkWest", walkWest)
    local walkEast = { { frame = 10, time = 0.2 }, { frame = 11, time = 0.2 }, { frame = 12, time = 0.2 } }
    player:AddAnimation("WalkEast", walkEast)
    
    player:SetAnimation("IdleSouth")
    
    player.facingDir = "South"
    
    player:SetScale(vec2(2, 2))
    player:SetPosition(vec2(kWorldWidth / 2, kWorldHeight / 2))
    self.world:Add(player, { "Player", "Updates" })
    
    InitMixin(player, GridMixin)
    player:SetGridLayer(1)
    player:SetGridPosition(player:GetPosition())
    player:SetUsesGridPositionForRendering(false)
    player:SetGridViewer(true)
    self.grid:Add(player)
    
    local spawnBlock = { }
    spawnBlock.Update = UpdateSpawnBlock
    InitMixin(spawnBlock, MovableMixin)
    InitMixin(spawnBlock, SpriteMixin)
    spawnBlock:SetImage("art/CastleBuilder/block_stone.png", 1, 1)
    spawnBlock:SetColor(color(255, 255, 255, 0))
    spawnBlock.alpha = 255
    self.world:Add(spawnBlock, { "SpawnBlock", "Updates" })
    player.spawnBlock = spawnBlock
    player.spawnBlock.outline = { }
    InitMixin(player.spawnBlock.outline, MovableMixin)
    InitMixin(player.spawnBlock.outline, SpriteMixin)
    player.spawnBlock.outline:SetImage("art/CastleBuilder/block_player" .. index .. ".png", 1, 1)
    function player.spawnBlock:OnDrawComplete()
    
        player.spawnBlock.outline:SetPosition(player.spawnBlock:GetPosition())
        player.spawnBlock.outline:Draw()
        
    end
    spawnBlock.owner = player
    
    player.blockType = 1
    
    return player
    
end

local function CheckPlayerSpawns(self)

    for p = 1, #self.inputs do
    
        local input = self.inputs[p]
        if not input.spawned and input:GetInputState("A") > 0.5 then
        
            input.spawned = true
            return SpawnPlayer(self, p, input)
            
        end
        
    end
    
    return nil
    
end

local function GetBuildTimeLeft(self)
    return self.gameStateTime + kBuildTime - Now()
end

local function UpdateMonster(monster, dt)

    local dir = monster.treasure:GetPosition():Sub(monster:GetPosition()):Normalize()
    local newPos = monster:GetPosition():Add(dir:Mul(dt * kMoveSpeed))
    
    -- Use the feet of the monster as the origin in the grid.
    local feetPos = newPos:Add(vec2(0, monster:GetHeight() / 2))
    local gridPos = monster.grid:GetGridPosition(feetPos)
    
    local gridObj = monster.grid:GetObjectAtGridPoint(gridPos)
    if gridObj == nil or gridObj == monster or gridObj == monster then
    
        monster:SetPosition(newPos)
        monster:SetGridPosition(gridPos)
        
    else
    
        if HasMixin(gridObj, "Live") then
            gridObj:TakeDamage(1 * dt)
        end
        
    end
    
end

local function SpawnMonster(self)

    self.monstersToSpawn = self.monstersToSpawn - 1
    
    local monster = { }
    monster.Update = UpdateMonster
    monster.world = self.world
    monster.grid = self.grid
    monster.treasure = self.treasure
    InitMixin(monster, MovableMixin)
    InitMixin(monster, SpriteMixin)
    monster:SetImage("art/CastleBuilder/monster.png", 1, 1)
    monster:SetScale(vec2(2, 2))
    monster:SetPosition(vec2(math.random() * kWorldWidth, kWorldHeight - 64))
    self.world:Add(monster, { "Monster", "Updates" })
    
    InitMixin(monster, GridMixin)
    monster:SetGridLayer(1)
    monster:SetGridPosition(monster:GetPosition())
    monster:SetUsesGridPositionForRendering(false)
    monster:SetGridViewer(true)
    self.grid:Add(monster)
    
    Sound.Play("art/CastleBuilder/spawn1.wav", 0.2)
    
end

local function Update(self, dt)

    local spawnedPlayer = CheckPlayerSpawns(self)
    if self.gameState == "waiting" and spawnedPlayer ~= nil then
    
        self.gameState = "build"
        self.gameStateTime = Now()
        
    end
    
    self.world:IterateTag("Updates", function(object) object:Update(dt) end)
    
    if self.gameState == "build" then
    
        if GetBuildTimeLeft(self) <= 0 then
        
            self.gameState = "attack"
            local numPlayers = self.world:QueryNumberWithTag("Player")
            self.monstersToSpawn = self.currentRound * kMonstersPerRoundPerPlayer * numPlayers
            
            self.buildMusic:Pause()
            self.attackMusic:Play()
            
        end
        
    elseif self.gameState == "attack" then
    
        if self.monstersToSpawn > 0 then
        
            self.lastMonsterSpawnedAt = self.lastMonsterSpawnedAt or 0
            if Now() - self.lastMonsterSpawnedAt >= kMonsterSpawnRate then
            
                self.lastMonsterSpawnedAt = Now()
                SpawnMonster(self)
                
            end
            
        else
        
            -- When all monsters killed, start the next build round.
            local numMonsters = self.world:QueryNumberWithTag("Monster")
            if numMonsters == 0 then
            
                self.gameState = "build"
                self.gameStateTime = Now()
                
                self.attackMusic:Pause()
                self.buildMusic:Play()
                
                self.currentRound = self.currentRound + 1
                
            end
            
        end
        
    end
    
end

local function DrawWorld(self)
    love.graphics.draw(self.staticBackground)
end

local function DrawPlayerUI(player)

    
    
end

local function DrawGameUI(self)

    local text = ""
    
    if self.gameState == "build" then
        text = string.format("%d", GetBuildTimeLeft(self))
    elseif self.gameState == "attack" then
        text = tostring(self.monstersToSpawn + self.world:QueryNumberWithTag("Monster"))
    elseif self.gameState == "waiting" then
        text = "Waiting for players"
    end
    
    IMGUI.Text({ text = text, font = self.font, pos = vec2(GetScreenDims() / 2, 32), scale = vec2(1, 1), color = color(255, 255, 255, 255) })
    
end

local function Draw(self)

    love.graphics.push()
    
    DrawWorld(self)
    
    self.grid:Draw()
    
    self.world:IterateTag("Draws", function(object) object:Draw() love.graphics.reset() end)
    
    if self.gameState == "build" then
        self.world:IterateTag("SpawnBlock", function(object) object:Draw() love.graphics.reset() end)
    end
    
    love.graphics.pop()
    
    self.world:IterateTag("Player", DrawPlayerUI)
    
    DrawGameUI(self)
    
    DebugDrawer.Draw()
    
end

local function Create(useFont, client, server)

    local state = { }
    
    state.font = useFont
    state.OnKeyPressed = OnKeyPressed
    state.OnKeyReleased = OnKeyReleased
    state.Update = Update
    state.Draw = Draw
    Init(state)
    
    return state
    
end

return { Create = Create }