-- map/Map.lua
-- Map generation and terrain management

local Config = require("config/Config")
local Utils = require("utils/Utils")

local Map = {}
Map.__index = Map

-- Create a new map instance
function Map.new(width, height)
    local self = setmetatable({}, Map)
    
    self.width = width
    self.height = height
    self.tiles = {}
    self.enemySpawnPoints = {}
    
    -- Initialize with floors
    self:initialize()
    
    return self
end

-- Initialize map with floor tiles
function Map.initialize(self)
    for x = 1, self.width do
        self.tiles[x] = {}
        for y = 1, self.height do
            self.tiles[x][y] = Config.terrainTypes.floor
        end
    end
end

-- Generate the complete map
function Map.generate(self)
    -- Clear enemy spawn points
    self.enemySpawnPoints = {}
    
    -- Add outer walls
    self:addBorders()
    
    -- Add biomes
    self:addBiome("forest", Utils.randomInt(10, self.width-10), Utils.randomInt(10, self.height-10), Utils.randomInt(8, 12))
    self:addBiome("mountains", Utils.randomInt(10, self.width-10), Utils.randomInt(10, self.height-10), Utils.randomInt(6, 10))
    self:addBiome("lake", Utils.randomInt(10, self.width-10), Utils.randomInt(10, self.height-10), Utils.randomInt(6, 9))
    self:addBiome("meadow", Utils.randomInt(10, self.width-10), Utils.randomInt(10, self.height-10), Utils.randomInt(7, 11))
    
    -- Generate paths connecting regions
    self:generatePaths(4)
    
    -- Add decorative elements
    self:addDecorativeElements()
    
    -- Generate enemy spawn points throughout the map
    self:generateSpawnPoints()
    
    return self
end

-- Add walls around map edges
function Map.addBorders(self)
    for x = 1, self.width do
        self.tiles[x][1] = Config.terrainTypes.wall
        self.tiles[x][self.height] = Config.terrainTypes.wall
    end
    for y = 1, self.height do
        self.tiles[1][y] = Config.terrainTypes.wall
        self.tiles[self.width][y] = Config.terrainTypes.wall
    end
end

-- Add specific biome (forest, mountain, lake, meadow)
function Map.addBiome(self, biomeType, centerX, centerY, size)
    if biomeType == "forest" then
        -- Create a forest with trees and grass
        for x = centerX - size, centerX + size do
            for y = centerY - size, centerY + size do
                if x > 1 and x < self.width and y > 1 and y < self.height then
                    local distFromCenter = Utils.distance(x, y, centerX, centerY)
                    if distFromCenter <= size then
                        -- Use noise for natural patterns
                        local noise = love.math.noise(x * 0.1, y * 0.1)
                        
                        if noise > 0.7 and math.random() > 0.5 then
                            self.tiles[x][y] = Config.terrainTypes.tree
                        elseif noise > 0.5 then
                            self.tiles[x][y] = Config.terrainTypes.tallGrass
                        elseif noise > 0.3 then
                            self.tiles[x][y] = Config.terrainTypes.grass
                        end
                    end
                end
            end
        end
    elseif biomeType == "mountains" then
        -- Create mountain ranges
        for x = centerX - size, centerX + size do
            for y = centerY - size, centerY + size do
                if x > 1 and x < self.width and y > 1 and y < self.height then
                    local distFromCenter = Utils.distance(x, y, centerX, centerY)
                    if distFromCenter <= size then
                        local noise = love.math.noise(x * 0.1, y * 0.1)
                        
                        if noise > 0.75 then
                            self.tiles[x][y] = Config.terrainTypes.highMountain
                        elseif noise > 0.55 then
                            self.tiles[x][y] = Config.terrainTypes.mountain
                        elseif noise > 0.4 then
                            self.tiles[x][y] = Config.terrainTypes.wall
                        end
                    end
                end
            end
        end
    elseif biomeType == "lake" then
        -- Create lakes with water
        for x = centerX - size, centerX + size do
            for y = centerY - size, centerY + size do
                if x > 1 and x < self.width and y > 1 and y < self.height then
                    local distFromCenter = Utils.distance(x, y, centerX, centerY)
                    if distFromCenter <= size * 0.8 then
                        local noise = love.math.noise(x * 0.15, y * 0.15)
                        
                        if distFromCenter < size * 0.5 or noise > 0.5 then
                            self.tiles[x][y] = Config.terrainTypes.deepWater
                        else
                            self.tiles[x][y] = Config.terrainTypes.water
                        end
                    end
                end
            end
        end
    elseif biomeType == "meadow" then
        -- Create meadows with flowers and grass
        for x = centerX - size, centerX + size do
            for y = centerY - size, centerY + size do
                if x > 1 and x < self.width and y > 1 and y < self.height then
                    local distFromCenter = Utils.distance(x, y, centerX, centerY)
                    if distFromCenter <= size then
                        local noise = love.math.noise(x * 0.2, y * 0.2)
                        
                        if noise > 0.7 and math.random() > 0.6 then
                            self.tiles[x][y] = Config.terrainTypes.flowers
                        elseif noise > 0.5 then
                            self.tiles[x][y] = Config.terrainTypes.tallGrass
                        else
                            self.tiles[x][y] = Config.terrainTypes.grass
                        end
                    end
                end
            end
        end
    end
