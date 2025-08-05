-- entities/Item.lua
-- Game item implementation

local Entity = require("entities/Entity")
local Config = require("config/Config")
local Utils = require("utils/Utils")

local Item = setmetatable({}, {__index = Entity})
Item.__index = Item

-- Create a new item
function Item.new(x, y, itemType)
    local self = setmetatable(Entity.new(x, y, itemType.char, Config.colors.item), Item)
    
    -- Copy properties from itemType
    self.name = itemType.name
    self.effect = itemType.effect
    self.value = itemType.value
    
    return self
end

-- Update item state
function Item.update(self, dt, currentFrame)
    -- Make items glow/pulse
    local pulse = (math.sin(currentFrame * 2 * math.pi) + 1) * 0.2 + 0.8
    self.pulseColor = {
        self.color[1] * pulse,
        self.color[2] * pulse,
        self.color[3] * pulse
    }
    
    -- Add hover animation
    self.animationOffset = math.sin(currentFrame * 4 * math.pi) * 2
end

-- Draw the item
function Item.draw(self, tileSize, currentFrame, visibleTiles)
    if visibleTiles[self.x] and visibleTiles[self.x][self.y] then
        love.graphics.setColor(self.pulseColor or self.color)
        love.graphics.print(self.char, (self.x-1) * tileSize, (self.y-1) * tileSize + self.animationOffset)
    end
end

-- Use the item on a target
function Item.use(self, target)
    local effect = ""
    
    if self.effect == "heal" then
        target.hp = math.min(target.hp + self.value, target.maxHp)
        effect = "Healed for " .. self.value .. " HP"
    elseif self.effect == "attack" then
        target.attack = target.attack + self.value
        effect = "Attack increased by " .. self.value
    elseif self.effect == "defense" then
        target.defense = target.defense + self.value
        effect = "Defense increased by " .. self.value
    elseif self.effect == "speed" then
        target.speed = target.speed + self.value
        effect = "Speed increased by " .. self.value
    elseif self.effect == "gold" then
        -- Gold is handled differently - added to inventory
        effect = "Found " .. self.value .. " gold"
    end
    
    return effect
end

return Item