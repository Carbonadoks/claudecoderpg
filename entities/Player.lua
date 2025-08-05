-- entities/Player.lua
-- Player character implementation

local Entity = require("entities/Entity")
local Config = require("config/Config")
local Utils = require("utils/Utils")

local Player = setmetatable({}, {__index = Entity})
Player.__index = Player

-- Create a new player
function Player.new(x, y)
    local self = setmetatable(Entity.new(x, y, "@", Config.colors.player), Player)
    
    -- Stats
    self.hp = 100
    self.maxHp = 100
    self.mana = 50
    self.maxMana = 50
    self.attack = 15
    self.defense = 5
    self.speed = 10
    self.level = 1
    self.xp = 0
    self.xpToLevel = 100
    
    -- State
    self.isMoving = false
    self.inventory = {}
    self.knownSpells = {1, 5} -- Start with Magic Missile and Heal
    self.activeBuffs = {}
    self.manaRegenRate = 1 -- Mana per turn
    self.spellCooldowns = {} -- Track individual spell cooldowns
    self.skills = {
        {
            name = "Basic Attack",
            description = "Standard attack with your weapon",
            damageMultiplier = 1.0,
            cooldown = 0,
            currentCooldown = 0
        },
        {
            name = "Power Strike",
            description = "Deals 150% damage (3 turn cooldown)",
            damageMultiplier = 1.5,
            cooldown = 3,
            currentCooldown = 0
        },
        {
            name = "Double Slash",
            description = "Strike twice at 75% damage (4 turn cooldown)",
            damageMultiplier = 0.75,
            hits = 2,
            cooldown = 4,
            currentCooldown = 0
        },
        {
            name = "Shield Bash",
            description = "100% damage + 2 defense for 2 turns (5 turn cooldown)",
            damageMultiplier = 1.0,
            defenseBoost = 2,
            duration = 2,
            cooldown = 5,
            currentCooldown = 0
        }
    }
    return self
end

-- Update player state
function Player.update(self, dt, currentFrame)
    -- Animate the player with a subtle breathing effect
    self.animationOffset = math.sin(currentFrame * 2 * math.pi) * 2
end

-- Try to move the player in a direction
function Player.move(self, dx, dy, map, entities)
    local newX, newY = self.x + dx, self.y + dy
    
    -- Check if tile is walkable (map will generate chunks as needed)
    if not map:isWalkable(newX, newY) then
        return false, "blocked"
    end
    
    -- Check for entities at destination
    for _, entity in ipairs(entities.enemies) do
        if entity.x == newX and entity.y == newY then
            return false, "enemy", entity
        end
    end
    
    for i, item in ipairs(entities.items) do
        if item.x == newX and item.y == newY then
            self.x, self.y = newX, newY
            return true, "item", item, i
        end
    end
    
    -- Move the player
    self.x, self.y = newX, newY
    return true
end

-- Pick up an item
function Player.pickupItem(self, item)
    local effect = ""
    
    if item.effect == "heal" then
        self.hp = math.min(self.hp + item.value, self.maxHp)
        effect = "Healed for " .. item.value .. " HP"
    elseif item.effect == "mana" then
        self.mana = math.min(self.mana + item.value, self.maxMana)
        effect = "Restored " .. item.value .. " mana"
    elseif item.effect == "attack" then
        self.attack = self.attack + item.value
        effect = "Attack increased by " .. item.value
    elseif item.effect == "defense" then
        self.defense = self.defense + item.value
        effect = "Defense increased by " .. item.value
    elseif item.effect == "speed" then
        self.speed = self.speed + item.value
        effect = "Speed increased by " .. item.value
    elseif item.effect == "gold" then
        table.insert(self.inventory, item)
        effect = "Found " .. item.value .. " gold"
    end
    
    return "Picked up " .. item.name .. "! " .. effect
end

-- Level up the player
function Player.levelUp(self)
    self.level = self.level + 1
    self.xp = self.xp - self.xpToLevel
    self.xpToLevel = math.floor(self.xpToLevel * 1.5)
    
    -- Improve stats
    self.maxHp = self.maxHp + 10
    self.hp = self.maxHp
    self.maxMana = self.maxMana + 5
    self.mana = self.maxMana
    self.attack = self.attack + 2
    self.defense = self.defense + 1
    self.speed = self.speed + 1
    
    -- Learn new spells at certain levels
    if self.level == 3 and not self:knowsSpell(2) then
        table.insert(self.knownSpells, 2) -- Fireball
        return "LEVEL UP! You are now level " .. self.level .. " and learned Fireball!"
    elseif self.level == 5 and not self:knowsSpell(3) then
        table.insert(self.knownSpells, 3) -- Ice Shard
        return "LEVEL UP! You are now level " .. self.level .. " and learned Ice Shard!"
    elseif self.level == 7 and not self:knowsSpell(4) then
        table.insert(self.knownSpells, 4) -- Lightning Bolt
        return "LEVEL UP! You are now level " .. self.level .. " and learned Lightning Bolt!"
    end
    
    return "LEVEL UP! You are now level " .. self.level
end

-- Check if player knows a spell
function Player.knowsSpell(self, spellIndex)
    for _, knownIndex in ipairs(self.knownSpells) do
        if knownIndex == spellIndex then
            return true
        end
    end
    return false
end

-- Check if a spell can be cast (mana + cooldown)
function Player.canCastSpell(self, spellIndex)
    if not self:knowsSpell(spellIndex) then
        return false
    end
    
    local spell = Config.spells[spellIndex]
    if not spell then
        return false
    end
    
    -- Check cooldown
    if self.spellCooldowns[spellIndex] and self.spellCooldowns[spellIndex] > 0 then
        return false
    end
    
    -- Check mana
    if self.mana < spell.manaCost then
        return false
    end
    
    return true
