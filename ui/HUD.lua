-- ui/HUD.lua
-- Heads-up display for player information

local UI = require("ui/UI")
local Config = require("config/Config")

local HUD = setmetatable({}, {__index = UI})
local Timer = require("utils.timer")
HUD.__index = HUD

-- Log display constants (calculated dynamically in functions)
local logWidth = 240
local logHeight = 200

-- Create a new HUD
function HUD.new(player, map)
    local self = setmetatable(UI.new(0, 0, love.graphics.getWidth(), love.graphics.getHeight()), HUD)
    
    self.player = player
    self.map = map
    
    -- Create the minimap
    self.minimapSize = 80
    self.minimapX = love.graphics.getWidth() - self.minimapSize - 10
    self.minimapY = 10
    
    -- Create terrain panel
    self.terrainPanelWidth = 180
    self.terrainPanelHeight = 230
    self.terrainPanelX = 10
    self.terrainPanelY = 10
    
    -- Tooltip properties
    self.hoveredTile = nil
    self.tooltipWidth = 250
    self.tooltipHeight = 120
    self.timer = Timer()
    
    -- Legend state
    self.showLegend = false
    self.messages = {}
    self.messageTweens = {Config.colors.highlight,Config.colors.highlight,Config.colors.highlight,Config.colors.highlight,Config.colors.highlight}
    self.currentTween = 0
    self.maxMessages = 5
    self.messageLog = {}
    self.showScrollbar = false
    self.scrollbarHover = false
    self.scrollOffset = 0


    return self
end

-- Update HUD state with hovered tile
function HUD.update(self, dt, hoveredTile)
    self.timer:update(dt)
    self.hoveredTile = hoveredTile

    local contentHeight = 0
    for _, msg in ipairs(self.messageLog) do
        contentHeight = contentHeight + msg.height
    end
    maxScrollOffset = math.max(0, contentHeight - logHeight)

    
    -- Clamp scroll offset
    self.scrollOffset = math.max(0, math.min(self.scrollOffset, maxScrollOffset))
    
    -- Check if mouse is over the scroll area
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local logX = screenWidth - logWidth - 10
    local logY = screenHeight - logHeight - 10
    
    local mx, my = love.mouse.getPosition()
    self.showScrollbar = (mx >= logX - 5 and mx <= logX - 5 + logWidth and
                     my >= logY - 5 and my <= logY - 5 + logHeight)
                     
    -- Check if mouse is over scrollbar
    if self.showScrollbar and maxScrollOffset > 0 then
        local scrollbarHeight = (logHeight / contentHeight) * logHeight
        local scrollbarY = logY - 5 + (self.scrollOffset / maxScrollOffset) * (logHeight - scrollbarHeight)
        
        self.scrollbarHover = (mx >= logX - 5 + logWidth - 10 and 
                         mx <= logX - 5 + logWidth and
                         my >= scrollbarY and 
                         my <= scrollbarY + scrollbarHeight)
    else
        self.scrollbarHover = false
    end
    
end

-- Toggle display of the legend
function HUD.toggleLegend(self)
    self.showLegend = not self.showLegend
end

-- Draw the HUD
function HUD.draw(self, map, visibleTiles, enemies, spawningInfo)
    local enemyCount = #enemies
    local maxEnemies = spawningInfo.maxEnemies
    local spawnTimer = spawningInfo.timer
    local spawnInterval = spawningInfo.interval
    local spawnEnabled = spawningInfo.enabled
    
    -- Draw terrain panel
    self:drawTerrainPanel(enemyCount, maxEnemies, spawnTimer, spawnInterval, spawnEnabled)
    
    -- Draw minimap
    self:drawMinimap(visibleTiles, map.exploredTiles or {})
    
    -- Draw player stats
    self.player:drawStats()
    
    -- Draw tooltip if hovering over a tile
    if self.hoveredTile then
        self:drawTileTooltip()
    end

    if self.messages then
        self:drawMessages()
    end

    self:drawMessageLog()
    
    -- Draw legend if it's toggled on
    if self.showLegend then
        self:drawLegend()
    end
end