end

-- Generate paths connecting different regions
function Map.generatePaths(self, count)
    for i = 1, count do
        local x1 = Utils.randomInt(5, self.width-5)
        local y1 = Utils.randomInt(5, self.height-5)
        local x2 = Utils.randomInt(5, self.width-5)
        local y2 = Utils.randomInt(5, self.height-5)
        
        -- Create winding paths between points
        local x, y = x1, y1
        while x ~= x2 or y ~= y2 do
            self.tiles[x][y] = Config.terrainTypes.path
            
            -- Add some path variations
            for dx = -1, 1 do
                for dy = -1, 1 do
                    if math.random() > 0.85 and x+dx > 1 and x+dx < self.width and y+dy > 1 and y+dy < self.height then
                        self.tiles[x+dx][y+dy] = Config.terrainTypes.path
                    end
                end
            end
            
            -- Random movement with bias toward destination
            if math.random() > 0.8 then
                -- Random direction
                local dirs = {{0, 1}, {1, 0}, {0, -1}, {-1, 0}}
                local dir = dirs[math.random(1, 4)]
                x = Utils.clamp(x + dir[1], 1, self.width)
                y = Utils.clamp(y + dir[2], 1, self.height)
            else
                -- Move toward destination
                local dx = x2 - x
                local dy = y2 - y
                
                if math.abs(dx) > math.abs(dy) then
                    x = x + (dx > 0 and 1 or -1)
                else
                    y = y + (dy > 0 and 1 or -1)
                end
            end
        end
    end
end

-- Add special terrain features
function Map.addDecorativeElements(self)
    -- Add special terrain features
    for i = 1, 12 do
        local x = Utils.randomInt(3, self.width-3)
        local y = Utils.randomInt(3, self.height-3)
        
        local element = math.random(1, 5)
        if element == 1 and self.tiles[x][y].walkable then
            self.tiles[x][y] = Config.terrainTypes.altar
        elseif element == 2 and self.tiles[x][y].walkable then
            self.tiles[x][y] = Config.terrainTypes.door
        elseif element == 3 and self.tiles[x][y] == Config.terrainTypes.wall then
            self.tiles[x][y] = Config.terrainTypes.door
        elseif element == 4 and self.tiles[x][y].walkable then
            self.tiles[x][y] = Config.terrainTypes.stairsDown
        elseif element == 5 and self.tiles[x][y].walkable then
            self.tiles[x][y] = Config.terrainTypes.stairsUp
        end
    end
    
    -- Add clusters of flowers in walkable areas
    for i = 1, 6 do
        local cx = Utils.randomInt(5, self.width-5)
        local cy = Utils.randomInt(5, self.height-5)
        
        for dx = -2, 2 do
            for dy = -2, 2 do
                local x, y = cx + dx, cy + dy
                if x > 1 and x < self.width and y > 1 and y < self.height then
                    if self.tiles[x][y].walkable and math.random() > 0.6 then
                        self.tiles[x][y] = Config.terrainTypes.flowers
                    end
                end
            end
        end
    end
end

-- Generates valid spawn points throughout the map
function Map.generateSpawnPoints(self)
    local spawnPointCount = 25 -- Number of spawn points to generate
    local playerX = math.floor(self.width / 2)
    local playerY = math.floor(self.height / 2)
    local minDistFromPlayer = 8 -- Minimum distance from player starting position
    
    for i = 1, spawnPointCount do
        local x, y
        local validSpawnPoint = false
        local attempts = 0
        
        repeat
            attempts = attempts + 1
            x = Utils.randomInt(5, self.width-5)
            y = Utils.randomInt(5, self.height-5)
            local distFromPlayer = Utils.distance(x, y, playerX, playerY)
            
            if self.tiles[x][y].walkable and distFromPlayer > minDistFromPlayer then
                validSpawnPoint = true
            end
        until validSpawnPoint or attempts > 50
        
        if validSpawnPoint then
            table.insert(self.enemySpawnPoints, {x = x, y = y})
            
            -- Visually mark spawn points with subtle environment changes (optional)
            if math.random() < 0.5 and self.tiles[x][y] == Config.terrainTypes.floor then
                self.tiles[x][y] = Config.terrainTypes.path -- Subtle marker for spawn points
            end
        end
    end
end

-- Make an area walkable (used for player spawn area)
function Map.makeAreaWalkable(self, centerX, centerY, radius)
    for x = centerX - radius, centerX + radius do
        for y = centerY - radius, centerY + radius do
            if x > 0 and x <= self.width and y > 0 and y <= self.height then
                if not self.tiles[x][y].walkable then
                    self.tiles[x][y] = Config.terrainTypes.floor
                end
            end
        end
    end
