-- ui/CombatUI.lua
-- UI for combat screen

local UI = require("ui/UI")
local Config = require("config/Config")
local BattleCanvas = require("ui/BattleCanvas")
local Utils = require("utils/Utils")

local CombatUI = setmetatable({}, {__index = UI})
CombatUI.__index = CombatUI

screenWidth = love.graphics.getWidth()
screenHeight = love.graphics.getHeight()

-- Create a new combat UI
function CombatUI.new(player, combat)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    local self = setmetatable(UI.new(0, 0, screenWidth, screenHeight), CombatUI)

    
    self.player = player
    self.combat = combat
    self.screenWidth = screenWidth
    self.screenHeight = screenHeight
    
    -- Create battle canvas
    self.battleCanvas = BattleCanvas.new()
    self.battleCanvas:setBackgroundType() -- Random background
    
    -- Track battle events for effects
    self.lastPlayerAttack = 0
    self.lastEnemyAttack = 0
    
    return self
end

-- Update combat UI state
function CombatUI.update(self, dt)
    -- Update the battle canvas
    -- Check if player just attacked
    if self.combat.playerAttackTimer < 0.2 and self.lastPlayerAttack > 0.8 then
        -- Add attack effect
        if math.random() < Config.combat.critChance then
            -- Critical hit effect
            self.battleCanvas:addEffect("slash", 
                3*self.screenWidth/4, 
                self.screenHeight/2, 
                {
                    duration = 0.8,
                    color = {1, 1, 0.2, 1}, 
                    size = 40,
                    angle = math.pi / 4
                }
            )
            
            self.battleCanvas:addEffect("impact", 
                3*self.screenWidth/4, 
                self.screenHeight/2, 
                {
                    duration = 0.6,
                    color = {1, 0.7, 0, 1}, 
                    size = 30
                }
            )
        else
            -- Normal hit effect
            self.battleCanvas:addEffect("slash", 
                3*self.screenWidth/4, 
                self.screenHeight/2, 
                {
                    duration = 0.5,
                    color = {0.9, 0.9, 1, 1}, 
                    size = 30,
                    angle = math.pi / 4
                }
            )
        end
    end
    
    -- Check if enemy just attacked
    if self.combat.enemyAttackTimer < 0.2 and self.lastEnemyAttack > 0.8 then
        -- Add attack effect
        if math.random() < Config.combat.critChance then
            -- Critical hit effect
            self.battleCanvas:addEffect("slash", 
                self.screenWidth/4, 
                self.screenHeight/2, 
                {
                    duration = 0.8,
                    color = {1, 0, 0, 1}, 
                    size = 40,
                    angle = -math.pi / 4
                }
            )
            
            self.battleCanvas:addEffect("impact", 
                self.screenWidth/4, 
                self.screenHeight/2, 
                {
                    duration = 0.6,
                    color = {1, 0.2, 0.2, 1}, 
                    size = 30
                }
            )
        else
            -- Normal hit effect
            self.battleCanvas:addEffect("slash", 
                self.screenWidth/4, 
                self.screenHeight/2, 
                {
                    duration = 0.5,
                    color = {1, 0.4, 0.4, 1}, 
                    size = 30,
                    angle = -math.pi / 4
                }
            )
        end
    end
    
    -- Save current attack timers for next frame
    self.lastPlayerAttack = self.combat.playerAttackTimer
    self.lastEnemyAttack = self.combat.enemyAttackTimer
end

