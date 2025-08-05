-- ui/CharacterMenu.lua
-- Character menu for displaying detailed player information

local UI = require("ui/UI")
local Config = require("config/Config")

local CharacterMenu = setmetatable({}, {__index = UI})
CharacterMenu.__index = CharacterMenu

-- Create a new character menu
function CharacterMenu.new(player)
    local self = setmetatable(UI.new(), CharacterMenu)
    
    self.player = player
    self.isVisible = false
    
    return self
end

-- Toggle menu visibility
function CharacterMenu.toggle(self)
    self.isVisible = not self.isVisible
end

-- Show the menu
function CharacterMenu.show(self)
    self.isVisible = true
end

-- Hide the menu
function CharacterMenu.hide(self)
    self.isVisible = false
end

-- Update the menu
function CharacterMenu.update(self, dt)
    -- Nothing to update for now
end

-- Draw the character menu
function CharacterMenu.draw(self)
    if not self.isVisible then
        return
    end
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Menu dimensions
    local menuWidth = 500
    local menuHeight = 600
    local menuX = (screenWidth - menuWidth) / 2
    local menuY = (screenHeight - menuHeight) / 2
    
    -- Semi-transparent background overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Main menu panel
    love.graphics.setColor(Config.colors.panel)
    love.graphics.rectangle("fill", menuX, menuY, menuWidth, menuHeight)
    love.graphics.setColor(Config.colors.panelBorder)
    love.graphics.rectangle("line", menuX, menuY, menuWidth, menuHeight)
    
    -- Title
    local bigFont = love.graphics.newFont(Config.fontPath, Config.bigFontSize)
    love.graphics.setFont(bigFont)
    love.graphics.setColor(Config.colors.text)
    love.graphics.printf("CHARACTER", menuX, menuY + 20, menuWidth, "center")
    
    -- Reset to default font
    local defaultFont = love.graphics.newFont(Config.fontPath, Config.defaultFontSize)
    love.graphics.setFont(defaultFont)
    
    local contentY = menuY + 60
    local leftCol = menuX + 30
    local rightCol = menuX + 260
    local lineHeight = 25
    
    -- Basic Information Section
    love.graphics.setColor(0.8, 0.8, 0.2)
    love.graphics.print("═══ BASIC INFO ═══", leftCol, contentY)
    contentY = contentY + lineHeight + 10
    
    love.graphics.setColor(Config.colors.text)
    love.graphics.print("Name: Adventurer", leftCol, contentY)
    contentY = contentY + lineHeight
    love.graphics.print("Level: " .. self.player.level, leftCol, contentY)
    contentY = contentY + lineHeight
    love.graphics.print("Experience: " .. self.player.xp .. " / " .. self.player.xpToLevel, leftCol, contentY)
    
    -- XP Progress Bar
    local barWidth = 200
    local barHeight = 12
    local xpRatio = self.player.xp / self.player.xpToLevel
    contentY = contentY + lineHeight
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", leftCol, contentY, barWidth, barHeight)
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.rectangle("fill", leftCol, contentY, barWidth * xpRatio, barHeight)
    love.graphics.setColor(Config.colors.panelBorder)
    love.graphics.rectangle("line", leftCol, contentY, barWidth, barHeight)
    
    contentY = contentY + lineHeight + 20
    
    -- Stats Section
    love.graphics.setColor(0.8, 0.8, 0.2)
    love.graphics.print("═══ ATTRIBUTES ═══", leftCol, contentY)
    contentY = contentY + lineHeight + 10
    
    love.graphics.setColor(Config.colors.text)
    love.graphics.print("Health: " .. self.player.hp .. " / " .. self.player.maxHp, leftCol, contentY)
    love.graphics.print("Mana: " .. self.player.mana .. " / " .. self.player.maxMana, rightCol, contentY)
    contentY = contentY + lineHeight
    
    love.graphics.print("Attack: " .. self.player.attack, leftCol, contentY)
    love.graphics.print("Defense: " .. self.player:getCurrentDefense(), rightCol, contentY)
    contentY = contentY + lineHeight
    
    love.graphics.print("Speed: " .. self.player:getCurrentSpeed(), leftCol, contentY)
    love.graphics.print("Mana Regen: " .. self.player.manaRegenRate .. "/turn", rightCol, contentY)
    
    contentY = contentY + lineHeight + 20
    
    -- Health and Mana Bars
    love.graphics.setColor(0.8, 0.8, 0.2)
    love.graphics.print("═══ VITALS ═══", leftCol, contentY)
    contentY = contentY + lineHeight + 10
    
    -- Health Bar
    local hpRatio = self.player.hp / self.player.maxHp
    love.graphics.setColor(Config.colors.text)
    love.graphics.print("Health:", leftCol, contentY)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", leftCol + 70, contentY + 2, barWidth, barHeight)
    love.graphics.setColor(Config.colors.health)
    love.graphics.rectangle("fill", leftCol + 70, contentY + 2, barWidth * hpRatio, barHeight)
    love.graphics.setColor(Config.colors.panelBorder)
    love.graphics.rectangle("line", leftCol + 70, contentY + 2, barWidth, barHeight)
    
    contentY = contentY + lineHeight
    
    -- Mana Bar
    local manaRatio = self.player.mana / self.player.maxMana
    love.graphics.setColor(Config.colors.text)
    love.graphics.print("Mana:", leftCol, contentY)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", leftCol + 70, contentY + 2, barWidth, barHeight)
    love.graphics.setColor(Config.colors.mana)
    love.graphics.rectangle("fill", leftCol + 70, contentY + 2, barWidth * manaRatio, barHeight)
    love.graphics.setColor(Config.colors.panelBorder)
    love.graphics.rectangle("line", leftCol + 70, contentY + 2, barWidth, barHeight)
    
    contentY = contentY + lineHeight + 20
    
    -- Skills Section
    love.graphics.setColor(0.8, 0.8, 0.2)
    love.graphics.print("═══ COMBAT SKILLS ═══", leftCol, contentY)
    contentY = contentY + lineHeight + 10
    
    love.graphics.setColor(Config.colors.text)
    for i, skill in ipairs(self.player.skills) do
        local skillColor = Config.colors.text
        if skill.currentCooldown > 0 then
            skillColor = Config.colors.cooldown
        else
            skillColor = Config.colors.ready
        end
        
        love.graphics.setColor(skillColor)
        love.graphics.print(skill.name, leftCol, contentY)
        
        love.graphics.setColor(Config.colors.text)
        local cooldownText = ""
        if skill.currentCooldown > 0 then
            cooldownText = " (CD: " .. skill.currentCooldown .. ")"
        elseif skill.cooldown > 0 then
            cooldownText = " (CD: " .. skill.cooldown .. ")"
        end
        love.graphics.print(cooldownText, leftCol + 150, contentY)
        
        contentY = contentY + lineHeight
    end
    
    contentY = contentY + 10
    
    -- Spells Section
    love.graphics.setColor(0.8, 0.8, 0.2)
    love.graphics.print("═══ KNOWN SPELLS ═══", leftCol, contentY)
    contentY = contentY + lineHeight + 10
    
    love.graphics.setColor(Config.colors.text)
    for i, spellIndex in ipairs(self.player.knownSpells) do
        local spell = Config.spells[spellIndex]
        if spell then
            local canCast = self.player:canCastSpell(spellIndex)
            local cooldown = self.player:getSpellCooldown(spellIndex)
            
            if canCast then
                love.graphics.setColor(Config.colors.mana)
            else
                love.graphics.setColor(Config.colors.cooldown)
            end
            
            love.graphics.print(i .. ". " .. spell.name, leftCol, contentY)
            love.graphics.setColor(Config.colors.text)
            
            local costText = "(" .. spell.manaCost .. " MP"
            if cooldown > 0 then
                costText = costText .. ", CD: " .. cooldown .. ")"
            else
                costText = costText .. ")"
            end
            
            love.graphics.print(costText, leftCol + 150, contentY)
            contentY = contentY + lineHeight
        end
    end
    
    -- Active Buffs Section
    if #self.player.activeBuffs > 0 then
        contentY = contentY + 10
        love.graphics.setColor(0.8, 0.8, 0.2)
        love.graphics.print("═══ ACTIVE BUFFS ═══", leftCol, contentY)
        contentY = contentY + lineHeight + 10
        
        for _, buff in ipairs(self.player.activeBuffs) do
            love.graphics.setColor(0, 1, 0)
            love.graphics.print(buff.name, leftCol, contentY)
            love.graphics.setColor(Config.colors.text)
            love.graphics.print("(" .. buff.duration .. " turns left)", leftCol + 150, contentY)
            contentY = contentY + lineHeight
        end
    end
    
    -- Inventory Section
    contentY = contentY + 10
    love.graphics.setColor(0.8, 0.8, 0.2)
    love.graphics.print("═══ INVENTORY ═══", leftCol, contentY)
    contentY = contentY + lineHeight + 10
    
    if #self.player.inventory > 0 then
        love.graphics.setColor(Config.colors.text)
        local goldTotal = 0
        for _, item in ipairs(self.player.inventory) do
            if item.effect == "gold" then
                goldTotal = goldTotal + item.value
            end
        end
        if goldTotal > 0 then
            love.graphics.print("Gold: " .. goldTotal, leftCol, contentY)
        else
            love.graphics.print("Empty", leftCol, contentY)
        end
    else
        love.graphics.setColor(Config.colors.text)
        love.graphics.print("Empty", leftCol, contentY)
    end
    
    -- Controls
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("Press 'C' to close", menuX, menuY + menuHeight - 40, menuWidth, "center")
end

return CharacterMenu