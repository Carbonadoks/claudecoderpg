-- map/FOV.lua
-- Field of view calculations for infinite worlds

local Utils = require("utils/Utils")
local Config = require("config/Config")

local FOV = {}
FOV.__index = FOV

-- Create a new FOV calculator
function FOV.new(map, player)
    local self = setmetatable({}, FOV)
    
    self.map = map
    self.player = player
    self.viewRange = 10 -- Default view range
    self.visibleTiles = {} -- Dynamic sparse array for infinite coordinates
    self.exploredTiles = {} -- Dynamic sparse array for infinite coordinates
    
    return self
end

-- Update visible tiles based on player position
function FOV.update(self, playerX, playerY, viewRange)
    -- Use stored player if not provided
    playerX = playerX or self.player.x
    playerY = playerY or self.player.y
    viewRange = viewRange or self.viewRange
    
    -- Save previously visible tiles as explored
    for x, column in pairs(self.visibleTiles) do
        if not self.exploredTiles[x] then
            self.exploredTiles[x] = {}
        end
        for y, brightness in pairs(column) do
            if brightness and brightness > 0 then
                self.exploredTiles[x][y] = true
            end
        end
    end
    
    -- Reset visibility
    self.visibleTiles = {}
    
    -- Cast rays in all directions for FOV
    local numRays = 180 -- More rays = more accurate but more processing
    for i = 1, numRays do
        local angle = (i / numRays) * math.pi * 2
        self:castRay(playerX, playerY, angle, viewRange)
    end
    
    -- Fill in any gaps with a post-processing step
    self:smoothFOV(playerX, playerY, viewRange)
end

-- Cast a ray from origin point at angle until blocked
function FOV.castRay(self, startX, startY, angle, maxLength)
    local dx = math.cos(angle)
    local dy = math.sin(angle)
    
    local currentX = startX
    local currentY = startY
    local lastX, lastY = math.floor(currentX), math.floor(currentY)
    
    -- Mark starting position as visible
    if not self.visibleTiles[lastX] then self.visibleTiles[lastX] = {} end
    self.visibleTiles[lastX][lastY] = 2.0  -- Increased brightness
    
    for i = 1, maxLength * 2 do
        currentX = currentX + dx * 0.5 -- Half-step for better precision
        currentY = currentY + dy * 0.5
        
        -- Get the tile coordinates
        local tileX, tileY = math.floor(currentX), math.floor(currentY)
        
        -- For infinite worlds, we don't check bounds - let the map handle chunk loading
        
        -- If we've moved to a new tile
        if tileX ~= lastX or tileY ~= lastY then
            -- Calculate distance for light falloff
            local distance = Utils.distance(tileX, tileY, startX, startY)
            local brightness = math.max(0, 3.5 - (distance / maxLength) * 0.3)
            
            -- Mark this tile as visible with brightness based on distance
            if not self.visibleTiles[tileX] then self.visibleTiles[tileX] = {} end
            self.visibleTiles[tileX][tileY] = math.max(self.visibleTiles[tileX][tileY] or 0, brightness)
            
            -- Get the tile at this position (will generate chunks as needed)
            local tile = self.map:getTileAt(tileX, tileY)
            
            -- If this tile blocks vision, stop the ray
            if tile and not tile.walkable and tile ~= Config.terrainTypes.door then
                -- We can see the wall but not through it
                break
            end
            
            lastX, lastY = tileX, tileY
        end
    end
end

-- Smooth out the FOV to avoid gaps
function FOV.smoothFOV(self, playerX, playerY, viewRange)
    -- Create a copy of the current FOV
    local newFOV = {}
    for x, column in pairs(self.visibleTiles) do
        newFOV[x] = {}
        for y, brightness in pairs(column) do
            if brightness then
                newFOV[x][y] = brightness
            end
        end
    end
    
    -- For each visible tile, check if it's surrounded by visible tiles
    for x, column in pairs(self.visibleTiles) do
        for y, brightness in pairs(column) do
            if brightness and brightness > 0 then
                -- Only smooth within reasonable range of player to avoid processing infinite tiles
                local distanceFromPlayer = Utils.distance(x, y, playerX, playerY)
                if distanceFromPlayer <= viewRange + 2 then
                    -- Check all surrounding tiles
                    for dx = -1, 1 do
                        for dy = -1, 1 do
                            local nx, ny = x + dx, y + dy
                            -- If a tile is visible, its neighbors should be at least slightly visible
                            if not newFOV[nx] then newFOV[nx] = {} end
                            
                            local currentVal = newFOV[nx][ny] or 0
                            local spreadVal = brightness * 0.95  -- Increased visibility spread to neighbors
                            
                            newFOV[nx][ny] = math.max(currentVal, spreadVal)
                        end
                    end
                end
            end
        end
    end
    
    self.visibleTiles = newFOV
end

-- Check if a tile is visible
function FOV.isVisible(self, x, y)
    return self.visibleTiles[x] and self.visibleTiles[x][y] and self.visibleTiles[x][y] > 0
end

-- Check if a tile is explored
function FOV.isExplored(self, x, y)
    return self.exploredTiles[x] and self.exploredTiles[x][y]
end

-- Check line of sight between two points
function FOV.hasLineOfSight(self, x1, y1, x2, y2)
    local dx = math.abs(x2 - x1)
    local dy = math.abs(y2 - y1)
    local sx = x1 < x2 and 1 or -1
    local sy = y1 < y2 and 1 or -1
    local err = dx - dy
    
    while true do
        if x1 == x2 and y1 == y2 then
            return true
        end
        
        local tile = self.map:getTileAt(x1, y1)
        if tile and not tile.walkable and tile ~= Config.terrainTypes.door then
            return false
        end
        
        local e2 = err * 2
        if e2 > -dy then
            if x1 == x2 then break end
            err = err - dy
            x1 = x1 + sx
        end
        if e2 < dx then
            if y1 == y2 then break end
            err = err + dx
            y1 = y1 + sy
        end
    end
    
    return true
end

return FOV