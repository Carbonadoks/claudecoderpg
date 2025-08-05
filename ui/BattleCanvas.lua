-- ui/BattleCanvas.lua
-- Enhanced battle canvas with animated backgrounds and effects

local UI = require("ui/UI")
local Config = require("config/Config")
local Utils = require("utils.Utils")

local BattleCanvas = setmetatable({}, {__index = UI})
BattleCanvas.__index = BattleCanvas

-- Create a new battle canvas
function BattleCanvas.new()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local self = setmetatable(UI.new(0, 0, screenWidth, screenHeight), BattleCanvas)
    
    self.time = 0
    self.effects = {}
    self.backgroundType = "default"
    self.particles = love.graphics.newParticleSystem(love.graphics.newCanvas(5, 5), 100)
    self:initParticles()
    
    -- Available background types
    self.backgroundTypes = {
        "default", -- Dynamic battle noise
        "forest",  -- Forest environment
        "cave",    -- Cave environment
        "plains",  -- Open plains
        "mountains" -- Mountain environment
    }
    
    return self
end

-- Initialize particle system
function BattleCanvas.initParticles(self)
    self.particles:setParticleLifetime(1, 3)
    self.particles:setEmissionRate(20)
    self.particles:setSizeVariation(0.5)
    self.particles:setLinearAcceleration(-20, -20, 20, 20)
    self.particles:setColors(
        1, 1, 1, 0.6,  -- Start color (white with alpha)
        1, 1, 1, 0     -- End color (transparent)
    )
    self.particles:setSizes(2, 1)
end

-- Update the battle canvas
function BattleCanvas.update(self, dt)
    self.time = self.time + dt
    self.particles:update(dt)
    
    -- Update active effects
    for i = #self.effects, 1, -1 do
        local effect = self.effects[i]
        effect.time = effect.time + dt
        
        if effect.time >= effect.duration then
            table.remove(self.effects, i)
        end
    end
end

-- Draw the battle canvas
function BattleCanvas.draw(self)
    local screenWidth = self.width
    local screenHeight = self.height
    
    -- Draw background based on type
    self:drawBackground(screenWidth, screenHeight)
    
    -- Draw active effects
    for _, effect in ipairs(self.effects) do
        self:drawEffect(effect)
    end
    
    -- Draw particles
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.draw(self.particles)
end

-- Draw the background
function BattleCanvas.drawBackground(self, screenWidth, screenHeight)
    if self.backgroundType == "default" then
        self:drawDefaultBackground(screenWidth, screenHeight)
    elseif self.backgroundType == "forest" then
        self:drawForestBackground(screenWidth, screenHeight)
    elseif self.backgroundType == "cave" then
        self:drawCaveBackground(screenWidth, screenHeight)
    elseif self.backgroundType == "plains" then
        self:drawPlainsBackground(screenWidth, screenHeight)
    elseif self.backgroundType == "mountains" then
        self:drawMountainsBackground(screenWidth, screenHeight)
    end
end

-- Draw default dynamic background with noise
function BattleCanvas.drawDefaultBackground(self, screenWidth, screenHeight)
    local tileSize = 20
    local currentTime = self.time
    
    -- Draw a dynamic battle background with noise patterns
    for y = 0, screenHeight, tileSize do
        for x = 0, screenWidth, tileSize do
            local noise = love.math.noise(x * 0.01, y * 0.01, currentTime * 0.5)
            love.graphics.setColor(0.1 + noise * 0.1, 0.1 + noise * 0.05, 0.2 + noise * 0.1)
            love.graphics.rectangle("fill", x, y, tileSize, tileSize)
        end
    end
    
    -- Draw dynamic effects
    for i = 1, 12 do
        local x = (screenWidth/2) + math.cos(currentTime * 2 + i) * screenWidth * 0.4
        local y = screenHeight * 0.7 + math.sin(currentTime * 3 + i) * screenHeight * 0.2
        local size = 5 + math.sin(currentTime * 4 + i) * 10
        
        love.graphics.setColor(0.8, 0.4, 0.1, 0.2)
        love.graphics.circle("fill", x, y, size)
    end
