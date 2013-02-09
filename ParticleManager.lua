
local function SpawnParticleSystem(manager, world)

    local particleImageData = love.image.newImageData(1, 1)
    particleImageData:setPixel(0, 0, 255, 0, 0, 255)
    local particleImage = love.graphics.newImage(particleImageData)
    local resultsEffect = love.graphics.newParticleSystem(particleImage, 250)
    
    resultsEffect:setGravity(15, 25)
    resultsEffect:setColor(255, 255, 255, 255, 255, 255, 255, 0)
    resultsEffect:setEmissionRate(30)
    resultsEffect:setParticleLife(1, 5)
    resultsEffect:setSpeed(30, 60)
    resultsEffect:setSpread(math.pi / 4)
    resultsEffect:setDirection(-math.pi / 2)
    resultsEffect:setLifetime(-1)
    resultsEffect:setSize(5, 15, 0.5)
    resultsEffect:start()
    
end

local function UpdateParticleManager(self, dt)

	for p = #self.particleSystems, 1, -1 do
		self.particleSystems[p]:Update(dt)
	end

end

local function CreateParticleManager()

	local particleManager = { }

	return particleManager

end

return { Create = CreateParticleManager }