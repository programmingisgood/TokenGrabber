
local SimpleInput = require("SimpleInput")
local Camera = require("Camera")
local World = require("World")
local IMGUI = require("IMGUI")
local Sound = require("Sound")
local Tween = require("Tween")
local Quest = require("StabboQuest")
local Dialog = require("Dialog")
require("UsableMixin")
require("CollectibleMixin")
require("CollectorMixin")
require("TimedCallbackMixin")
require("PhysicsMixin")
require("UpgradableMixin")
require("DebugDrawer")

local kWorldWidth = 1024
local kWorldHeight = 1024

local function RandomPointInWorld()
    return vec2(RandomFloatBetween(100, kWorldWidth - 100), RandomFloatBetween(100, kWorldHeight - 100))
end

local kMoveForce = 40000
local kMaxSpeed = 140

local kHumanMass = 1
local kMovingDamping = 0.1
local kStandingDamping = 10

local kCheckUseRange = 100

local kRobDistance = 20
local kShopDistance = 60

local kExtraReachDistance = 10

local kRobTime = 1
local kRobMinCoins = 3
local kRobMaxCoins = 5
local kCoinXForce = 1000
local kCoinYForce = 1000
local kCoinMass = 0.2
local kCoinDamping = 2.2
local kCollectCoinRange = 20
local kCoinPickupTime = 0.5
local kCoinAttractDistanceSq = 100 * 100

local kHUDCoinPos = vec2(40, 40)

local kDustPerLevel = 2

local kCollisionCategories = { }
kCollisionCategories.coin = 1
kCollisionCategories.human = 2
kCollisionCategories.structure = 3

local function GetDustProgress(dust, level)
    return dust / ((level * level) * kDustPerLevel)
end

local function CreateCoins(playState, fromPos)

    local numCoins = math.random(kRobMinCoins, kRobMaxCoins)
    for c = 1, numCoins do
    
        local coin = { }
        InitMixin(coin, MovableMixin)
        InitMixin(coin, SpriteMixin)
        
        function coin:OnCollected(player)
        
            player.coins = player.coins + 1
            playState.world:Remove(coin)
            Sound.Play("art/Stabbo/coin_pickup.wav")
            local screenPos = playState.camera:GetScreenPosition(coin:GetPosition())
            screenPos.y = screenPos.y - 16
            table.insert(playState.collectingCoins, { pos = screenPos, time = 0, anim = 0 })
            
        end
        
        InitMixin(coin, CollectibleMixin)
        coin:SetIsCollectible(false)
        
        InitMixin(coin, TimedCallbackMixin)
        coin:AddTimedCallback(function() coin:SetIsCollectible(true) end, kCoinPickupTime)
        
        coin:SetImage("art/Stabbo/Coin.png", 1, 4)
        coin:SetScale(vec2(1, 1))
        coin:SetPosition(vec2(fromPos.x, fromPos.y))
        
        InitMixin(coin, PhysicsMixin)
        coin:SetupPhysics(playState.physicsWorld, kCoinMass, 0, love.physics.newCircleShape(coin:GetWidth() / 2))
        coin:SetCollisionCategory(kCollisionCategories.coin)
        coin:SetCollisionMask(kCollisionCategories.human, kCollisionCategories.coin)
        
        local animTime = RandomFloatBetween(0.15, 0.25)
        local idleAnim = { { frame = 1, time = animTime },
                           { frame = 2, time = animTime },
                           { frame = 3, time = animTime },
                           { frame = 4, time = animTime },
                           { frame = 3, time = animTime },
                           { frame = 2, time = animTime } }
        coin:AddAnimation("idle", idleAnim)
        coin:SetAnimation("idle")
        
        coin:SetLinearDamping(kCoinDamping)
        coin:ApplyForce(vec2(RandomFloatBetween(-kCoinXForce, kCoinXForce), RandomFloatBetween(-kCoinYForce, kCoinYForce)))
        
        playState.world:Add(coin, { "Draws", "Updates", "Coin" })
        
    end
    