end

-- Draw forest background
function BattleCanvas.drawForestBackground(self, screenWidth, screenHeight)
    -- Sky gradient
    local gradient = {
        {0, 0.3, 0.5},     -- Top color
        {0.1, 0.4, 0.3}    -- Bottom color
    }
    
    for i = 0, screenHeight do
        local ratio = i / screenHeight
        local r = Utils.lerp(gradient[1][1], gradient[2][1], ratio)
        local g = Utils.lerp(gradient[1][2], gradient[2][2], ratio)
        local b = Utils.lerp(gradient[1][3], gradient[2][3], ratio)
        
        love.graphics.setColor(r, g, b)
        love.graphics.line(0, i, screenWidth, i)
    end
    
    -- Draw trees
    for i = 1, 20 do
        local x = (i * screenWidth / 20) - screenWidth / 40 + math.sin(self.time + i) * 5
        local height = screenHeight * 0.6 + math.sin(i * 7) * 50
        local width = 20 + math.sin(i * 3) * 5
        
        -- Tree trunk
        love.graphics.setColor(0.3, 0.2, 0.1)
        love.graphics.rectangle("fill", x - width/4, screenHeight - height/2, width/2, height/2)
        
        -- Tree foliage
        love.graphics.setColor(0.1, 0.3, 0.1)
        love.graphics.circle("fill", x, screenHeight - height, width)
    end
    
    -- Ground
    love.graphics.setColor(0.2, 0.3, 0.1)
    love.graphics.rectangle("fill", 0, screenHeight - 40, screenWidth, 40)
end

-- Draw cave background
function BattleCanvas.drawCaveBackground(self, screenWidth, screenHeight)
    -- Dark cave wall
    love.graphics.setColor(0.2, 0.15, 0.1)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Cave details with noise
    for y = 0, screenHeight, 15 do
        for x = 0, screenWidth, 15 do
            local noise = love.math.noise(x * 0.05, y * 0.05, self.time * 0.1)
            
            if noise > 0.7 then
                love.graphics.setColor(0.3, 0.25, 0.2, noise - 0.6)
                love.graphics.rectangle("fill", x, y, 15, 15)
            end
            
            if noise < 0.3 then
                love.graphics.setColor(0.1, 0.05, 0.05, 0.3 - noise)
                love.graphics.rectangle("fill", x, y, 15, 15)
            end
        end
    end
    
    -- Draw stalagmites and stalactites
    for i = 1, 10 do
        local x = screenWidth * i / 10 - screenWidth / 20
        
        -- Stalagmite (from bottom)
        local height1 = screenHeight * 0.2 + math.sin(i * 3) * 30
        love.graphics.setColor(0.25, 0.2, 0.15)
        love.graphics.polygon("fill", 
            x - 15, screenHeight,
            x + 15, screenHeight,
            x, screenHeight - height1
        )
        
        -- Stalactite (from top)
        local height2 = screenHeight * 0.15 + math.cos(i * 5) * 20
        love.graphics.setColor(0.25, 0.2, 0.15)
        love.graphics.polygon("fill",
            x - 10, 0,
            x + 10, 0,
            x, height2
        )
    end
end

