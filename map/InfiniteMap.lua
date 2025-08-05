-- map/InfiniteMap.lua
-- Infinite procedural world generation using chunks

local Config = require("config/Config")
local Utils = require("utils/Utils")

local InfiniteMap = {}
InfiniteMap.__index = InfiniteMap

-- Chunk size (in tiles)
local CHUNK_SIZE = 32
local CHUNK_LOAD_RADIUS = 2  -- Load chunks within this radius of player
local MAX_LOADED_CHUNKS = 50  -- Memory management

-- Create a new infinite map
function InfiniteMap.new()
    local self = setmetatable({}, InfiniteMap)
    
    self.chunks = {}  -- Loaded chunks [chunkX][chunkY] = chunk
    self.loadedChunkList = {}  -- For memory management
    self.biomeSeeds = {}  -- Seeds for consistent biome placement
    self.worldSeed = love.math.random(1000000)
    
    -- Use world seed for consistent generation
    love.math.setRandomSeed(self.worldSeed)
    
    return self
end

-- Convert world coordinates to chunk coordinates
function InfiniteMap.worldToChunk(self, worldX, worldY)
    return math.floor((worldX - 1) / CHUNK_SIZE), math.floor((worldY - 1) / CHUNK_SIZE)
end

-- Convert chunk coordinates to world coordinates (top-left of chunk)
function InfiniteMap.chunkToWorld(self, chunkX, chunkY)
    return chunkX * CHUNK_SIZE + 1, chunkY * CHUNK_SIZE + 1
end

-- Get local coordinates within a chunk
function InfiniteMap.worldToLocal(self, worldX, worldY)
    local chunkX, chunkY = self:worldToChunk(worldX, worldY)
    local worldChunkX, worldChunkY = self:chunkToWorld(chunkX, chunkY)
    return worldX - worldChunkX + 1, worldY - worldChunkY + 1
end

-- Get or generate a chunk
function InfiniteMap.getChunk(self, chunkX, chunkY)
    if not self.chunks[chunkX] then
        self.chunks[chunkX] = {}
    end
    
    if not self.chunks[chunkX][chunkY] then
        self.chunks[chunkX][chunkY] = self:generateChunk(chunkX, chunkY)
        table.insert(self.loadedChunkList, {x = chunkX, y = chunkY})
        
        -- Memory management - unload distant chunks
        if #self.loadedChunkList > MAX_LOADED_CHUNKS then
            local oldChunk = table.remove(self.loadedChunkList, 1)
            if self.chunks[oldChunk.x] then
                self.chunks[oldChunk.x][oldChunk.y] = nil
            end
        end
    end
    
    return self.chunks[chunkX][chunkY]
end

-- Generate a single chunk
function InfiniteMap.generateChunk(self, chunkX, chunkY)
    -- Use chunk coordinates as seed for consistent generation
    local chunkSeed = chunkX * 10000 + chunkY + self.worldSeed
    love.math.setRandomSeed(chunkSeed)
    
    local chunk = {
        x = chunkX,
        y = chunkY,
        tiles = {},
        enemySpawnPoints = {},
        enemies = {}  -- Store enemies generated in this chunk
    }
    
    -- Initialize with base terrain
    for x = 1, CHUNK_SIZE do
        chunk.tiles[x] = {}
        for y = 1, CHUNK_SIZE do
            chunk.tiles[x][y] = Config.terrainTypes.floor
        end
    end
    
    -- Determine biome for this chunk based on position
    local biome = self:getBiomeForChunk(chunkX, chunkY)
    
    -- Generate terrain based on biome
    self:generateChunkTerrain(chunk, biome, chunkX, chunkY)
    
    -- Ensure connectivity by adding paths
    self:ensureChunkConnectivity(chunk, chunkX, chunkY)
    
    -- Add decorative elements
    self:addChunkDecorations(chunk, biome)
    
    -- Generate spawn points
    self:generateChunkSpawnPoints(chunk)
    
    -- Generate enemies in chunk
    self:generateChunkEnemies(chunk, biome)
    
    -- Restore random seed
    love.math.setRandomSeed(os.time())
    
    return chunk
end

