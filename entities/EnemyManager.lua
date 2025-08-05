-- entities/EnemyManager.lua
-- Manages enemy spawning and tracking

local Enemy = require("entities/Enemy")
local Config = require("config/Config")
local Utils = require("utils/Utils")

local EnemyManager = {}
EnemyManager.__index = EnemyManager

-- Create a new enemy manager
function EnemyManager.new(map)
    local self = setmetatable({}, EnemyManager)
    
    self.map = map
    self.enemies = {}
    self.spawnEffects = {}
    
    -- Spawning configuration
    self.spawning = {
        enabled = Config.enemySpawning.enabled,
        timer = 0,
        interval = Config.enemySpawning.interval,
        chance = Config.enemySpawning.chance,
        maxEnemies = Config.enemySpawning.maxEnemies
    }
    
    return self
end

-- Update enemy system
function EnemyManager.update(self, dt, currentFrame, player)
    -- Update existing enemies
    for _, enemy in ipairs(self.enemies) do
        enemy:update(dt, currentFrame)
    end
    
    -- Update spawn effects
    for i = #self.spawnEffects, 1, -1 do
        local effect = self.spawnEffects[i]
        effect.timer = effect.timer + dt
        
        -- Remove completed effects
        if effect.timer >= effect.duration then
            table.remove(self.spawnEffects, i)
        end
    end
    
    -- Only process spawning if enabled and not at max capacity
    if not self.spawning.enabled then
        return
    end
    
    -- Update spawn timer
    self.spawning.timer = self.spawning.timer + dt
    
    -- Check if it's time to attempt spawning
    if self.spawning.timer >= self.spawning.interval then
        self.spawning.timer = 0 -- Reset timer
        
        -- Only spawn if below max and probability check passes
        if #self.enemies < self.spawning.maxEnemies and math.random() < self.spawning.chance then
            -- Determine number of enemies to spawn (1-3)
            local count = math.random(1, 3)
            
            -- Try to spawn using designated spawn points, pass player position if available
            local playerX, playerY = 1, 1  -- Default position
            if player then
                playerX, playerY = player.x, player.y
            end
            self:generateEnemies(count, true, playerX, playerY)
        end
    end
end

-- Generate enemies
function EnemyManager.generateEnemies(self, count, useSpawnPoints, playerX, playerY)
    -- Check if we've reached the max enemy limit
    if #self.enemies >= self.spawning.maxEnemies then
        return 0 -- No enemies spawned
    end
    
    local spawnedCount = 0
    -- Use provided player position or default to origin
    playerX = playerX or 1
    playerY = playerY or 1
    
    for i = 1, count do
        -- Don't exceed the maximum
        if #self.enemies >= self.spawning.maxEnemies then
            break
        end
        
        local x, y
        
        if useSpawnPoints then
            -- Use a spawn point from loaded chunks
            local spawnPoint = self.map:getRandomSpawnPoint()
            if not spawnPoint then
                -- No spawn points available, use random position near player
                useSpawnPoints = false
            else
                x, y = spawnPoint.x, spawnPoint.y
                
                -- Check if the spawn point is valid (might have been occupied since generation)
                if not self.map:isWalkable(x, y) or self:isEnemyAt(x, y) then
                    -- Find a nearby valid position
                    local found = false
                    for dx = -2, 2 do
                        for dy = -2, 2 do
                            local nx, ny = x + dx, y + dy
                            if self.map:isWalkable(nx, ny) and not self:isEnemyAt(nx, ny) then
                                x, y = nx, ny
                                found = true
                                break
                            end
                        end
                        if found then break end
                    end
                    
                    if not found then
                        -- If no valid position found near spawn point, use random position
                        useSpawnPoints = false
                    end
                end
            end
        end
        
        if not useSpawnPoints then
            -- Get a random position near the player (within reasonable distance)
            local maxAttempts = 50
            local attempt = 0
            repeat
                attempt = attempt + 1
                -- Spawn within a reasonable range around player (10-20 tiles away)
                local angle = math.random() * 2 * math.pi
                local distance = math.random(10, 20)
                x = math.floor(playerX + math.cos(angle) * distance)
                y = math.floor(playerY + math.sin(angle) * distance)
            until (self.map:isWalkable(x, y) and not self:isEnemyAt(x, y)) or attempt >= maxAttempts
            
            -- If we couldn't find a good spot, try closer to player
            if attempt >= maxAttempts then
                repeat
                    local dx = math.random(-5, 5)
                    local dy = math.random(-5, 5)
                    x = playerX + dx
                    y = playerY + dy
                until self.map:isWalkable(x, y) and not self:isEnemyAt(x, y)
            end
        end
        
        -- Create the enemy
        local enemyType = Config.enemyTypes[math.random(#Config.enemyTypes)]
        local enemy = Enemy.new(x, y, enemyType)
        
        table.insert(self.enemies, enemy)
        
        -- Add spawn effect
        table.insert(self.spawnEffects, enemy:createSpawnEffect())
        
        spawnedCount = spawnedCount + 1
    end
    
    return spawnedCount
end

-- Check if an enemy is at the specified position
function EnemyManager.isEnemyAt(self, x, y)
    for _, enemy in ipairs(self.enemies) do
        if enemy.x == x and enemy.y == y then
            return true
        end
    end
    return false
end

-- Get enemy at the specified position
function EnemyManager.getEnemyAt(self, x, y)
    for i, enemy in ipairs(self.enemies) do
        if enemy.x == x and enemy.y == y then
            return enemy, i
        end
    end
    return nil
end

-- Remove enemy at specified index
function EnemyManager.removeEnemy(self, index)
    table.remove(self.enemies, index)
end

-- Draw all enemies
function EnemyManager.draw(self, tileSize, currentFrame, visibleTiles)
    -- Draw spawn effects first
    for _, effect in ipairs(self.spawnEffects) do
        Enemy.drawSpawnEffect(effect, tileSize, visibleTiles)
    end
    
    -- Then draw the enemies
    for _, enemy in ipairs(self.enemies) do
        enemy:draw(tileSize, currentFrame, visibleTiles)
    end
end

-- Enable or disable enemy spawning
function EnemyManager.setSpawningEnabled(self, enabled)
    self.spawning.enabled = enabled
    return "Enemy spawning " .. (enabled and "enabled" or "disabled")
end

-- Force spawn enemies
function EnemyManager.forceSpawn(self, count, playerX, playerY)
    if self.spawning.enabled and #self.enemies < self.spawning.maxEnemies then
        local spawnedCount = self:generateEnemies(count or math.random(1, 2), true, playerX, playerY)
        return spawnedCount .. " new " .. (spawnedCount == 1 and "enemy" or "enemies") .. " appeared!"
    else
        return "Cannot spawn more enemies (limit reached or spawning disabled)"
    end
end

return EnemyManager