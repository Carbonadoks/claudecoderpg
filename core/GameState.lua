-- core/GameState.lua
-- Game state manager

local GameState = {}
GameState.__index = GameState

-- Create a new GameState instance
function GameState.new()
    local self = setmetatable({}, GameState)
    self.states = {}
    self.currentState = nil
    self.message = ""
    self.messageTimer = 0
    return self
end

-- Register a state with its update and draw functions
function GameState.registerState(self, stateName, state)
    self.states[stateName] = state
end

-- Change to a different state
function GameState.changeState(self, stateName, ...)
    if self.states[stateName] then
        local args = {...}
        if self.currentState and self.states[self.currentState].exit then
            self.states[self.currentState].exit(self)
        end
        
        self.currentState = stateName
        
        if self.states[stateName].enter then
            self.states[stateName].enter(self, unpack(args))
        end
        
        return true
    end
    return false
end

-- Get the current state name
function GameState.getCurrentState(self)
    return self.currentState
end

-- Update the current state
function GameState.update(self, dt)
    -- Update message timer
    if self.messageTimer > 0 then
        self.messageTimer = self.messageTimer - dt
        if self.messageTimer <= 0 then
            self.message = ""
        end
    end
    
    -- Update current state
    if self.currentState and self.states[self.currentState].update then
        self.states[self.currentState].update(self, dt)
    end
end

-- Draw the current state
function GameState.draw(self)
    if self.currentState and self.states[self.currentState].draw then
        self.states[self.currentState].draw(self)
    end
    
    -- Draw message if active
    if self.message ~= "" and self.messageTimer > 0 then
        local Config = require("config/Config")
        love.graphics.setColor(Config.colors.highlight)
        love.graphics.printf(self.message, 10, 10, love.graphics.getWidth() - 20, "center")
    end
end

-- Display a message for a specified duration
function GameState.showMessage(self, message, duration)
    self.message = message
    self.messageTimer = duration or 3
end

-- Handle key press in the current state
function GameState.keypressed(self, key)
    if self.currentState and self.states[self.currentState].keypressed then
        self.states[self.currentState].keypressed(self, key)
    end
end

return GameState