-- Determine biome for chunk based on world position
function InfiniteMap.getBiomeForChunk(self, chunkX, chunkY)
    -- Use noise to create biome regions
    local biomeNoise = love.math.noise(chunkX * 0.1, chunkY * 0.1, 100)
    local tempNoise = love.math.noise(chunkX * 0.05, chunkY * 0.05, 200)
    local humidNoise = love.math.noise(chunkX * 0.08, chunkY * 0.08, 300)
    
    -- Combine noise values to determine biome
    local biomeValue = biomeNoise + tempNoise * 0.5 + humidNoise * 0.3
    
    if biomeValue > 0.7 then
        return "mountains"
    elseif biomeValue > 0.4 then
        return "forest"
    elseif biomeValue > 0.1 then
        return "meadow"
    elseif biomeValue > -0.2 then
        return "plains"
    else
        return "lake"
    end
end

-- Generate terrain for a chunk based on its biome
function InfiniteMap.generateChunkTerrain(self, chunk, biome, chunkX, chunkY)
    local worldX, worldY = self:chunkToWorld(chunkX, chunkY)
    
    for x = 1, CHUNK_SIZE do
        for y = 1, CHUNK_SIZE do
            local globalX = worldX + x - 1
            local globalY = worldY + y - 1
            
            -- Use global coordinates for noise to ensure continuity across chunks
            local noise1 = love.math.noise(globalX * 0.1, globalY * 0.1)
            local noise2 = love.math.noise(globalX * 0.05, globalY * 0.05)
            local noise3 = love.math.noise(globalX * 0.2, globalY * 0.2)
            
            if biome == "forest" then
                if noise1 > 0.8 and math.random() > 0.4 then
                    chunk.tiles[x][y] = Config.terrainTypes.tree
                elseif noise1 > 0.5 then
                    chunk.tiles[x][y] = Config.terrainTypes.tallGrass
                elseif noise1 > 0.2 then
                    chunk.tiles[x][y] = Config.terrainTypes.grass
                end
                
            elseif biome == "mountains" then
                if noise1 > 0.85 then
                    chunk.tiles[x][y] = Config.terrainTypes.highMountain
                elseif noise1 > 0.70 then
                    chunk.tiles[x][y] = Config.terrainTypes.mountain
                elseif noise1 > 0.60 then
                    chunk.tiles[x][y] = Config.terrainTypes.wall
                elseif noise1 > 0.3 then
                    chunk.tiles[x][y] = Config.terrainTypes.grass
                end
                
            elseif biome == "lake" then
                if noise1 > 0.75 and noise2 > 0.7 then
                    chunk.tiles[x][y] = Config.terrainTypes.deepWater
                elseif noise1 > 0.6 and noise2 > 0.5 then
                    chunk.tiles[x][y] = Config.terrainTypes.water
                elseif noise1 > 0.3 then
                    chunk.tiles[x][y] = Config.terrainTypes.grass
                end
                
            elseif biome == "meadow" then
                if noise1 > 0.7 and math.random() > 0.6 then
                    chunk.tiles[x][y] = Config.terrainTypes.flowers
                elseif noise1 > 0.5 then
                    chunk.tiles[x][y] = Config.terrainTypes.tallGrass
                else
                    chunk.tiles[x][y] = Config.terrainTypes.grass
                end
                
            elseif biome == "plains" then
                if noise1 > 0.6 then
                    chunk.tiles[x][y] = Config.terrainTypes.grass
                elseif noise3 > 0.8 then
                    chunk.tiles[x][y] = Config.terrainTypes.path
                end
            end
        end
    end
end