-- Draw terrain panel with legend
function HUD.drawTerrainPanel(self, enemyCount, maxEnemies, spawnTimer, spawnInterval, spawnEnabled)
    local padding = 10
    local lineHeight = 22
    
    -- Draw panel background
    love.graphics.setColor(Config.colors.panel)
    love.graphics.rectangle("fill", self.terrainPanelX, self.terrainPanelY, self.terrainPanelWidth, self.terrainPanelHeight)
    love.graphics.setColor(Config.colors.panelBorder)
    love.graphics.rectangle("line", self.terrainPanelX, self.terrainPanelY, self.terrainPanelWidth, self.terrainPanelHeight)
    
    -- Panel title
    love.graphics.setColor(Config.colors.text)
    love.graphics.printf("TERRAIN GUIDE", self.terrainPanelX, self.terrainPanelY + 5, self.terrainPanelWidth, "center")
    
    -- Draw common terrain examples
    local terrainList = {
        Config.terrainTypes.floor,
        Config.terrainTypes.wall,
        Config.terrainTypes.water,
        Config.terrainTypes.grass,
        Config.terrainTypes.tree,
        Config.terrainTypes.path,
        Config.terrainTypes.stairsDown,
        Config.terrainTypes.stairsUp
    }
    
    for i, terrain in ipairs(terrainList) do
        local y = self.terrainPanelY + 25 + (i-1) * lineHeight
        
        -- Draw terrain symbol
        love.graphics.setColor(terrain.color)
        love.graphics.print(terrain.char, self.terrainPanelX + 20, y)
        
        -- Draw terrain name and passability
        love.graphics.setColor(Config.colors.text)
        love.graphics.print(terrain.name, self.terrainPanelX + 40, y)
        
        love.graphics.setColor(terrain.walkable and {0.2, 0.8, 0.2} or {0.8, 0.2, 0.2})
        love.graphics.print(terrain.walkable and "Pass" or "Block", self.terrainPanelX + self.terrainPanelWidth - 50, y)
    end
    
    -- Draw enemy counter
    love.graphics.setColor(Config.colors.enemy)
    love.graphics.print("Enemies: " .. enemyCount .. "/" .. maxEnemies, self.terrainPanelX + 15, self.terrainPanelY + self.terrainPanelHeight - 40)
    
    -- Draw next spawn info
    local timeToSpawn = math.max(0, spawnInterval - spawnTimer)
    love.graphics.setColor(Config.colors.text)
    love.graphics.print("Next spawn: " .. string.format("%.0f", timeToSpawn) .. "s", self.terrainPanelX + 15, self.terrainPanelY + self.terrainPanelHeight - 20)
    
    -- Restore default font
    love.graphics.setFont(love.graphics.newFont(Config.fontPath, Config.defaultFontSize))
end

-- Draw minimap (redesigned for infinite worlds)
function HUD.drawMinimap(self, visibleTiles, exploredTiles)
    -- For infinite worlds, show a fixed range around the player
    local minimapRadius = 25  -- Show 25 tiles in each direction from player
    local tileSizeMini = self.minimapSize / (minimapRadius * 2)
    
    -- Draw background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", self.minimapX - 5, self.minimapY - 5, self.minimapSize + 10, self.minimapSize + 10)
    
    -- Draw border
    love.graphics.setColor(0.7, 0.7, 0.7, 0.7)
    love.graphics.rectangle("line", self.minimapX - 5, self.minimapY - 5, self.minimapSize + 10, self.minimapSize + 10)
    
    -- Calculate bounds around player
    local playerX, playerY = self.player.x, self.player.y
    local minX = playerX - minimapRadius
    local maxX = playerX + minimapRadius
    local minY = playerY - minimapRadius
    local maxY = playerY + minimapRadius
    
    -- Draw explored tiles within minimap range
    for x = minX, maxX do
        for y = minY, maxY do
            if exploredTiles and exploredTiles[x] and exploredTiles[x][y] then
                local terrain = self.map:getTileAt(x, y)
                local isVisible = visibleTiles[x] and visibleTiles[x][y]
                
                if terrain then
                    love.graphics.setColor(
                        terrain.color[1] * (isVisible and 1 or 0.5),
                        terrain.color[2] * (isVisible and 1 or 0.5),
                        terrain.color[3] * (isVisible and 1 or 0.5),
                        isVisible and 1 or 0.7
                    )
                    
                    -- Convert world coordinates to minimap coordinates
                    local minimapX = self.minimapX + (x - minX) * tileSizeMini
                    local minimapY = self.minimapY + (y - minY) * tileSizeMini
                    
                    love.graphics.rectangle("fill", minimapX, minimapY, tileSizeMini, tileSizeMini)
                end
            end
        end
    end
    
    -- Draw player on minimap (center of minimap)
    love.graphics.setColor(1, 1, 1)
    local playerMinimapX = self.minimapX + minimapRadius * tileSizeMini
    local playerMinimapY = self.minimapY + minimapRadius * tileSizeMini
    love.graphics.rectangle("fill", playerMinimapX, playerMinimapY, tileSizeMini, tileSizeMini)
    
    -- Draw minimap label
    love.graphics.setColor(Config.colors.text)
    local smallFont = love.graphics.newFont(Config.fontPath, Config.smallFontSize)
    love.graphics.setFont(smallFont)
    love.graphics.print("MINIMAP", self.minimapX, self.minimapY - 20)
    love.graphics.setFont(love.graphics.newFont(Config.fontPath, Config.defaultFontSize))