end

local kMinVillagerSpeed = 0.5
local kMaxVillagerSpeed = 1

local function CreateVillager(playState)

    local villager = { }
    
    villager.speed = RandomFloatBetween(kMinVillagerSpeed, kMaxVillagerSpeed)
    function villager:Update(dt)
    
        if self:GetUnderAttack() then
        
            self:SetColor(color(155 + 100 * CosAnim(20), 100, 100, 255))
            return
            
        else
            self:SetColor(color(255, 255, 255, 255))
        end
        
        if self.moveToSpot then
        
            local dir = self.moveToSpot:Sub(self:GetPosition())
            local dirNorm = dir:Normalize()
            self:SetPosition(self:GetPosition():Add(dirNorm:Mul(self.speed)))
            if dir:LengthSquared() <= 20 * 20 then
                self.moveToSpot = nil
            end
            
        else
            self.moveToSpot = RandomPointInWorld()
        end
        
    end
    
    villager.underAttackTime = 0
    function villager:OnUseProgress()
        self.underAttackTime = Now()
    end
    
    function villager:GetUnderAttack()
        return Now() - self.underAttackTime < 1
    end
    
    function villager:OnUseEnd()
    
        CreateCoins(playState, villager:GetPosition())
        playState.world:Remove(self)
        Sound.Play("art/Stabbo/kill.wav", 1.5)
        -- Replace him.
        CreateVillager(playState)
        
    end
    
    InitMixin(villager, MovableMixin)
    InitMixin(villager, SpriteMixin)
    InitMixin(villager, UsableMixin, kRobTime, kRobTime / 4, kRobDistance)
    
    villager:SetImage("art/Stabbo/Villager" .. math.random(1, 2) .. ".png", 1, 1)
    villager:SetScale(vec2(2, 2))
    villager:SetPosition(RandomPointInWorld())
    
    playState.world:Add(villager, { "Draws", "Updates", "Villager" })
    
    return villager
    
end

local function CreateDealer(world, physicsWorld, position, stabbo)

    local dealer = { }
    InitMixin(dealer, MovableMixin)
    InitMixin(dealer, SpriteMixin)
    InitMixin(dealer, UsableMixin, 0.01, 0.01, kShopDistance, false)
    
    dealer:SetImage("art/Stabbo/Dealer.png", 1, 1)
    dealer:SetScale(vec2(2, 2))
    dealer:SetPosition(position)
    
    InitMixin(dealer, PhysicsMixin)
    dealer:SetupPhysics(physicsWorld, kHumanMass, 0, love.physics.newCircleShape(dealer:GetWidth() / 4))
    dealer:SetPhysicsType("static")
    dealer:SetCollisionCategory(kCollisionCategories.structure)
    
    function dealer.OnUseEnd()
    
        if not stabbo.buying and Now() - stabbo.lastBuyTime >= 0.6 then
        
            stabbo.buying = true
            stabbo.buyMenuLocked = true
            Sound.Play("art/Stabbo/kill.wav", 1.5)
            
        end
        
    end
    
    world:Add(dealer, { "Draws", "Updates", "Dealer" })
    
    dealer.store = { }
    
    local function BuyDust()
    
        stabbo.dust = stabbo.dust + 1
        if GetDustProgress(stabbo.dust, stabbo.level) >= 1 then
        
            stabbo.dust = 0
            stabbo.level = stabbo.level + 1
            
        end
        
    end
    table.insert(dealer.store, { name = "Colombian Fairy Dust", cost = 10, OnBuy = BuyDust })
    table.insert(dealer.store, { name = "Mexican Fairy Dust", cost = 5, OnBuy = BuyDust })
    table.insert(dealer.store, { name = "Texas Fairy Dust", cost = 7, OnBuy = BuyDust })
    table.insert(dealer.store, { name = "Wand of Coin Attraction", cost = 37, amount = 1, OnBuy = function() stabbo:AddUpgrade("CoinAttraction") end })
    table.insert(dealer.store, { name = "Gem of Multi-Villager Conversion", cost = 25, amount = 2, OnBuy = function() stabbo:AddUpgrade("VillagerUse") end })
    table.insert(dealer.store, { name = "Ring of Extended Reach", cost = 50, amount = 1, OnBuy = function() stabbo:AddUpgrade("ExtendedReach") end })
    
    return dealer
    
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

