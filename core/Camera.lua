-- core/Camera.lua
-- Camera system for handling view transformations and effects

local Utils = require("utils/Utils")
local Config = require("config/Config")

local Camera = {}
Camera.__index = Camera

-- Create a new camera instance
function Camera.new()
    local self = setmetatable({}, Camera)
    
    -- Position
    self.x = 0
    self.y = 0
    self.targetX = 0
    self.targetY = 0
    
    -- Scaling and rotation
    self.scale = Config.camera.scale
    self.targetScale = Config.camera.scale
    self.rotation = Config.camera.rotation
    
    -- Shake effect
    self.shakeMagnitude = 0
    self.shakeTime = 0
    self.shakeX = 0
    self.shakeY = 0
    
    -- Visual effects
    self.vignette = Config.camera.vignette
    self.distortAmount = Config.camera.distortAmount
    
    -- Shader
    self:initShaders()
    
    return self
end

-- Initialize shader effects
function Camera.initShaders(self)
    -- Shader with vignette and screen distortion
    self.shader = love.graphics.newShader([[
        uniform float time;           // Current time for animation
        uniform float vignette;       // Vignette intensity
        uniform float distortAmount;  // Screen distortion amount
        
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            // Center coordinates for effects
            vec2 position = texture_coords;
            vec2 center = vec2(0.5, 0.5);
            float dist = distance(position, center);
            
            // Screen distortion (barrel effect)
            vec2 dir = position - center;
            float distPow = pow(dist, 1.5);
            position = position + dir * distPow * distortAmount;
            
            // Clamp coordinates
            position = clamp(position, 0.0, 1.0);
            
            // Get texture color
            vec4 texColor = Texel(texture, position);
            
            // Vignette effect
            float vignetteEffect = 1.0 - dist * vignette;
            texColor.rgb *= vignetteEffect;
            
            // Subtle scanline effect using screen coordinates
            float scanline = sin(screen_coords.y * 0.5) * 0.01 + 0.99;
            texColor.rgb *= scanline;
            
            return texColor * color;
        }
    ]])
end

-- Update camera position and effects
function Camera.update(self, dt)
    -- Smooth camera movement
    self.x = Utils.lerp(self.x, self.targetX, dt * 5)
    self.y = Utils.lerp(self.y, self.targetY, dt * 5)
    
    -- Smooth scale changes
    self.scale = Utils.lerp(self.scale, self.targetScale, dt * 3)
    
    -- Camera shake effect
    if self.shakeTime > 0 then
        self.shakeTime = self.shakeTime - dt
        -- Random camera offset when shaking
        self.shakeX = (math.random() * 2 - 1) * self.shakeMagnitude
        self.shakeY = (math.random() * 2 - 1) * self.shakeMagnitude
        
        if self.shakeTime <= 0 then
            self.shakeMagnitude = 0
            self.shakeX = 0
            self.shakeY = 0
        end
    end
    
    -- Update shader uniforms
    -- Skip sending time as it's not used in the shader
    self.shader:send("vignette", self.vignette)
    self.shader:send("distortAmount", self.distortAmount)
end

-- Set camera target position
function Camera.setTarget(self, x, y)
    self.targetX = x
    self.targetY = y
end

-- Apply camera shake effect
function Camera.shake(self, magnitude, duration)
    self.shakeMagnitude = magnitude
    self.shakeTime = duration
end

-- Set camera scale (zoom)
function Camera.setScale(self, scale)
    self.targetScale = scale
end

-- Apply camera transformations directly (no canvas)
function Camera.startCapture(self)
    -- Apply camera transformations
    love.graphics.push()
    love.graphics.translate(-self.x, -self.y)
    love.graphics.scale(self.scale)
    
    -- Add camera shake if active
    if self.shakeTime > 0 then
        love.graphics.translate(self.shakeX, self.shakeY)
    end
end

-- Reset transformations
function Camera.endCapture(self)
    love.graphics.pop()
end

-- Draw the contents of the camera canvas with shader effects applied
function Camera.draw(self)
    -- Create a canvas to render to
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local canvas = love.graphics.newCanvas(screenWidth, screenHeight)
    
    -- Render to the canvas
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    
    -- Apply camera transformations
    self:startCapture()
    
    -- Return the canvas for whatever needs to be drawn on it
    return canvas
end

-- Finish drawing to the canvas and render it with effects
function Camera.endDraw(self, canvas)
    -- End the camera capture
    self:endCapture()
    
    -- Reset canvas
    love.graphics.setCanvas()
    
    -- Save current state
    love.graphics.push()
    love.graphics.origin()
    
    -- Set the shader
    love.graphics.setShader(self.shader)
    
    -- Draw the canvas at 0,0 with original size
    love.graphics.draw(canvas, 0, 0, 0, 1, 1)
    
    -- Reset shader
    love.graphics.setShader()
    
    -- Restore state
    love.graphics.pop()
end

return Camera