end

-- Draw tooltip for hovered tile
function HUD.drawTileTooltip(self)
    local padding = 10
    
    -- Position near mouse but ensure it's on screen
    local mouseX, mouseY = love.mouse.getPosition()
    local tooltipX = math.min(mouseX + 15, love.graphics.getWidth() - self.tooltipWidth - 5)
    local tooltipY = math.min(mouseY + 15, love.graphics.getHeight() - self.tooltipHeight - 5)
    
    -- Background
    love.graphics.setColor(Config.colors.panel)
    love.graphics.rectangle("fill", tooltipX, tooltipY, self.tooltipWidth, self.tooltipHeight)
    love.graphics.setColor(Config.colors.panelBorder)
    love.graphics.rectangle("line", tooltipX, tooltipY, self.tooltipWidth, self.tooltipHeight)
    
    -- Tile coordinates
    love.graphics.setColor(Config.colors.text)
    love.graphics.print("Position: (" .. self.hoveredTile.x .. ", " .. self.hoveredTile.y .. ")", 
        tooltipX + padding, tooltipY + padding)
    
    -- Terrain info
    local terrain = self.hoveredTile.terrain
    if terrain then
        love.graphics.setColor(terrain.color)
        love.graphics.print(terrain.char, tooltipX + padding, tooltipY + padding + 25)
        
        love.graphics.setColor(Config.colors.text)
        love.graphics.print(terrain.name, tooltipX + padding + 20, tooltipY + padding + 25)
        
        -- Description
        local smallFont = love.graphics.newFont(Config.fontPath, Config.smallFontSize)
        love.graphics.setFont(smallFont)
        love.graphics.printf(terrain.desc or "", 
            tooltipX + padding, tooltipY + padding + 50, self.tooltipWidth - padding*2, "left")
        love.graphics.setFont(love.graphics.newFont(Config.fontPath, Config.defaultFontSize))
    end
    
    -- Entity info if available
    if self.hoveredTile.entity then
        local entity = self.hoveredTile.entity
        
        if self.hoveredTile.entityType == "enemy" then
            love.graphics.setColor(Config.colors.enemy)
            love.graphics.print("Enemy: " .. entity.name, tooltipX + padding, tooltipY + padding + 75)
            love.graphics.print("HP: " .. entity.hp .. "/" .. entity.maxHp, tooltipX + padding + 100, tooltipY + padding + 75)
        elseif self.hoveredTile.entityType == "item" then
            love.graphics.setColor(Config.colors.item)
            love.graphics.print("Item: " .. entity.name, tooltipX + padding, tooltipY + padding + 75)
        elseif self.hoveredTile.entityType == "player" then
            love.graphics.setColor(Config.colors.player)
            love.graphics.print("You (Level " .. self.player.level .. ")", tooltipX + padding, tooltipY + padding + 75)
        end
    end
end

function HUD.drawMessages(self)
    for index, value in ipairs(self.messages) do
        love.graphics.setColor(self.messageTweens[value.tween])
        love.graphics.printf(value.message, 10, index*15, love.graphics.getWidth() - 20, "center")
    end
end

function HUD.addMessage(self,message)

    self:addMessageToLog(message)
    if self.currentTween == 5 then
        self.currentTween = 1
    else
       self.currentTween = self.currentTween + 1
    end
    table.insert(self.messages, 1, {message = message, tween = self.currentTween})
    self.messageTweens[self.currentTween] = {1,1,0,1}
    self.timer:tween(2,self.messageTweens[self.currentTween], {1,1,0,0})

    -- Remove oldest message if exceeding max
    if #self.messages > self.maxMessages then
        table.remove(self.messages)
    end