-- Draw the combat screen
function CombatUI.draw(self,currentFrame)
    -- Draw fullscreen battle background
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)
    
    -- Draw title (smaller font)
    local titleFont = love.graphics.newFont(Config.fontPath, Config.defaultFontSize)
    love.graphics.setFont(titleFont)
    love.graphics.setColor(Config.colors.text)
    love.graphics.printf("BATTLE!", 0, 10, self.screenWidth, "center")
    local defaultFont = love.graphics.newFont(Config.fontPath, Config.smallFontSize)
    love.graphics.setFont(defaultFont)
    
    -- Draw battle background
    drawBattleBackground(self, currentFrame)
    
    -- Draw player
    drawCombatEntity(self.player, self.screenWidth/4, self.screenHeight/2, self.combat.playerAttackTimer,true)
    
    -- Draw enemy
    drawCombatEntity(self.combat.enemy, 3*self.screenWidth/4, self.screenHeight/2, self.combat.enemyAttackTimer,false)
    
    -- Draw combat messages (smaller text, closer to action)
    love.graphics.setColor(Config.colors.text)
    local messageStartY = self.screenHeight - 200  -- Moved up closer to the battle
    for i, msg in ipairs(self.combat.messages) do
        love.graphics.printf(msg, 20, messageStartY + (i-1)*18, self.screenWidth - 40, "left")
    end
    
    -- Show battle speed indicator (smaller text)
    love.graphics.setColor(Config.colors.highlight)
    love.graphics.printf("Speed: " .. string.format("%.1f", Config.combat.battleSpeed) .. " (+/-)", 
                        0, 30, self.screenWidth, "center")
    
    -- Draw VS text (smaller)
    love.graphics.setColor(Config.colors.highlight)
    love.graphics.printf("VS", self.screenWidth/2 - 15, self.screenHeight/2 - 10, 30, "center")
    
    -- Draw turn timer bars (smaller)
    local barWidth = 100
    local barHeight = 8
    
    -- Player attack bar
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", self.screenWidth/4 - barWidth/2, self.screenHeight/2 + 40, barWidth, barHeight)
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.rectangle("fill", self.screenWidth/4 - barWidth/2, self.screenHeight/2 + 40, barWidth * self.combat.playerAttackTimer, barHeight)
    
    -- Enemy attack bar
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 3*self.screenWidth/4 - barWidth/2, self.screenHeight/2 + 40, barWidth, barHeight)
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.rectangle("fill", 3*self.screenWidth/4 - barWidth/2, self.screenHeight/2 + 40, barWidth * self.combat.enemyAttackTimer, barHeight)
    
    -- Draw spell info panel
    self:drawSpellPanel()
    
    -- Magic effects removed - to be rebuilt later
end

-- Draw spell information panel (smaller)
function CombatUI.drawSpellPanel(self)
    local panelX = 10
    local panelY = 50
    local panelWidth = 250
    local panelHeight = 150
    
    -- Background panel
    love.graphics.setColor(Config.colors.panel)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight)
    love.graphics.setColor(Config.colors.panelBorder)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight)
    
    -- Title (smaller font)
    local smallFont = love.graphics.newFont(Config.fontPath, Config.smallFontSize)
    love.graphics.setFont(smallFont)
    love.graphics.setColor(Config.colors.text)
    love.graphics.print("Spells:", panelX + 5, panelY + 5)
    
    -- List spells (compact)
    local spellInfo = self.combat:getSpellInfo(self.player)
    for i, spell in ipairs(spellInfo) do
        local y = panelY + 20 + (i-1) * 20
        
        -- Color based on whether spell can be cast
        if spell.canCast then
            love.graphics.setColor(Config.colors.ready)
        else
            love.graphics.setColor(Config.colors.cooldown)
        end
        
        -- Display spell name and info (compact)
        local spellText = i .. ". " .. spell.icon .. spell.name
        if spell.currentCooldown > 0 then
            spellText = spellText .. " [" .. spell.currentCooldown .. "]"
        else
            spellText = spellText .. " (" .. spell.manaCost .. ")"
        end
        
        love.graphics.print(spellText, panelX + 5, y)
    end
    
    -- Instructions (smaller)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("1-7: cast spell", panelX + 5, panelY + panelHeight - 15)
end

function drawBattleBackground(combatUI, currentFrame)
    -- Draw a dynamic battle background with noise patterns
    
    for y = 0, combatUI.screenHeight, 20 do
        for x = 0, combatUI.screenWidth, 20 do
            local noise = love.math.noise(x * 0.01, y * 0.01, currentFrame)
            love.graphics.setColor(0.1 + noise * 0.1, 0.1 + noise * 0.05, 0.2 + noise * 0.1)
            love.graphics.rectangle("fill", x, y, 20, 20)
        end
    end
    
    -- Draw some dynamic effects
    for i = 1, 10 do
        local x = (combatUI.screenWidth/2) + math.cos(currentFrame * 2 + i) * combatUI.screenWidth * 0.4
        local y = combatUI.screenHeight * 0.7 + math.sin(currentFrame * 3 + i) * combatUI.screenHeight * 0.2
        local size = 5 + math.sin(currentFrame * 4 + i) * 10
        
        love.graphics.setColor(0.8, 0.4, 0.1, 0.2)
        love.graphics.circle("fill", x, y, size)
    end
end