local function PreloadAssets()

    Sound.Preload("art/Stabbo/coin_pickup.wav")
    
end

local function Init(self)

    PreloadAssets()
    
    math.randomseed(os.time())
    
    self.world = World.Create()
    self.physicsWorld = love.physics.newWorld(0, 0, true)
    
    InitWorldBounds(self.physicsWorld)
    
    local spawnPoint = vec2(kWorldWidth / 2, kWorldHeight / 2 + 200)
    
    self.stabbo = { }
    InitMixin(self.stabbo, MovableMixin)
    InitMixin(self.stabbo, SpriteMixin)
    InitMixin(self.stabbo, CollectorMixin, self.world, kCollectCoinRange)
    InitMixin(self.stabbo, UpgradableMixin)
    
    self.stabbo:SetImage("art/Stabbo/stabbo.png", 1, 1)
    self.stabbo:SetScale(vec2(2, 2))
    self.stabbo:SetPosition(spawnPoint)
    self.stabbo.input = SimpleInput.Create(1)
    
    InitMixin(self.stabbo, PhysicsMixin)
    
    self.stabbo:SetupPhysics(self.physicsWorld, kHumanMass, 0, love.physics.newRectangleShape(self.stabbo:GetWidth(), self.stabbo:GetHeight()))
    self.stabbo:SetCollisionCategory(kCollisionCategories.human)
    self.stabbo:SetCollisionMask(kCollisionCategories.coin)
    self.stabbo:SetLinearDamping(kStandingDamping)
    self.stabbo:SetMaxSpeed(kMaxSpeed)
    
    self.stabbo:AddUpgrade("VillagerUse")
    
    self.stabbo.coins = 0
    self.stabbo.dust = 0
    self.stabbo.level = 1
    self.stabbo.lastBuyTime = 0
    
    self.stabbo.useSound = Sound.Create("art/Stabbo/bar_fill.wav")
    self.stabbo.useSound:SetVolume(1.7)
    self.stabbo.useSound:SetLooping(true)
    
    self.stabbo.buyIndex = 1
    
    self.world:Add(self.stabbo, { "Draws" })
    
    self.staticBackground = love.graphics.newCanvas(kWorldWidth, kWorldHeight)
    
    local cobbleTile = love.graphics.newImage("art/Stabbo/cobble.png")
    cobbleTile:setFilter("nearest", "nearest")
    local cobbleTileWidth = cobbleTile:getWidth() * 2
    local cobbleTileHeight = cobbleTile:getHeight() * 2
    local numTilesWide = kWorldWidth / cobbleTileWidth
    local numTilesHigh = kWorldHeight / cobbleTileHeight
    self.staticBackground:renderTo(
    function()
    
        for w = 0, numTilesWide - 1 do
        
            for h = 0, numTilesHigh - 1 do
                love.graphics.draw(cobbleTile, w * cobbleTileWidth, h * cobbleTileHeight, 0, 2, 2)
            end
            
        end
        
    end)
    
    self.camera = Camera.Create()
    self.camera:SetWorldExtents(kWorldWidth, kWorldHeight)
    self.camera:SetFocusObject(self.stabbo)
    
    self.collectingCoins = { }
    
    for v = 1, 25 do
        CreateVillager(self)
    end
    
    self.dealer = CreateDealer(self.world, self.physicsWorld, vec2(kWorldWidth / 2, kWorldHeight / 2), self.stabbo)
    
    Quest.Create(self.world, RandomPointInWorld(), self.font)
    
end