end

function HUD.drawMessageLog(self)
    -- Calculate log position dynamically
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local logX = screenWidth - logWidth - 10
    local logY = screenHeight - logHeight - 10
    
    -- Background panel
    love.graphics.setColor(Config.colors.panel)
    love.graphics.rectangle("fill", logX-5, logY-5, logWidth, logHeight)
    love.graphics.setColor(Config.colors.panelBorder)
    love.graphics.rectangle("line", logX-5, logY-5, logWidth, logHeight)
    
    -- Set stencil to clip messages outside the log area
    love.graphics.stencil(function()
        love.graphics.rectangle("fill", logX-5, logY-5, logWidth, logHeight)
    end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)
    
    -- Draw messages with proper spacing
    love.graphics.setColor(Config.colors.text)
    local smallFont = love.graphics.newFont(Config.fontPath, Config.smallFontSize)
    love.graphics.setFont(smallFont)
    
    local y = logY + 5 - self.scrollOffset
    local lineHeight = smallFont:getHeight() + 2  -- Consistent line height with padding
    
    for _, msg in ipairs(self.messageLog) do
        love.graphics.printf(msg.text, logX + 5, y, logWidth - 20, "left")
        y = y + msg.height
    end
    
    -- Reset stencil test and font
    love.graphics.setStencilTest()
    love.graphics.setFont(love.graphics.newFont(Config.fontPath, Config.defaultFontSize))
    
    -- Draw scrollbar if needed
    if self.showScrollbar and maxScrollOffset > 0 then
        local scrollbarWidth = 5
        local scrollbarHeight = (logHeight / (maxScrollOffset + logHeight)) * logHeight
        scrollbarHeight = math.max(20, scrollbarHeight) -- Minimum scrollbar size
        
        local scrollbarY = logY - 5 + (self.scrollOffset / maxScrollOffset) * (logHeight - scrollbarHeight)
        
        if self.scrollbarHover then
            love.graphics.setColor(Config.colors.scrollBarHover)
        else
            love.graphics.setColor(Config.colors.scrollBar)
        end
        
        love.graphics.rectangle("fill", 
                              logX - 5 + logWidth - scrollbarWidth - 3, 
                              scrollbarY, 
                              scrollbarWidth, 
                              scrollbarHeight)
    end
end