end

-- Get tile at position
function Map.getTileAt(self, x, y)
    if x < 1 or x > self.width or y < 1 or y > self.height then
        return nil
    end
    return self.tiles[x][y]
end

-- Check if tile is walkable
function Map.isWalkable(self, x, y)
    local tile = self:getTileAt(x, y)
    return tile and tile.walkable
end

-- Get a random spawn point
function Map.getRandomSpawnPoint(self)
    if #self.enemySpawnPoints == 0 then
        return nil
    end
    return self.enemySpawnPoints[math.random(#self.enemySpawnPoints)]
end

-- Draw the map
function Map.draw(self, visibleTiles, exploredTiles, currentFrame)
    local tileSize = Config.tileSize
    love.graphics.setColor(1, 1, 1)
    
    for x = 1, self.width do
        for y = 1, self.height do
            local terrain = self.tiles[x][y]
            
            -- Determine tile visibility and appearance
            if visibleTiles[x] and visibleTiles[x][y] then
                -- Currently visible tiles
                local brightness = type(visibleTiles[x][y]) == "boolean" and 1.0 or visibleTiles[x][y]
                -- Clamp brightness to avoid too bright colors
                local r = math.min(1.0, terrain.color[1] * brightness)
                local g = math.min(1.0, terrain.color[2] * brightness)
                local b = math.min(1.0, terrain.color[3] * brightness)
                
                love.graphics.setColor(r, g, b)
                
                -- Add animation for certain terrain types
                if terrain.animated then
                    if terrain == Config.terrainTypes.water or terrain == Config.terrainTypes.deepWater then
                        -- Wave animation for water
                        local waveOffset = math.sin((currentFrame + x * 0.1 + y * 0.1) * 2 * math.pi) * 2
                        love.graphics.print(terrain.char, (x-1) * tileSize, (y-1) * tileSize + waveOffset)
                    elseif terrain == Config.terrainTypes.grass or terrain == Config.terrainTypes.tallGrass then
                        -- Subtle swaying for grass
                        local swayOffset = math.sin((currentFrame + x * 0.05) * 2 * math.pi) * 1
                        love.graphics.print(terrain.char, (x-1) * tileSize + swayOffset, (y-1) * tileSize)
                    elseif terrain == Config.terrainTypes.flowers then
                        -- Pulsing for flowers
                        local scale = 1.0 + math.sin(currentFrame * 2 * math.pi) * 0.1
                        local flowerOffset = math.sin((currentFrame + x * 0.1) * 2 * math.pi) * 1
                        love.graphics.print(terrain.char, (x-1) * tileSize + flowerOffset, (y-1) * tileSize)
                    elseif terrain == Config.terrainTypes.tree then
                        -- Subtle swaying for trees
                        local treeOffset = math.sin((currentFrame + x * 0.03) * 2 * math.pi) * 1.5
                        love.graphics.print(terrain.char, (x-1) * tileSize + treeOffset, (y-1) * tileSize)
                    else
                        love.graphics.print(terrain.char, (x-1) * tileSize, (y-1) * tileSize)
                    end
                else
                    love.graphics.print(terrain.char, (x-1) * tileSize, (y-1) * tileSize)
                end
            elseif exploredTiles[x] and exploredTiles[x][y] then
                -- Previously explored but not currently visible
                love.graphics.setColor(
                    terrain.color[1] * 0.8,  -- Significantly increased brightness for explored tiles
                    terrain.color[2] * 0.8,
                    terrain.color[3] * 0.8
                )
                love.graphics.print(terrain.char, (x-1) * tileSize, (y-1) * tileSize)
            else
                -- Unexplored
                love.graphics.setColor(0.15, 0.15, 0.25)  -- Much brighter unexplored areas
                love.graphics.print(" ", (x-1) * tileSize, (y-1) * tileSize)
            end
        end
    end
    
    -- Draw FOV border effect
    for x = 1, self.width do
        for y = 1, self.height do
            if visibleTiles[x] and visibleTiles[x][y] then
                -- Check if any adjacent tiles are not visible
                for dx = -1, 1 do
                    for dy = -1, 1 do
                        local nx, ny = x + dx, y + dy
                        if nx > 0 and nx <= self.width and ny > 0 and ny <= self.height then
                            if not (visibleTiles[nx] and visibleTiles[nx][ny]) and
                               (dx ~= 0 or dy ~= 0) then -- Don't shade the tile itself
                                love.graphics.setColor(0, 0, 0, 0.15)  -- Further reduced shadow opacity
                                love.graphics.rectangle("fill", 
                                    (x-1) * tileSize + dx * (tileSize/2), 
                                    (y-1) * tileSize + dy * (tileSize/2), 
                                    tileSize/2, tileSize/2)
                            end
                        end
                    end
                end
            end
        end
    end
end

return Map