local function OnKeyPressed(self, keyPressed)

    if keyPressed == "escape" then
    
        if self.stabbo.buying then
            self.stabbo.buying = false
        else
        
            local dialogs = self.world:CollectAllWithTag("Dialog")
            for d = 1, #dialogs do
                self.world:Remove(dialogs[d])
            end
            
        end
        
    end
    
end

local function OnKeyReleased(self, keyReleased)
end

local function UpdateUsing(self, dt)

    if self.stabbo.input:GetInputState("A") > 0 then
    
        local nearbyUsables = self.world:Query("Usable", self.stabbo:GetPosition(), kCheckUseRange)
        local somethingWasUsed = false
        
        if not self.stabbo.buying then
        
            local numUsed = 0
            local maxUseAmount = 0
            for u = 1, #nearbyUsables do
            
                local usable = nearbyUsables[u]
                local usableDist = usable:GetUseDistance()
                
                local extraReach = self.stabbo:GetUpgrade("ExtendedReach")
                usableDist = usableDist + (extraReach * kExtraReachDistance)
                
                local distTo = usable:GetPosition():Sub(self.stabbo:GetPosition()):LengthSquared()
                if distTo <= (usableDist * usableDist) then
                
                    if not self.stabbo.using then
                    
                        self.stabbo.using = true
                        self.stabbo.useSound:SetPitch(1)
                        self.stabbo.useSound:Play()
                        
                    end
                    
                    usable:Use(dt)
                    
                    somethingWasUsed = true
                    maxUseAmount = math.max(maxUseAmount, 1 + 1 * usable:GetUseProgress())
                    
                    numUsed = numUsed + 1
                    if numUsed >= self.stabbo:GetUpgrade("VillagerUse") then
                        break
                    end
                    
                end
                
            end
            
            if somethingWasUsed then
                self.stabbo.useSound:SetPitch(maxUseAmount)
            end
            
        end
        
        if not somethingWasUsed and self.stabbo.using then
        
            self.stabbo.using = false
            self.stabbo.useSound:Stop()
            
        end
        
    else
        self.stabbo.useSound:Stop()
    end
    
end

local function UpdateDialog(stabbo, dialog)

    dialog.lastInputX = dialog.lastInputX or 0
    local inputX = stabbo.input:GetInputState("X")
    if dialog.lastInputX < 0.5 and inputX >= 0.5 then
        dialog:SelectNext()
    elseif dialog.lastInputX > -0.5 and inputX <= -0.5 then
        dialog:SelectPrevious()
    end
    
    dialog.lastInputX = inputX
    
end

local function UpdateMovement(stabbo, dt)

    local controls = vec2(0, 0)
    controls.x = stabbo.input:GetInputState("X")
    controls.y = stabbo.input:GetInputState("Y")
    controls.x = math.abs(controls.x) < 0.2 and 0 or controls.x
    controls.y = math.abs(controls.y) < 0.2 and 0 or controls.y
    
    local moving = math.abs(controls.x) > 0 or math.abs(controls.y) > 0
    
    if moving then
    
        stabbo:SetLinearDamping(kMovingDamping)
        stabbo:ApplyForce(controls:Mul(dt * kMoveForce))
        
    else
        stabbo:SetLinearDamping(kStandingDamping)
    end
    
end

local function CanAffordToBuy(stabbo, dealer, buyIndex)

    local storeItem = dealer.store[buyIndex]
    local hasEnoughInStore = storeItem.amount == nil or storeItem.amount > 0
    return hasEnoughInStore and stabbo.coins >= storeItem.cost, storeItem.cost
    
end