end

-- Get spell cooldown remaining
function Player.getSpellCooldown(self, spellIndex)
    return self.spellCooldowns[spellIndex] or 0
end

-- Cast a spell
function Player.castSpell(self, spellIndex, target)
    if not self:knowsSpell(spellIndex) then
        return false, "You don't know that spell!"
    end
    
    local spell = Config.spells[spellIndex]
    
    -- Check if spell is on cooldown
    if self.spellCooldowns[spellIndex] and self.spellCooldowns[spellIndex] > 0 then
        return false, spell.name .. " is on cooldown! (" .. self.spellCooldowns[spellIndex] .. " turns left)"
    end
    
    if self.mana < spell.manaCost then
        return false, "Not enough mana! Need " .. spell.manaCost .. ", have " .. self.mana
    end
    
    self.mana = self.mana - spell.manaCost
    
    -- Set spell on cooldown
    if spell.cooldown and spell.cooldown > 0 then
        self.spellCooldowns[spellIndex] = spell.cooldown
    end
    
    local result = {
        spell = spell,
        damage = 0,
        healing = 0
    }
    
    if spell.type == "damage" then
        result.damage = math.random(spell.damage[1], spell.damage[2])
        
    elseif spell.type == "heal" then
        result.healing = math.random(spell.healing[1], spell.healing[2])
        self.hp = math.min(self.maxHp, self.hp + result.healing)
        
    elseif spell.type == "buff" then
        local buff = {
            name = spell.name,
            duration = spell.duration
        }
        if spell.defenseBoost then
            buff.defenseBoost = spell.defenseBoost
        end
        if spell.speedBoost then
            buff.speedBoost = spell.speedBoost
        end
        table.insert(self.activeBuffs, buff)
    end
    
    return true, result
end

-- Update buffs and regenerate mana
function Player.updateMagic(self)
    -- Regenerate mana
    self.mana = math.min(self.maxMana, self.mana + self.manaRegenRate)
    
    -- Update active buffs
    for i = #self.activeBuffs, 1, -1 do
        local buff = self.activeBuffs[i]
        buff.duration = buff.duration - 1
        if buff.duration <= 0 then
            table.remove(self.activeBuffs, i)
        end
    end
    
    -- Update spell cooldowns
    for spellIndex, cooldown in pairs(self.spellCooldowns) do
        if cooldown > 0 then
            self.spellCooldowns[spellIndex] = cooldown - 1
            if self.spellCooldowns[spellIndex] <= 0 then
                self.spellCooldowns[spellIndex] = nil -- Remove completed cooldowns
            end
        end
    end
end

-- Get current defense including buffs
function Player.getCurrentDefense(self)
    local defense = self.defense
    for _, buff in ipairs(self.activeBuffs) do
        if buff.defenseBoost then
            defense = defense + buff.defenseBoost
        end
    end
    return defense
end

-- Get current speed including buffs
function Player.getCurrentSpeed(self)
    local speed = self.speed
    for _, buff in ipairs(self.activeBuffs) do
        if buff.speedBoost then
            speed = speed + buff.speedBoost
        end
    end
    return speed
end

-- Draw player stats UI
function Player.drawStats(self)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    love.graphics.setColor(Config.colors.text)
    
    local statsX = screenWidth - 230
    local statsY = screenHeight - 320
    local statBlockWidth = 240
    local statBlockHeight = 95

    -- Background panel
    love.graphics.setColor(Config.colors.panel)
    love.graphics.rectangle("fill", statsX-11, statsY-11, statBlockWidth, statBlockHeight)
    love.graphics.setColor(Config.colors.panelBorder)
    love.graphics.rectangle("line", statsX-11, statsY-11, statBlockWidth, statBlockHeight)
    
    -- Basic stats
    love.graphics.setColor(Config.colors.text)
    love.graphics.print("Level: " .. self.level, statsX, statsY)
    love.graphics.print("XP: " .. self.xp .. "/" .. self.xpToLevel, statsX, statsY + 20)
    love.graphics.print("ATK: " .. self.attack .. " DEF: " .. self:getCurrentDefense() .. " SPD: " .. self:getCurrentSpeed(), statsX, statsY + 40)
    
    -- HP bar
    local barWidth = 100
    local hpRatio = self.hp / self.maxHp
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", statsX + 100, statsY, barWidth, 15)
    love.graphics.setColor(Config.colors.health)
    love.graphics.rectangle("fill", statsX + 100, statsY, barWidth * hpRatio, 15)
    love.graphics.setColor(Config.colors.text)
    love.graphics.print("HP: " .. self.hp .. "/" .. self.maxHp, statsX + 205, statsY)
    
    -- Mana bar
    local manaRatio = self.mana / self.maxMana
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", statsX + 100, statsY + 20, barWidth, 15)
    love.graphics.setColor(Config.colors.mana)
    love.graphics.rectangle("fill", statsX + 100, statsY + 20, barWidth * manaRatio, 15)
    love.graphics.setColor(Config.colors.text)
    love.graphics.print("MP: " .. self.mana .. "/" .. self.maxMana, statsX + 205, statsY + 20)
    
    -- Active buffs
    if #self.activeBuffs > 0 then
        love.graphics.print("Buffs:", statsX, statsY + 60)
        for i, buff in ipairs(self.activeBuffs) do
            love.graphics.setColor(0, 1, 0)
            love.graphics.print(buff.name .. " (" .. buff.duration .. ")", statsX + 40 + (i-1)*80, statsY + 60)
        end
    end
end

return Player