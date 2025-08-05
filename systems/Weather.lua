-- systems/Weather.lua
-- Weather effects system

local Config = require("config/Config")
local Utils = require("utils/Utils")

local Weather = {}
Weather.__index = Weather

-- Create a new weather system
function Weather.new(mapWidth, mapHeight, tileSize)
    local self = setmetatable({}, Weather)
    
    self.mapWidth = mapWidth
    self.mapHeight = mapHeight
    self.tileSize = tileSize or Config.tileSize
    
    -- Current weather type (1=clear, 2=rain, 3=snow, 4=fog)
    self.type = Utils.randomInt(1, 4)
    self.intensity = Utils.randomFloat(0.2, 0.7)
    
    -- Weather particles
    self.particles = {}
    self:initializeParticles(100)
    
    return self
end

-- Initialize weather particles
function Weather.initializeParticles(self, count)
    self.particles = {}
    
    for i = 1, count do
        table.insert(self.particles, {
            x = math.random(1, self.mapWidth) * self.tileSize,
            y = math.random(1, self.mapHeight) * self.tileSize,
            speed = math.random() * 5 + 5,
            size = math.random() * 3 + 1
        })
    end
end

-- Change the weather type
function Weather.changeWeather(self, weatherType, intensity)
    weatherType = weatherType or Utils.randomInt(1, 4)
    intensity = intensity or Utils.randomFloat(0.2, 0.7)
    
    self.type = weatherType
    self.intensity = intensity
    
    -- Re-initialize particles for the new weather
    self:initializeParticles(100)
    
    return self.type
end

-- Randomize weather (alias for changeWeather with random values)
function Weather.randomizeWeather(self)
    return self:changeWeather()
end

-- Update weather particles
function Weather.update(self, dt, currentFrame)
    local screenWidth = self.mapWidth * self.tileSize
    local screenHeight = self.mapHeight * self.tileSize
    
    for i, particle in ipairs(self.particles) do
        if self.type == Config.weatherTypes.rain then -- Rain
            particle.y = particle.y + particle.speed * dt * 5
            particle.x = particle.x - particle.speed * dt * 2
        elseif self.type == Config.weatherTypes.snow then -- Snow
            particle.y = particle.y + particle.speed * dt * 2
            particle.x = particle.x + math.sin(currentFrame * 2 * math.pi + i) * dt * 10
        elseif self.type == Config.weatherTypes.fog then -- Fog
            particle.x = particle.x + math.sin(currentFrame * 2 * math.pi + i * 0.1) * dt * 5
        end
        
        -- Reset particles that go off-screen
        if particle.y > screenHeight or particle.x < 0 or particle.x > screenWidth then
            particle.y = 0
            particle.x = math.random(1, screenWidth)
        end
    end
end

-- Draw weather effects
function Weather.draw(self, visibleTiles)
    if self.type == Config.weatherTypes.clear then
        return -- No effects for clear weather
    elseif self.type == Config.weatherTypes.rain then
        -- Draw rain
        love.graphics.setColor(0.7, 0.8, 1, 0.7 * self.intensity)
        for _, drop in ipairs(self.particles) do
            love.graphics.line(drop.x, drop.y, drop.x + 2, drop.y + 7)
        end
    elseif self.type == Config.weatherTypes.snow then
        -- Draw snow
        love.graphics.setColor(1, 1, 1, 0.8 * self.intensity)
        for _, flake in ipairs(self.particles) do
            love.graphics.circle("fill", flake.x, flake.y, flake.size * 0.5)
        end
    elseif self.type == Config.weatherTypes.fog then
        -- Draw fog over visible tiles
        for y = 1, self.mapHeight do
            for x = 1, self.mapWidth do
                if visibleTiles[x] and visibleTiles[x][y] then
                    local distFromPlayer = math.sqrt((x - self.mapWidth/2)^2 + (y - self.mapHeight/2)^2)
                    local fogAmount = math.min(1, distFromPlayer / 8) * self.intensity
                    love.graphics.setColor(0.8, 0.8, 0.9, fogAmount * 0.6)
                    love.graphics.rectangle("fill", (x-1) * self.tileSize, (y-1) * self.tileSize, self.tileSize, self.tileSize)
                end
            end
        end
    end
end

return Weather