-- Ensure chunk connectivity by adding guaranteed paths
function InfiniteMap.ensureChunkConnectivity(self, chunk, chunkX, chunkY)
    -- Create guaranteed horizontal and vertical paths through the chunk
    local midX = math.floor(CHUNK_SIZE / 2)
    local midY = math.floor(CHUNK_SIZE / 2)
    
    -- Add horizontal path (left to right)
    for x = 1, CHUNK_SIZE do
        if not chunk.tiles[x][midY].walkable then
            chunk.tiles[x][midY] = Config.terrainTypes.path
        end
    end
    
    -- Add vertical path (top to bottom)  
    for y = 1, CHUNK_SIZE do
        if not chunk.tiles[midX][y].walkable then
            chunk.tiles[midX][y] = Config.terrainTypes.path
        end
    end
    
    -- Add connecting paths to chunk edges for smoother transitions
    -- Top edge connection
    local topConnectX = math.random(math.floor(CHUNK_SIZE * 0.3), math.floor(CHUNK_SIZE * 0.7))
    for y = 1, midY do
        if not chunk.tiles[topConnectX][y].walkable then
            chunk.tiles[topConnectX][y] = Config.terrainTypes.path
        end
    end
    
    -- Bottom edge connection
    local bottomConnectX = math.random(math.floor(CHUNK_SIZE * 0.3), math.floor(CHUNK_SIZE * 0.7))
    for y = midY, CHUNK_SIZE do
        if not chunk.tiles[bottomConnectX][y].walkable then
            chunk.tiles[bottomConnectX][y] = Config.terrainTypes.path
        end
    end
    
    -- Left edge connection
    local leftConnectY = math.random(math.floor(CHUNK_SIZE * 0.3), math.floor(CHUNK_SIZE * 0.7))
    for x = 1, midX do
        if not chunk.tiles[x][leftConnectY].walkable then
            chunk.tiles[x][leftConnectY] = Config.terrainTypes.path
        end
    end
    
    -- Right edge connection
    local rightConnectY = math.random(math.floor(CHUNK_SIZE * 0.3), math.floor(CHUNK_SIZE * 0.7))
    for x = midX, CHUNK_SIZE do
        if not chunk.tiles[x][rightConnectY].walkable then
            chunk.tiles[x][rightConnectY] = Config.terrainTypes.path
        end
    end
    
    -- Add some additional random walkable areas to prevent large impassable regions
    for i = 1, 5 do
        local areaX = math.random(3, CHUNK_SIZE - 2)
        local areaY = math.random(3, CHUNK_SIZE - 2)
        
        -- Create small walkable areas (3x3)
        for dx = -1, 1 do
            for dy = -1, 1 do
                local x, y = areaX + dx, areaY + dy
                if x >= 1 and x <= CHUNK_SIZE and y >= 1 and y <= CHUNK_SIZE then
                    if not chunk.tiles[x][y].walkable then
                        -- Use appropriate walkable terrain based on current biome
                        if math.random() > 0.5 then
                            chunk.tiles[x][y] = Config.terrainTypes.path
                        else
                            chunk.tiles[x][y] = Config.terrainTypes.floor
                        end
                    end
                end
            end
        end
    end
end

-- Add decorative elements to chunk
function InfiniteMap.addChunkDecorations(self, chunk, biome)
    -- Add special features occasionally
    for i = 1, 3 do
        local x = math.random(3, CHUNK_SIZE - 2)
        local y = math.random(3, CHUNK_SIZE - 2)
        
        if chunk.tiles[x][y].walkable and math.random() < 0.1 then
            local feature = math.random(1, 5)
            if feature == 1 then
                chunk.tiles[x][y] = Config.terrainTypes.altar
            elseif feature == 2 then
                chunk.tiles[x][y] = Config.terrainTypes.stairsDown
            elseif feature == 3 then
                chunk.tiles[x][y] = Config.terrainTypes.stairsUp
            elseif feature == 4 then
                chunk.tiles[x][y] = Config.terrainTypes.door
            end
        end
    end
end

-- Generate spawn points for chunk
function InfiniteMap.generateChunkSpawnPoints(self, chunk)
    local spawnCount = math.random(2, 5)  -- 2-5 spawn points per chunk
    
    for i = 1, spawnCount do
        local attempts = 0
        local x, y
        
        repeat
            attempts = attempts + 1
            x = math.random(2, CHUNK_SIZE - 1)
            y = math.random(2, CHUNK_SIZE - 1)
        until chunk.tiles[x][y].walkable or attempts > 20
        
        if chunk.tiles[x][y].walkable then
            -- Convert to world coordinates
            local worldX, worldY = self:chunkToWorld(chunk.x, chunk.y)
            table.insert(chunk.enemySpawnPoints, {
                x = worldX + x - 1,
                y = worldY + y - 1
            })
        end
    end
end