function drawCombatEntity(entity, x, y, timer, isPlayer)
    -- Draw character with attack animation (smaller)
    local charSize = 24
    
    -- Add shaking when about to attack
    local shake = 0
    if timer > 0.8 then
        shake = math.random(-2, 2)
    end
    
    -- Add visual feedback for attacks
    local size = 1.0
    if timer < 0.2 then
        size = 1.2 -- "Pop" effect right after attacking
    end
    
    love.graphics.setFont(love.graphics.newFont(charSize * size))
    love.graphics.setColor(entity.color)
    love.graphics.printf(entity.char, x - charSize + shake, y - charSize/2 + shake, charSize * 2, "center")
    local smallFont = love.graphics.newFont(Config.fontPath, Config.smallFontSize)
    love.graphics.setFont(smallFont)
    
    -- Draw name and stats (smaller)
    love.graphics.setColor(Config.colors.text)
    love.graphics.printf(isPlayer and "You" or entity.name, x - 80, y - 45, 160, "center")
    
    -- HP bar (smaller)
    local barWidth = 80
    local barHeight = 8
    local hpRatio = entity.hp / entity.maxHp
    
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", x - barWidth/2, y + 20, barWidth, barHeight)
    love.graphics.setColor(Config.colors.health)
    love.graphics.rectangle("fill", x - barWidth/2, y + 20, barWidth * hpRatio, barHeight)
    
    -- HP text (smaller)
    love.graphics.setColor(Config.colors.text)
    love.graphics.printf(entity.hp .. "/" .. entity.maxHp, x - 40, y + 30, 80, "center")
    
    -- Combat stats (smaller)
    if isPlayer then
        love.graphics.printf("ATK:" .. entity.attack .. " DEF:" .. entity:getCurrentDefense(), x - 80, y + 45, 160, "center")
        
        -- Draw mana bar for player (smaller)
        local manaRatio = entity.mana / entity.maxMana
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", x - barWidth/2, y + 60, barWidth, 6)
        love.graphics.setColor(Config.colors.mana)
        love.graphics.rectangle("fill", x - barWidth/2, y + 60, barWidth * manaRatio, 6)
        
        -- Mana text (smaller)
        love.graphics.setColor(Config.colors.text)
        love.graphics.printf("MP:" .. entity.mana .. "/" .. entity.maxMana, x - 40, y + 70, 80, "center")
    else
        love.graphics.printf("ATK:" .. entity.attack .. " DEF:" .. entity.defense, x - 80, y + 45, 160, "center")
    end
    
    -- Draw combat effects
    if timer < 0.3 then -- Just attacked
        for i = 1, 5 do
            local angle = math.random() * math.pi * 2
            local dist = math.random(20, 40)
            local px = x + math.cos(angle) * dist
            local py = y + math.sin(angle) * dist
            love.graphics.setColor(1, 1, 0, 1 - timer/0.3)
            love.graphics.circle("fill", px, py, 2)
        end
    end
end



-- Draw the game over screen
function CombatUI.drawGameOver(self, playerLevel)
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)
    
    local bigFont = love.graphics.newFont(Config.fontPath, Config.bigFontSize)
    love.graphics.setFont(bigFont)
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.printf("GAME OVER", 0, self.screenHeight/3, self.screenWidth, "center")
    
    local defaultFont = love.graphics.newFont(Config.fontPath, Config.defaultFontSize)
    love.graphics.setFont(defaultFont)
    love.graphics.setColor(Config.colors.text)
    love.graphics.printf("You reached level " .. playerLevel, 0, self.screenHeight/3 + 50, self.screenWidth, "center")
    
    love.graphics.printf("Press ENTER to play again", 0, self.screenHeight/3 + 100, self.screenWidth, "center")
end



-- Add a visual effect to the battle
function CombatUI.addEffect(self, effectType, x, y, options)
    return self.battleCanvas:addEffect(effectType, x, y, options)
end

-- Handle keyboard input in combat
function CombatUI.keypressed(self, key)
    if key == "+" or key == "=" then
        -- Increase battle speed
        self.combat:adjustSpeed(0.1)
        return true
    elseif key == "-" then
        -- Decrease battle speed
        self.combat:adjustSpeed(-0.1)
        return true
    elseif key == "b" then
        -- Cycle through backgrounds
        local bgTypes = self.battleCanvas.backgroundTypes
        local currentIndex = 1
        
        for i, bgType in ipairs(bgTypes) do
            if bgType == self.battleCanvas.backgroundType then
                currentIndex = i
                break
            end
        end
        
    end
    
    return false
end

return CombatUI