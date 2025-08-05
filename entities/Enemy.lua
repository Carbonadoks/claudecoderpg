-- entities/Enemy.lua
-- Enemy entity implementation

local Entity = require("entities/Entity")
local Config = require("config/Config")
local Utils = require("utils/Utils")

local Enemy = setmetatable({}, {__index = Entity})
Enemy.__index = Enemy

-- Create a new enemy
function Enemy.new(x, y, enemyType)
    local self = setmetatable(Entity.new(x, y, enemyType.char, Config.colors.enemy), Enemy)
    
    -- Copy properties from enemyType
    self.name = enemyType.name
    self.hp = enemyType.hp
    self.maxHp = enemyType.hp
    self.attack = enemyType.attack
    self.defense = enemyType.defense
    self.speed = enemyType.speed
    self.xp = enemyType.xp
    
    -- Spawning animation
    self.isSpawning = true
    self.spawnProgress = 0
    
    return self
end

-- Update enemy state
function Enemy.update(self, dt, currentFrame)
    -- Animate the enemy with a subtle movement effect
    self.animationOffset = math.sin((currentFrame + self.x * 0.1) * 2 * math.pi) * 2
    
    -- Update spawn animation
    if self.isSpawning then
        self.spawnProgress = self.spawnProgress + dt * 2 -- Complete in 0.5 seconds
        if self.spawnProgress >= 1 then
            self.isSpawning = false
            self.spawnProgress = 1
        end
    end
end

-- Draw the enemy
function Enemy.draw(self, tileSize, currentFrame, visibleTiles)
    if visibleTiles[self.x] and visibleTiles[self.x][self.y] then
        if self.isSpawning then
            -- Spawn animation effect - fade in and grow
            local scale = self.spawnProgress
            local alpha = self.spawnProgress
            
            -- Glow behind the character
            love.graphics.setColor(1, 0.5, 0.2, alpha * 0.5)
            love.graphics.circle("fill", (self.x-0.5) * tileSize, (self.y-0.5) * tileSize, 
                                tileSize * 0.6 * scale)
                                
            -- The character itself
            love.graphics.setColor(self.color[1], self.color[2], self.color[3], alpha)
            -- Make sure fontSize is at least 1 to avoid font creation error
            local fontSize = math.max(1, love.graphics.getFont():getHeight() * scale)
            local tempFont = love.graphics.newFont(Config.fontPath, fontSize)
            love.graphics.setFont(tempFont)
            love.graphics.print(self.char, 
                (self.x-1) * tileSize + tileSize * (1-scale)/2, 
                (self.y-1) * tileSize + tileSize * (1-scale)/2 + self.animationOffset)
            love.graphics.setFont(love.graphics.getFont()) -- Restore default font
        else
            -- Normal enemy display
            love.graphics.setColor(self.color)
            love.graphics.print(self.char, (self.x-1) * tileSize, (self.y-1) * tileSize + self.animationOffset)
        end
    end
end

-- Draw enemy in combat
function Enemy.drawInCombat(self, x, y, attackTimer)
    local charSize = 32
    
    -- Add shaking when about to attack
    local shake = 0
    if attackTimer > 0.8 then
        shake = math.random(-3, 3)
    end
    
    -- Add visual feedback for attacks
    local size = 1.0
    if attackTimer < 0.2 then
        size = 1.2 -- "Pop" effect right after attacking
    end
    
    -- Draw the enemy character
    love.graphics.setFont(love.graphics.newFont(Config.fontPath, charSize * size))
    love.graphics.setColor(self.color)
    love.graphics.printf(self.char, x - charSize + shake, y - charSize/2 + shake, charSize * 2, "center")
    
    -- Draw name and stats
    love.graphics.setColor(Config.colors.text)
    love.graphics.printf(self.name, x - 100, y - 60, 200, "center")
    
    -- HP bar
    local barWidth = 100
    local hpRatio = self.hp / self.maxHp
    
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", x - barWidth/2, y + 30, barWidth, 10)
    love.graphics.setColor(Config.colors.health)
    love.graphics.rectangle("fill", x - barWidth/2, y + 30, barWidth * hpRatio, 10)
    
    -- HP text
    love.graphics.setColor(Config.colors.text)
    love.graphics.printf(self.hp .. "/" .. self.maxHp, x - 50, y + 45, 100, "center")
    
    -- Combat stats
    love.graphics.printf("ATK: " .. self.attack .. "   DEF: " .. self.defense, x - 100, y + 65, 200, "center")
    
    -- Draw attack effects
    if attackTimer < 0.3 then -- Just attacked
        for i = 1, 5 do
            local angle = math.random() * math.pi * 2
            local dist = math.random(20, 40)
            local px = x + math.cos(angle) * dist
            local py = y + math.sin(angle) * dist
            love.graphics.setColor(1, 1, 0, 1 - attackTimer/0.3)
            love.graphics.circle("fill", px, py, 2)
        end
    end
end

-- Create spawn effect at location
function Enemy.createSpawnEffect(self)
    return {
        x = self.x,
        y = self.y,
        timer = 0,
        duration = 1.0
    }
end

-- Draw spawn effects
function Enemy.drawSpawnEffect(effect, tileSize, visibleTiles)
    if visibleTiles[effect.x] and visibleTiles[effect.x][effect.y] then
        -- Calculate effect progress (0 to 1)
        local progress = effect.timer / effect.duration
        
        -- Draw expanding circle
        local radius = (1 - progress) * tileSize * 2
        local alpha = (1 - progress) * 0.8
        
        love.graphics.setColor(1, 0.2, 0.2, alpha)
        love.graphics.circle("fill", (effect.x-0.5) * tileSize, (effect.y-0.5) * tileSize, radius)
        
        -- Draw pulsing glow
        love.graphics.setColor(1, 0.5, 0.1, alpha * 0.6)
        love.graphics.circle("line", (effect.x-0.5) * tileSize, (effect.y-0.5) * tileSize, radius * 1.2)
    end
end

return Enemy