-- Generate enemies for chunk
function InfiniteMap.generateChunkEnemies(self, chunk, biome)
    -- Enemy count based on biome
    local enemyCounts = {
        forest = {2, 4},      -- 2-4 enemies in forests
        mountains = {1, 3},   -- 1-3 enemies in mountains  
        lake = {1, 2},        -- 1-2 enemies near lakes
        meadow = {2, 5},      -- 2-5 enemies in meadows
        plains = {3, 6}       -- 3-6 enemies in plains
    }
    
    local range = enemyCounts[biome] or {2, 4}
    local enemyCount = math.random(range[1], range[2])
    
    -- Don't spawn too many enemies near origin (starting area)
    local worldX, worldY = self:chunkToWorld(chunk.x, chunk.y)
    local distanceFromOrigin = math.sqrt(worldX * worldX + worldY * worldY)
    
    if distanceFromOrigin < 100 then  -- Within 100 tiles of origin
        enemyCount = math.max(1, math.floor(enemyCount * 0.5))  -- Reduce enemy count
    end
    
    for i = 1, enemyCount do
        local attempts = 0
        local x, y
        
        -- Try to place enemy on walkable terrain
        repeat
            attempts = attempts + 1
            x = math.random(2, CHUNK_SIZE - 1)
            y = math.random(2, CHUNK_SIZE - 1)
        until chunk.tiles[x][y].walkable or attempts > 20
        
        if chunk.tiles[x][y].walkable then
            -- Convert to world coordinates
            local enemyWorldX = worldX + x - 1
            local enemyWorldY = worldY + y - 1
            
            -- Create enemy data (will be converted to actual Enemy objects later)
            local enemyData = {
                x = enemyWorldX,
                y = enemyWorldY,
                biome = biome,
                chunkX = chunk.x,
                chunkY = chunk.y
            }
            
            table.insert(chunk.enemies, enemyData)
        end
    end
end

-- Load chunks around player position
function InfiniteMap.loadChunksAroundPlayer(self, playerX, playerY)
    local playerChunkX, playerChunkY = self:worldToChunk(playerX, playerY)
    
    for dx = -CHUNK_LOAD_RADIUS, CHUNK_LOAD_RADIUS do
        for dy = -CHUNK_LOAD_RADIUS, CHUNK_LOAD_RADIUS do
            self:getChunk(playerChunkX + dx, playerChunkY + dy)
        end
    end
end

-- Get tile at world coordinates
function InfiniteMap.getTileAt(self, worldX, worldY)
    local chunkX, chunkY = self:worldToChunk(worldX, worldY)
    local chunk = self:getChunk(chunkX, chunkY)
    
    local localX, localY = self:worldToLocal(worldX, worldY)
    return chunk.tiles[localX][localY]
end

-- Check if tile is walkable
function InfiniteMap.isWalkable(self, worldX, worldY)
    local tile = self:getTileAt(worldX, worldY)
    return tile and tile.walkable
end

-- Get all spawn points from loaded chunks
function InfiniteMap.getAllSpawnPoints(self)
    local allSpawnPoints = {}
    
    for chunkX, chunkRow in pairs(self.chunks) do
        for chunkY, chunk in pairs(chunkRow) do
            if chunk and chunk.enemySpawnPoints then
                for _, spawnPoint in ipairs(chunk.enemySpawnPoints) do
                    table.insert(allSpawnPoints, spawnPoint)
                end
            end
        end
    end
    
    return allSpawnPoints
end