-- Draw plains background
function BattleCanvas.drawPlainsBackground(self, screenWidth, screenHeight)
    -- Sky gradient
    local gradient = {
        {0.4, 0.7, 0.9},   -- Top color
        {0.6, 0.8, 0.9}    -- Bottom color (horizon)
    }
    
    for i = 0, screenHeight * 0.7 do
        local ratio = i / (screenHeight * 0.7)
        local r = Utils.lerp(gradient[1][1], gradient[2][1], ratio)
        local g = Utils.lerp(gradient[1][2], gradient[2][2], ratio)
        local b = Utils.lerp(gradient[1][3], gradient[2][3], ratio)
        
        love.graphics.setColor(r, g, b)
        love.graphics.line(0, i, screenWidth, i)
    end
    
    -- Ground
    love.graphics.setColor(0.6, 0.8, 0.3)
    love.graphics.rectangle("fill", 0, screenHeight * 0.7, screenWidth, screenHeight * 0.3)
    
    -- Grass
    for i = 1, 100 do
        local x = math.random() * screenWidth
        local height = 5 + math.random() * 10
        love.graphics.setColor(0.3, 0.7, 0.2)
        love.graphics.line(x, screenHeight * 0.7, x, screenHeight * 0.7 - height)
    end
    
    -- Clouds
    for i = 1, 5 do
        local x = (self.time * 10 + i * 100) % (screenWidth + 200) - 100
        local y = 50 + i * 30
        local size = 30 + i * 10
        
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.circle("fill", x, y, size)
        love.graphics.circle("fill", x + size * 0.7, y, size * 0.7)
        love.graphics.circle("fill", x - size * 0.7, y, size * 0.7)
    end
end

-- Draw mountains background
function BattleCanvas.drawMountainsBackground(self, screenWidth, screenHeight)
    -- Sky gradient
    local gradient = {
        {0.2, 0.3, 0.5},   -- Top color (darker)
        {0.5, 0.6, 0.7}    -- Bottom color (horizon)
    }
    
    for i = 0, screenHeight * 0.6 do
        local ratio = i / (screenHeight * 0.6)
        local r = Utils.lerp(gradient[1][1], gradient[2][1], ratio)
        local g = Utils.lerp(gradient[1][2], gradient[2][2], ratio)
        local b = Utils.lerp(gradient[1][3], gradient[2][3], ratio)
        
        love.graphics.setColor(r, g, b)
        love.graphics.line(0, i, screenWidth, i)
    end
    
    -- Far mountains
    love.graphics.setColor(0.3, 0.35, 0.4)
    for i = 0, 5 do
        local x1 = i * screenWidth / 5 - 50
        local x2 = (i + 1) * screenWidth / 5 + 50
        local peak = math.random() * screenHeight * 0.2 + screenHeight * 0.2
        
        love.graphics.polygon("fill",
            x1, screenHeight * 0.6,
            x2, screenHeight * 0.6,
            (x1 + x2) / 2, peak
        )
    end
    
    -- Closer mountains
    love.graphics.setColor(0.25, 0.3, 0.35)
    for i = 0, 3 do
        local x1 = i * screenWidth / 3 - 100
        local x2 = (i + 1) * screenWidth / 3 + 100
        local peak = math.random() * screenHeight * 0.15 + screenHeight * 0.3
        
        love.graphics.polygon("fill",
            x1, screenHeight * 0.6,
            x2, screenHeight * 0.6,
            (x1 + x2) / 2, peak
        )
    end
    
    -- Ground
    love.graphics.setColor(0.5, 0.4, 0.3)
    love.graphics.rectangle("fill", 0, screenHeight * 0.6, screenWidth, screenHeight * 0.4)
    
    -- Rocks
    for i = 1, 15 do
        local x = math.random() * screenWidth
        local y = screenHeight * 0.6 + math.random() * screenHeight * 0.2
        local size = 5 + math.random() * 15
        
        love.graphics.setColor(0.4, 0.35, 0.3)
        love.graphics.circle("fill", x, y, size)
    end
end

-- Add a visual effect
function BattleCanvas.addEffect(self, effectType, x, y, options)
    options = options or {}
    
    local effect = {
        type = effectType,
        x = x,
        y = y,
        time = 0,
        duration = options.duration or 1.0,
        size = options.size or 30,
        color = options.color or {1, 1, 0, 0.8},
        options = options
    }
    
    table.insert(self.effects, effect)
    
    -- Emit particles at effect location
    self.particles:setPosition(x, y)
    self.particles:emit(10)
    
    return effect
end