-- Draw the full legend screen
function HUD.drawLegend(self)
    local legendWidth = 500
    local legendHeight = 500
    local padding = 20
    local lineHeight = 24
    
    -- Center on screen
    local legendX = (love.graphics.getWidth() - legendWidth) / 2
    local legendY = (love.graphics.getHeight() - legendHeight) / 2
    
    -- Semi-transparent dark background for the whole screen
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Legend panel
    love.graphics.setColor(Config.colors.panel)
    love.graphics.rectangle("fill", legendX, legendY, legendWidth, legendHeight)
    love.graphics.setColor(Config.colors.panelBorder)
    love.graphics.rectangle("line", legendX, legendY, legendWidth, legendHeight)
    
    -- Title
    local bigFont = love.graphics.newFont(Config.fontPath, Config.bigFontSize)
    love.graphics.setFont(bigFont)
    love.graphics.setColor(Config.colors.text)
    love.graphics.printf("LEGEND & GAME HELP", legendX, legendY + padding, legendWidth, "center")
    love.graphics.setFont(love.graphics.newFont(Config.fontPath, Config.defaultFontSize))
    
    -- Terrain types in columns
    local col1X = legendX + padding
    local col2X = legendX + padding + 250
    local startY = legendY + padding + 40
    local y = startY
    
    love.graphics.setColor(Config.colors.text)
    love.graphics.print("TERRAIN TYPES:", col1X, y)
    y = y + lineHeight * 1.5
    
    local count = 0
    for name, terrain in pairs(Config.terrainTypes) do
        -- Alternate between left and right columns
        local x = (count % 2 == 0) and col1X or col2X
        
        love.graphics.setColor(terrain.color)
        love.graphics.print(terrain.char, x, y)
        
        love.graphics.setColor(Config.colors.text)
        love.graphics.print(" - " .. terrain.name, x + 20, y)
        
        -- Display walkable status
        love.graphics.setColor(terrain.walkable and {0.2, 0.8, 0.2} or {0.8, 0.2, 0.2})
        love.graphics.print(terrain.walkable and "(Pass)" or "(Block)", x + 150, y)
        
        count = count + 1
        if count % 2 == 0 then y = y + lineHeight end
    end
    
    -- Entities section
    y = y + lineHeight * 1.5
    love.graphics.setColor(Config.colors.text)
    love.graphics.print("ENTITIES:", col1X, y)
    y = y + lineHeight
    
    -- Player
    love.graphics.setColor(Config.colors.player)
    love.graphics.print("@", col1X, y)
    love.graphics.setColor(Config.colors.text)
    love.graphics.print(" - You (Player)", col1X + 20, y)
    
    -- Enemy
    love.graphics.setColor(Config.colors.enemy)
    love.graphics.print("g/o/T", col2X, y)
    love.graphics.setColor(Config.colors.text)
    love.graphics.print(" - Enemies", col2X + 40, y)
    
    y = y + lineHeight
    
    -- Item
    love.graphics.setColor(Config.colors.item)
    love.graphics.print("!/$/=", col1X, y)
    love.graphics.setColor(Config.colors.text)
    love.graphics.print(" - Items", col1X + 40, y)
    
    -- Controls section
    y = y + lineHeight * 1.5
    love.graphics.setColor(Config.colors.text)
    love.graphics.print("CONTROLS:", col1X, y)
    y = y + lineHeight
    
    -- List controls
    local controls = {
        {"Arrow Keys / WASD", "Move character"},
        {"H / F1", "Toggle this help screen"},
        {"Mouse hover", "See tile information"},
        {"Enter (at game over)", "Start new game"},
        {"+ / -", "Adjust combat speed in battle"},
        {"E", "Toggle enemy spawning"},
        {"Q", "Force spawn enemies"},
        {"1", "Toggle camera zoom"},
        {"2", "Toggle vignette effect"},
        {"3", "Test camera shake"},
        {"4", "Toggle chromatic aberration"},
        {"5", "Toggle screen distortion"},
        {"0", "Reset all camera effects"}
    }
    
    for i, control in ipairs(controls) do
        love.graphics.setColor(Config.colors.highlight)
        love.graphics.print(control[1], col1X, y)
        love.graphics.setColor(Config.colors.text)
        love.graphics.print(" - " .. control[2], col1X + 150, y)
        y = y + lineHeight
    end
    
    -- Combat section
    y = y + lineHeight
    love.graphics.setColor(Config.colors.text)
    love.graphics.print("COMBAT:", col1X, y)
    y = y + lineHeight
    
    -- Explain combat system
    local smallFont = love.graphics.newFont(Config.fontPath, Config.smallFontSize)
    love.graphics.setFont(smallFont)
    love.graphics.printf("Combat is automatic and turn-based. The speed of combat can be adjusted during battle with + and - keys. Faster characters attack more frequently. Critical hits deal double damage.", 
      col1X, y, legendWidth - padding*2, "left")
    love.graphics.setFont(love.graphics.newFont(Config.fontPath, Config.defaultFontSize))
    
    -- Close instructions
    love.graphics.setColor(Config.colors.highlight)
    love.graphics.printf("Press H, F1 or any movement key to close", legendX, legendY + legendHeight - 30, legendWidth, "center")
end

function HUD.addMessageToLog(self, message)
    -- Use small font for consistent message sizing
    local smallFont = love.graphics.newFont(Config.fontPath, Config.smallFontSize)
    local _, wrappedText = smallFont:getWrap(message, logWidth - 20)
    local height = #wrappedText * (smallFont:getHeight() + 2) + 2 -- Line height + padding
    
    -- Add to the beginning of the log for newest-first order
    table.insert(self.messageLog, 1, {text = message, height = height})
    
    -- Optional: limit number of messages stored
    if #self.messageLog > 200 then
        table.remove(self.messageLog)
    end
end


function HUD.wheelmoved(self,x,y)
    -- Calculate log position dynamically
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local logX = screenWidth - logWidth - 10
    local logY = screenHeight - logHeight - 10
    
    -- Check if mouse is over the log area
    local mx, my = love.mouse.getPosition()
    if mx >= logX - 5 and mx <= logX - 5 + logWidth and
       my >= logY - 5 and my <= logY - 5 + logHeight then
        -- Scroll with mouse wheel
        self.scrollOffset = self.scrollOffset - y * Config.scrollSpeed
        -- Clamp scroll offset
        self.scrollOffset = math.max(0, math.min(self.scrollOffset, maxScrollOffset))
    end
end

return HUD