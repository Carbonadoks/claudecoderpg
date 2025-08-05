-- entities/ItemManager.lua
-- Manages item creation and tracking

local Item = require("entities/Item")
local Config = require("config/Config")
local Utils = require("utils/Utils")

local ItemManager = {}
ItemManager.__index = ItemManager

-- Create a new item manager
function ItemManager.new(map)
    local self = setmetatable({}, ItemManager)
    
    self.map = map
    self.items = {}
    
    return self
end

-- Update all items
function ItemManager.update(self, dt, currentFrame)
    for _, item in ipairs(self.items) do
        item:update(dt, currentFrame)
    end
end

-- Generate items
function ItemManager.generateItems(self, count, enemyManager, playerX, playerY)
    local generatedCount = 0
    -- Use provided player position or default to origin
    playerX = playerX or 1
    playerY = playerY or 1
    
    for i = 1, count do
        local x, y
        local attempts = 0
        local validPosition = false
        
        -- Find a valid position for the item
        repeat
            attempts = attempts + 1
            -- Generate items within reasonable range around player (5-15 tiles away)
            local angle = math.random() * 2 * math.pi
            local distance = math.random(5, 15)
            x = math.floor(playerX + math.cos(angle) * distance)
            y = math.floor(playerY + math.sin(angle) * distance)
            
            -- Check if position is valid (walkable and not occupied)
            validPosition = self.map:isWalkable(x, y) and
                           not self:isItemAt(x, y)
            
            -- Check enemy position if enemyManager is provided
            if validPosition and enemyManager then
                validPosition = not enemyManager:isEnemyAt(x, y)
            end
        until validPosition or attempts > 50
        
        if validPosition then
            -- Create the item
            local itemType = Config.itemTypes[math.random(#Config.itemTypes)]
            local item = Item.new(x, y, itemType)
            
            table.insert(self.items, item)
            generatedCount = generatedCount + 1
        end
    end
    
    return generatedCount
end

-- Check if an item is at the specified position
function ItemManager.isItemAt(self, x, y)
    for _, item in ipairs(self.items) do
        if item.x == x and item.y == y then
            return true
        end
    end
    return false
end

-- Get item at the specified position
function ItemManager.getItemAt(self, x, y)
    for i, item in ipairs(self.items) do
        if item.x == x and item.y == y then
            return item, i
        end
    end
    return nil
end

-- Remove item at specified index
function ItemManager.removeItem(self, index)
    table.remove(self.items, index)
end

-- Draw all items
function ItemManager.draw(self, tileSize, currentFrame, visibleTiles)
    for _, item in ipairs(self.items) do
        item:draw(tileSize, currentFrame, visibleTiles)
    end
end

return ItemManager