local function UpdateBuying(self, dt)

    self.stabbo.buyIndexChangeTime = self.stabbo.buyIndexChangeTime or 0
    if Now() - self.stabbo.buyIndexChangeTime >= 0.2 then
    
        if self.stabbo.input:GetInputState("Y") > 0.5 then
        
            self.stabbo.buyIndex = math.min(#self.dealer.store, self.stabbo.buyIndex + 1)
            self.stabbo.buyIndexChangeTime = Now()
            Sound.Play("art/Stabbo/menu_move.wav")
            
        elseif self.stabbo.input:GetInputState("Y") < -0.5 then
        
            self.stabbo.buyIndex = math.max(1, self.stabbo.buyIndex - 1)
            self.stabbo.buyIndexChangeTime = Now()
            Sound.Play("art/Stabbo/menu_move.wav")
            
        end
        
    end
    
    -- Cannot buy anything until A is released after first opening the menu.
    self.stabbo.buyMenuLocked = self.stabbo.buyMenuLocked and self.stabbo.input:GetInputState("A") > 0.5
    
    if not self.stabbo.buyMenuLocked then
    
        local canAfford, dustCost = CanAffordToBuy(self.stabbo, self.dealer, self.stabbo.buyIndex)
        if canAfford and self.stabbo.input:GetInputState("A") > 0.5 then
        
            self.stabbo.lastBuyTime = Now()
            self.stabbo.coins = self.stabbo.coins - dustCost
            
            local storeItem = self.dealer.store[self.stabbo.buyIndex]
            storeItem:OnBuy()
            if storeItem.amount then
                storeItem.amount = storeItem.amount - 1
            end
            
            self.stabbo.buying = false
            self.stabbo.buyMenuLocked = true
            Sound.Play("art/Stabbo/menu_select.wav")
            
        end
        
    end
    
    if self.stabbo.input:GetInputState("B") > 0.5 then
        self.stabbo.buying = false
    end
    
end

local function UpdateCoinAttraction(coin, toPos, dt)

    local coinPos = coin:GetPosition()
    if coin:GetIsCollectible() and coinPos:DistanceSquared(toPos) <= kCoinAttractDistanceSq then
        coin:ApplyForce(toPos:Sub(coinPos):Normalize():Mul(dt * 600))
    end
    
end

local function UpdateCollectingCoins(collectingCoins, dt)

    for c = #collectingCoins, 1, -1 do
    
        local coin = collectingCoins[c]
        coin.time = coin.time + dt
        coin.anim = Tween.InQuad(coin.time, 0, 1, 0.5)
        if coin.time >= 0.5 then
            table.remove(collectingCoins, c)
        end
        
    end
    
end

local function Update(self, dt)

    self.world:IterateTag("Updates", function(object) object:Update(dt) end)
    
    local dialogs = self.world:CollectAllWithTag("Dialog")
    
    if #dialogs > 0 then
        UpdateDialog(self.stabbo, dialogs[1])
    elseif self.stabbo.buying then
        UpdateBuying(self)
    else
        UpdateMovement(self.stabbo, dt)
    end
    
    UpdateUsing(self, dt)
    
    if self.stabbo:GetHasUpgrade("CoinAttraction") then
        self.world:IterateTag("Coin", function(coin) UpdateCoinAttraction(coin, self.stabbo:GetPosition(), dt) end)
    end
    
    UpdateCollectingCoins(self.collectingCoins, dt)
    
    self.stabbo:Update(dt)
    
    self.physicsWorld:update(dt)
    
end

local function DrawStoreHUD(self)

    local w, h = GetScreenDims()
    IMGUI.Rect({ pos = vec2(w / 2, h / 2), size = vec2(w, h), color = color(0, 0, 0, 180) })
    
    local itemStartY = h / 4
    local itemSpacingY = 64
    local itemY = itemStartY
    for i = 1, #self.dealer.store do
    
        local item = self.dealer.store[i]
        
        local canAfford = CanAffordToBuy(self.stabbo, self.dealer, i)
        local affordColor = canAfford and color(255, 255, 255, 255) or color(255, 0, 0, 255)
        
        IMGUI.Image({ path = "art/Stabbo/DustBag.png", pos = vec2(w / 10, itemY), scale = vec2(2, 2) })
        local selectAnim = 100 + (155 * CosAnim(10))
        local nameColor = self.stabbo.buyIndex == i and color(selectAnim, selectAnim, 0, 255) or color(255, 255, 255, 255)
        if not canAfford then
            nameColor = affordColor
        end
        IMGUI.Text({ text = item.name, font = self.font, pos = vec2(w / 2, itemY), scale = vec2(0.5, 0.5), color = nameColor })
        
        local coinPos = vec2(124, itemY)
        IMGUI.Image({ path = "art/Stabbo/UICoin.png", pos = coinPos, scale = vec2(3, 3), color = affordColor })
        IMGUI.Text({ text = tostring(item.cost), font = self.font, pos = coinPos, scale = vec2(0.5, 0.5), color = color(0, 0, 0, 255) })
        
        itemY = itemY + itemSpacingY
        
    end
    
end

local function DrawHUD(self)

    for c = 1, #self.collectingCoins do
    
        local coin = self.collectingCoins[c]
        local pos = coin.pos:Add(kHUDCoinPos:Sub(coin.pos):Mul(coin.anim))
        IMGUI.Image({ path = "art/Stabbo/UICoin.png", pos = pos, scale = vec2(1, 1) })
        
    end
    
    IMGUI.Image({ path = "art/Stabbo/UICoin.png", pos = kHUDCoinPos, scale = vec2(5, 5) })
    IMGUI.Text({ text = tostring(self.stabbo.coins), font = self.font, pos = vec2(40, 40), scale = vec2(0.6, 0.6), color = color(0, 0, 0, 255) })
    
    local barY = 100
    IMGUI.Image({ path = "art/Stabbo/DustBag.png", pos = vec2(40, barY), scale = vec2(4, 4) })
    local barWidth = 150
    local barHeight = 16
    local barX = 80
    IMGUI.Rect({ pos = vec2(barX, barY), alignx = "min", size = vec2(barWidth, barHeight), color = color(180, 180, 180, 160), style = "fill" })
    IMGUI.Rect({ pos = vec2(barX, barY), alignx = "min", size = vec2(barWidth * GetDustProgress(self.stabbo.dust, self.stabbo.level), barHeight), color = color(255, 255, 255, 255), style = "fill" })
    
    IMGUI.Text({ text = "Level " .. tostring(self.stabbo.level), font = self.font, pos = vec2(barX + barWidth / 2, barY), scale = vec2(0.6, 0.6), color = color(0, 0, 0, 255) })
    
    if self.stabbo.buying then
        DrawStoreHUD(self)
    end
    
end

local function DrawWorld(self)
    love.graphics.draw(self.staticBackground)
end

local function WorldDrawerSorter(a, b)
    return a:GetPosition().y < b:GetPosition().y
end

local function Draw(self)

    love.graphics.push()
    
    self.camera:Draw()
    
    DrawWorld(self)
    
    local worldDrawers = self.world:CollectAllWithTag("Draws")
    table.sort(worldDrawers, WorldDrawerSorter)
    Iterate(worldDrawers, function(object) object:Draw() end)
    
    worldDrawers = self.world:CollectAllWithTag("Draws2")
    table.sort(worldDrawers, WorldDrawerSorter)
    Iterate(worldDrawers, function(object) object:Draw() end)
    
    love.graphics.pop()
    
    DrawHUD(self)
    
    local dialogs = self.world:CollectAllWithTag("Dialog")
    if #dialogs > 0 then
        Dialog.Draw(dialogs[1])
    end
    
    DebugDrawer.Draw()
    
end

local function Create(useFont, client, server)

    local state = { }
    
    state.font = useFont
    state.OnKeyPressed = OnKeyPressed
    state.OnKeyReleased = OnKeyReleased
    state.Update = Update
    state.Draw = Draw
    state.GetBlocksEscape = function() return state.stabbo.buying or #state.world:CollectAllWithTag("Dialog") > 0 end
    Init(state)
    
    return state
    
end

return { Create = Create }