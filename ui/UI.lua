-- ui/UI.lua
-- Base UI class for all user interface elements

local Config = require("config/Config")

local UI = {}
UI.__index = UI

-- Create a new UI element
function UI.new(x, y, width, height)
    local self = setmetatable({}, UI)
    
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.visible = true
    
    return self
end

-- Update UI state
function UI.update(self, dt)
    -- Base implementation does nothing
    -- Override in derived classes
end

-- Draw the UI element
function UI.draw(self)
    if not self.visible then
        return
    end
    
    -- Base implementation draws a simple rectangle
    love.graphics.setColor(Config.colors.panel)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(Config.colors.panelBorder)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
end

-- Check if a point is inside the UI element
function UI.isPointInside(self, x, y)
    return x >= self.x and x <= self.x + self.width and
           y >= self.y and y <= self.y + self.height
end

-- Set UI visibility
function UI.setVisible(self, visible)
    self.visible = visible
end

-- Set position
function UI.setPosition(self, x, y)
    self.x = x
    self.y = y
end

-- Set dimensions
function UI.setDimensions(self, width, height)
    self.width = width
    self.height = height
end

return UI