-- Draw a visual effect
function BattleCanvas.drawEffect(self, effect)
    if effect.type == "slash" then
        self:drawSlashEffect(effect)
    elseif effect.type == "impact" then
        self:drawImpactEffect(effect)
    elseif effect.type == "heal" then
        self:drawHealEffect(effect)
    elseif effect.type == "magic" then
        self:drawMagicEffect(effect)
    end
end

-- Draw a slash effect
function BattleCanvas.drawSlashEffect(self, effect)
    local progress = effect.time / effect.duration
    local alpha = 1 - progress
    local size = effect.size * (1 + progress)
    
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], alpha)
    
    -- Draw slash lines
    local angle = effect.options.angle or (math.pi / 4)
    local width = effect.options.width or 3
    
    for i = 1, 3 do
        local offset = (i - 2) * (size / 5)
        local x1 = effect.x - math.cos(angle) * size + offset
        local y1 = effect.y - math.sin(angle) * size
        local x2 = effect.x + math.cos(angle) * size + offset
        local y2 = effect.y + math.sin(angle) * size
        
        love.graphics.setLineWidth(width)
        love.graphics.line(x1, y1, x2, y2)
    end
    
    love.graphics.setLineWidth(1)
end

-- Draw an impact effect
function BattleCanvas.drawImpactEffect(self, effect)
    local progress = effect.time / effect.duration
    local alpha = 1 - progress
    local size = effect.size * (1 + progress * 2)
    
    -- Draw impact circle
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], alpha * 0.5)
    love.graphics.circle("fill", effect.x, effect.y, size)
    
    -- Draw impact lines
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], alpha)
    for i = 1, 8 do
        local angle = i * math.pi / 4
        local x1 = effect.x + math.cos(angle) * size * 0.3
        local y1 = effect.y + math.sin(angle) * size * 0.3
        local x2 = effect.x + math.cos(angle) * size
        local y2 = effect.y + math.sin(angle) * size
        
        love.graphics.line(x1, y1, x2, y2)
    end
end

-- Draw a heal effect
function BattleCanvas.drawHealEffect(self, effect)
    local progress = effect.time / effect.duration
    local alpha = 1 - progress
    local size = effect.size * (1 - progress * 0.5)
    
    -- Draw healing particles
    for i = 1, 6 do
        local angle = i * math.pi / 3 + self.time * 2
        local distance = size * (0.5 + progress * 0.5)
        local x = effect.x + math.cos(angle) * distance
        local y = effect.y + math.sin(angle) * distance
        
        love.graphics.setColor(0.2, 0.8, 0.3, alpha)
        love.graphics.circle("fill", x, y, 4)
    end
    
    -- Draw central glow
    love.graphics.setColor(0.2, 0.8, 0.3, alpha * 0.5)
    love.graphics.circle("fill", effect.x, effect.y, size * 0.7)
end

-- Draw a magic effect
function BattleCanvas.drawMagicEffect(self, effect)
    local progress = effect.time / effect.duration
    local alpha = 1 - progress
    local size = effect.size
    
    -- Draw magic circle
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], alpha * 0.3)
    love.graphics.circle("fill", effect.x, effect.y, size)
    
    -- Draw rotating magic runes
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], alpha)
    for i = 1, 5 do
        local angle = i * math.pi * 2 / 5 + self.time * 3
        local x = effect.x + math.cos(angle) * size * 0.8
        local y = effect.y + math.sin(angle) * size * 0.8
        
        -- Small glowing rune
        love.graphics.circle("fill", x, y, 3)
    end
    
    -- Inner circle
    love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], alpha * 0.5)
    love.graphics.circle("line", effect.x, effect.y, size * 0.6)
    love.graphics.circle("line", effect.x, effect.y, size * 0.9)
end

-- Set the background type
function BattleCanvas.setBackgroundType(self, bgType)
    if not bgType then
        -- Randomly select a background if none specified
        bgType = self.backgroundTypes[math.random(#self.backgroundTypes)]
    end
    
    self.backgroundType = bgType
end

return BattleCanvas