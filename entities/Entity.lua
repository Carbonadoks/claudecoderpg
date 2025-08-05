-- entities/Entity.lua
-- Base entity class for all game objects

local Utils = require("utils/Utils")

local Entity = {}
Entity.__index = Entity

-- Create a new entity
function Entity.new(x, y, char, color)
    local self = setmetatable({}, Entity)
    
    self.x = x
    self.y = y
    self.char = char
    self.color = color
    
    -- Animation properties
    self.isAnimated = false
    self.animationOffset = 0
    
    return self
end

-- Update entity state
function Entity.update(self, dt, currentFrame)
    -- Base implementation does nothing
    -- Override in derived classes
end

-- Draw the entity
function Entity.draw(self, tileSize, currentFrame)
    love.graphics.setColor(self.color)
    love.graphics.print(self.char, (self.x-1) * tileSize, (self.y-1) * tileSize + self.animationOffset)
end

-- Move entity to a new position
function Entity.moveTo(self, x, y)
    self.x = x
    self.y = y
end

-- Calculate distance to another entity or position
function Entity.distanceTo(self, target)
    local targetX, targetY
    
    if type(target) == "table" then
        -- Target is another entity
        targetX, targetY = target.x, target.y
    else
        -- Target is a position (x, y)
        targetX, targetY = target[1], target[2]
    end
    
    return Utils.distance(self.x, self.y, targetX, targetY)
end

return Entity