-- Get random spawn point from loaded chunks
function InfiniteMap.getRandomSpawnPoint(self)
    local allSpawnPoints = self:getAllSpawnPoints()
    if #allSpawnPoints == 0 then
        return nil
    end
    return allSpawnPoints[math.random(#allSpawnPoints)]
end

-- Get all enemy data from loaded chunks
function InfiniteMap.getAllEnemyData(self)
    local allEnemyData = {}
    
    for chunkX, chunkRow in pairs(self.chunks) do
        for chunkY, chunk in pairs(chunkRow) do
            if chunk and chunk.enemies then
                for _, enemyData in ipairs(chunk.enemies) do
                    table.insert(allEnemyData, enemyData)
                end
            end
        end
    end
    
    return allEnemyData
end

-- Remove enemy data from chunk when enemy is defeated
function InfiniteMap.removeEnemyData(self, enemyX, enemyY)
    local chunkX, chunkY = self:worldToChunk(enemyX, enemyY)
    local chunk = self.chunks[chunkX] and self.chunks[chunkX][chunkY]
    
    if chunk and chunk.enemies then
        for i = #chunk.enemies, 1, -1 do
            local enemyData = chunk.enemies[i]
            if enemyData.x == enemyX and enemyData.y == enemyY then
                table.remove(chunk.enemies, i)
                break
            end
        end
    end
end

-- Draw visible portion of the infinite map
function InfiniteMap.draw(self, visibleTiles, exploredTiles, currentFrame)
    local tileSize = Config.tileSize
    love.graphics.setColor(1, 1, 1)
    
    -- Get screen dimensions
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Calculate visible tile range based on current view
    -- Since we're drawing with camera transformations, we draw a generous area around origin
    local padding = 5  -- Extra tiles to draw outside visible area
    local tilesPerScreenX = math.ceil(screenWidth / tileSize) + padding * 2
    local tilesPerScreenY = math.ceil(screenHeight / tileSize) + padding * 2
    
    -- Draw tiles around visible area
    local minVisibleX, maxVisibleX = math.huge, -math.huge
    local minVisibleY, maxVisibleY = math.huge, -math.huge
    
    -- Find bounds of visible tiles
    for x, column in pairs(visibleTiles) do
        for y, brightness in pairs(column) do
            if brightness and brightness > 0 then
                minVisibleX = math.min(minVisibleX, x)
                maxVisibleX = math.max(maxVisibleX, x)
                minVisibleY = math.min(minVisibleY, y)
                maxVisibleY = math.max(maxVisibleY, y)
            end
        end
    end
    
    -- If no visible tiles, use a default range
    if minVisibleX == math.huge then
        minVisibleX, maxVisibleX = -padding, padding
        minVisibleY, maxVisibleY = -padding, padding
    else
        -- Expand bounds by padding
        minVisibleX = minVisibleX - padding
        maxVisibleX = maxVisibleX + padding
        minVisibleY = minVisibleY - padding
        maxVisibleY = maxVisibleY + padding
    end
    
    -- Draw tiles in calculated range
    for worldX = minVisibleX, maxVisibleX do
        for worldY = minVisibleY, maxVisibleY do
            local terrain = self:getTileAt(worldX, worldY)
            if terrain then
                local screenX = (worldX - 1) * tileSize
                local screenY = (worldY - 1) * tileSize
                
                -- Determine tile visibility
                if visibleTiles[worldX] and visibleTiles[worldX][worldY] then
                    -- Currently visible
                    local brightness = type(visibleTiles[worldX][worldY]) == "boolean" and 1.0 or visibleTiles[worldX][worldY]
                    local r = math.min(1.0, terrain.color[1] * brightness)
                    local g = math.min(1.0, terrain.color[2] * brightness)
                    local b = math.min(1.0, terrain.color[3] * brightness)
                    
                    love.graphics.setColor(r, g, b)
                    
                    -- Add animation for certain terrain types
                    if terrain.animated then
                        if terrain == Config.terrainTypes.water or terrain == Config.terrainTypes.deepWater then
                            local waveOffset = math.sin((currentFrame + worldX * 0.1 + worldY * 0.1) * 2 * math.pi) * 2
                            love.graphics.print(terrain.char, screenX, screenY + waveOffset)
                        elseif terrain == Config.terrainTypes.grass or terrain == Config.terrainTypes.tallGrass then
                            local swayOffset = math.sin((currentFrame + worldX * 0.05) * 2 * math.pi) * 1
                            love.graphics.print(terrain.char, screenX + swayOffset, screenY)
                        else
                            love.graphics.print(terrain.char, screenX, screenY)
                        end
                    else
                        love.graphics.print(terrain.char, screenX, screenY)
                    end
                    
                elseif exploredTiles and exploredTiles[worldX] and exploredTiles[worldX][worldY] then
                    -- Previously explored
                    love.graphics.setColor(
                        terrain.color[1] * 0.8,
                        terrain.color[2] * 0.8,
                        terrain.color[3] * 0.8
                    )
                    love.graphics.print(terrain.char, screenX, screenY)
                else
                    -- Unexplored (only draw if close to visible area to avoid infinite black tiles)
                    local distanceToVisible = math.huge
                    for vx, vcolumn in pairs(visibleTiles) do
                        for vy, vbrightness in pairs(vcolumn) do
                            if vbrightness and vbrightness > 0 then
                                local dist = math.abs(worldX - vx) + math.abs(worldY - vy)
                                distanceToVisible = math.min(distanceToVisible, dist)
                            end
                        end
                    end
                    
                    if distanceToVisible <= 3 then  -- Only draw unexplored near visible areas
                        love.graphics.setColor(0.15, 0.15, 0.25)
                        love.graphics.print(" ", screenX, screenY)
                    end
                end
            end
        end
    end
end

return InfiniteMap