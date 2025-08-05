-- systems/Combat.lua
-- Enhanced combat system with skills and magic for battles between player and enemies

local Config = require("config/Config")
local Combat = {}
Combat.__index = Combat

-- Define player skills
local Skills = {
    {
        name = "Fireball",
        description = "Deal high damage with a chance to burn the enemy",
        damageMultiplier = 1.5,
        cooldown = 3,
        currentCooldown = 0,
        specialEffect = function(self, player, enemy)
            if math.random() < 0.3 then -- 30% chance to burn
                enemy.status = {
                    type = "burn",
                    duration = 3,
                    damage = math.floor(player.attack * 0.2),
                    message = enemy.name .. " is burning!"
                }
                self:addMessage(enemy.name .. " is burning!")
            end
        end
    },
    {
        name = "Heal",
        description = "Restore some of your health",
        cooldown = 4,
        currentCooldown = 0,
        healing = function(player)
            return math.floor(player.maxHp * 0.2) -- Heal 20% of max HP
        end,
        specialEffect = function(self, player)
            local healAmount = math.floor(player.maxHp * 0.2)
            player.hp = math.min(player.maxHp, player.hp + healAmount)
            self:addMessage("You restored " .. healAmount .. " health!")
        end
    },
    {
        name = "Shield Bash",
        description = "Deal damage and reduce enemy attack",
        damageMultiplier = 0.8,
        cooldown = 3,
        currentCooldown = 0,
        specialEffect = function(self, player, enemy)
            local reduction = math.max(1, math.floor(enemy.attack * 0.15))
            enemy.attackReduction = (enemy.attackReduction or 0) + reduction
            enemy.attackReductionDuration = 2
            self:addMessage(enemy.name .. "'s attack reduced by " .. reduction .. "!")
        end
    },
    {
        name = "Critical Strike",
        description = "Attack with a high chance to critically hit",
        damageMultiplier = 1.0,
        cooldown = 2,
        currentCooldown = 0,
        critChance = 0.7,
        critMultiplier = 2.5,
        specialEffect = function() end -- No additional effect
    },
    {
        name = "Vampiric Strike",
        description = "Deal damage and heal for a portion of the damage dealt",
        damageMultiplier = 0.9,
        cooldown = 3,
        currentCooldown = 0,
        specialEffect = function(self, player, enemy, damage)
            local healAmount = math.floor(damage * 0.5)
            player.hp = math.min(player.maxHp, player.hp + healAmount)
            self:addMessage("You leeched " .. healAmount .. " health!")
        end
    }
}

-- Create a new combat instance
function Combat.new(hud)
    local self = setmetatable({}, Combat)
    
    self.enemy = nil
    self.turnCount = 0
    self.playerAttackTimer = 0
    self.enemyAttackTimer = 0
    self.messages = {}
    self.maxMessages = Config.combat.maxMessages
    self.isOver = false
    self.result = nil
    self.battleSpeed = Config.combat.battleSpeed
    self.hud = hud
    
    -- Initialize player skills
    self.availableSkills = {}
    self.skillCooldowns = {}
    
    -- Player's current skill selection
    self.playerSkills = {}
    self.selectedSkillIndex = nil  -- For manual skill activation
    self.selectedSpellIndex = nil  -- For spell casting
    self.autoUseSkills = true      -- For auto-battle
    
    return self
end

-- Start combat with an enemy
function Combat.start(self, player, enemy)
    self.enemy = enemy
    self.turnCount = 0
    self.playerAttackTimer = 0
    self.enemyAttackTimer = enemy.speed * 0.1
    self.messages = {}
    self.isOver = false
    self.result = nil
    self.battleSpeed = Config.combat.battleSpeed
    self.endMessagesAdded = false  -- Initialize flag to prevent message spam
    
    -- Initialize enemy status effects
    self.enemy.status = nil
    self.enemy.attackReduction = 0
    self.enemy.attackReductionDuration = 0
    
    -- Assign random skills to the player at the start of combat
    self:assignRandomSkills(player)
    
    self:addMessage("Battle with " .. enemy.name .. " started!")
    self:addMessage("Your skills: " .. self:getSkillListString())
    
    return self
end

-- Assign random skills to the player
function Combat.assignRandomSkills(self, player)
    -- Clear existing skills
    self.playerSkills = {}
    self.skillCooldowns = {}
    
    -- Get a copy of all skills
    local availableSkills = {}
    for i, skill in ipairs(Skills) do
        table.insert(availableSkills, skill)
    end
    
    -- Select 3 random skills for this battle
    local numSkills = math.min(3, #availableSkills)
    for i = 1, numSkills do
        local skillIndex = math.random(1, #availableSkills)
        local skill = availableSkills[skillIndex]
        
        -- Deep copy the skill to avoid reference issues
        local skillCopy = {}
        for k, v in pairs(skill) do
            skillCopy[k] = v
        end
        
        -- Reset cooldown
        skillCopy.currentCooldown = 0
        
        table.insert(self.playerSkills, skillCopy)
        table.remove(availableSkills, skillIndex)
        
        -- Initialize cooldown tracker
        self.skillCooldowns[#self.playerSkills] = 0
    end
end

-- Get a string listing all current skills
function Combat.getSkillListString(self)
    local skillList = ""
    for i, skill in ipairs(self.playerSkills) do
        if i > 1 then
            skillList = skillList .. ", "
        end
        skillList = skillList .. skill.name
    end
    return skillList
end

-- Update combat state
function Combat.update(self, dt, player)
    if self.isOver then
        return self.result -- Return the result even when combat is over
    end
    
    -- Update attack timers - scaled by target FPS (60) and battle speed
    self.playerAttackTimer = self.playerAttackTimer + dt * player.speed * 60/100 * self.battleSpeed
    self.enemyAttackTimer = self.enemyAttackTimer + dt * self.enemy.speed * 60/100 * self.battleSpeed
    
    -- Update skill cooldowns
    for i, skill in ipairs(self.playerSkills) do
        if skill.currentCooldown > 0 then
            skill.currentCooldown = math.max(0, skill.currentCooldown - dt * self.battleSpeed)
        end
    end
    
    -- Player attack
    if self.playerAttackTimer >= 1 then
        self.playerAttackTimer = self.playerAttackTimer - 1
        
        -- Try to use a spell or skill if auto usage is enabled
        if self.autoUseSkills then
            local actionUsed = self:tryUseSpell(player) or self:tryUseSkill(player)
            if not actionUsed then
                self:playerAttack(player) -- Regular attack if no action was used
            end
        else
            -- Use selected spell or skill if one is chosen, otherwise regular attack
            if self.selectedSpellIndex then
                self:castSpell(self.selectedSpellIndex, player)
                self.selectedSpellIndex = nil
            elseif self.selectedSkillIndex and self.playerSkills[self.selectedSkillIndex].currentCooldown <= 0 then
                self:useSkill(self.selectedSkillIndex, player)
                self.selectedSkillIndex = nil
            else
                self:playerAttack(player)
            end
        end
    end
    
    -- Enemy attack
    if self.enemyAttackTimer >= 1 then
        self.enemyAttackTimer = self.enemyAttackTimer - 1
        self:enemyAttack(player)
    end
    
    -- Update cooldowns and effects
    
    -- Apply status effects
    self:updateStatusEffects(player)
    
    -- Check if combat is over
    if self.enemy.hp <= 0 then
        self:addMessage("You defeated the " .. self.enemy.name .. "!")
        self:addMessage("Gained " .. self.enemy.xp .. " XP")
        self.isOver = true
        self.result = "victory"
        
        -- Award XP to player
        player.xp = player.xp + self.enemy.xp
        
        return self.result
    elseif player.hp <= 0 then
        self:addMessage("You were defeated by the " .. self.enemy.name .. "!")
        self.isOver = true
        self.result = "defeat"
        
        return self.result
    end
    
    return nil -- Combat not over yet
end

-- Try to use a random available skill
function Combat.tryUseSkill(self, player)
    -- Collect all skills that are off cooldown
    local availableSkills = {}
    for i, skill in ipairs(self.playerSkills) do
        if skill.currentCooldown <= 0 then
            table.insert(availableSkills, i)
        end
    end
    
    -- If we have skills available, use a random one
    if #availableSkills > 0 then
        local randomSkillIndex = availableSkills[math.random(1, #availableSkills)]
        self:useSkill(randomSkillIndex, player)
        return true
    end
    
    return false
end

-- Use a specific skill
function Combat.useSkill(self, skillIndex, player)
    local skill = self.playerSkills[skillIndex]
    
    self:addMessage("You use " .. skill.name .. "!")
    
    -- Handle different skill types
    if skill.damageMultiplier then
        -- Damage-dealing skill
        local damage = math.max(1, math.floor(player.attack * skill.damageMultiplier) - self.enemy.defense)
        
        -- Check for critical hit
        local isCritical = math.random() < (skill.critChance or Config.combat.critChance)
        local critMultiplier = skill.critMultiplier or Config.combat.critMultiplier
        
        if isCritical then
            damage = math.floor(damage * critMultiplier)
            self:addMessage("Critical hit! You deal " .. damage .. " damage!")
        else
            self:addMessage("You deal " .. damage .. " damage")
        end
        
        self.enemy.hp = math.max(0, self.enemy.hp - damage)
        
        -- Apply special effect
        if skill.specialEffect then
            skill.specialEffect(self, player, self.enemy, damage)
        end
    elseif skill.healing then
        -- Healing skill
        if skill.specialEffect then
            skill.specialEffect(self, player)
        end
    end
    
    -- Set cooldown
    skill.currentCooldown = skill.cooldown
end

-- Try to cast a random available spell
function Combat.tryUseSpell(self, player)
    -- Only cast spells if player has mana and knows spells
    if player.mana <= 0 or #player.knownSpells == 0 then
        return false
    end
    
    -- Collect all spells that can be cast (mana + cooldown check)
    local availableSpells = {}
    for _, spellIndex in ipairs(player.knownSpells) do
        if player:canCastSpell(spellIndex) then
            table.insert(availableSpells, spellIndex)
        end
    end
    
    -- If we have spells available, use a random one (prefer damage spells in combat)
    if #availableSpells > 0 then
        -- Prioritize damage spells over healing/buffs
        local damageSpells = {}
        local otherSpells = {}
        
        for _, spellIndex in ipairs(availableSpells) do
            local spell = Config.spells[spellIndex]
            if spell.type == "damage" then
                table.insert(damageSpells, spellIndex)
            else
                table.insert(otherSpells, spellIndex)
            end
        end
        
        -- Use damage spell 70% of the time, other spells 30%
        local useList = (#damageSpells > 0 and math.random() < 0.7) and damageSpells or otherSpells
        if #useList > 0 then
            local randomSpellIndex = useList[math.random(1, #useList)]
            self:castSpell(randomSpellIndex, player)
            return true
        end
    end
    
    return false
end

-- Cast a specific spell
function Combat.castSpell(self, spellIndex, player)
    local success, result = player:castSpell(spellIndex, self.enemy)
    
    if not success then
        self:addMessage(result) -- Error message
        return false
    end
    
    local spell = result.spell
    self:addMessage("You cast " .. spell.name .. "!")
    
    if spell.type == "damage" then
        -- Apply spell damage directly to enemy
        local damage = result.damage
        local actualDamage = math.max(1, damage - self.enemy.defense)
        self.enemy.hp = self.enemy.hp - actualDamage
        self:addMessage("You deal " .. actualDamage .. " magical damage!")
        
    elseif spell.type == "heal" then
        self:addMessage("You restored " .. result.healing .. " health!")
        
    elseif spell.type == "buff" then
        self:addMessage("You cast " .. spell.name .. "!")
    end
    
    return true
end

-- Select a spell to cast
function Combat.selectSpell(self, spellIndex, player)
    if not player:knowsSpell(spellIndex) then
        self:addMessage("You don't know that spell!")
        return false
    end
    
    if not player:canCastSpell(spellIndex) then
        local spell = Config.spells[spellIndex]
        local cooldown = player:getSpellCooldown(spellIndex)
        if cooldown > 0 then
            self:addMessage(spell.name .. " is on cooldown! (" .. cooldown .. " turns left)")
        else
            self:addMessage("Not enough mana! Need " .. spell.manaCost .. ", have " .. player.mana)
        end
        return false
    end
    
    local spell = Config.spells[spellIndex]
    self.selectedSpellIndex = spellIndex
    self:addMessage("Selected spell: " .. spell.name)
    return true
end

-- Get spell info for UI
function Combat.getSpellInfo(self, player)
    local info = {}
    for _, spellIndex in ipairs(player.knownSpells) do
        local spell = Config.spells[spellIndex]
        if spell then
            table.insert(info, {
                index = spellIndex,
                name = spell.name,
                description = spell.description,
                manaCost = spell.manaCost,
                cooldown = spell.cooldown,
                currentCooldown = player:getSpellCooldown(spellIndex),
                canCast = player:canCastSpell(spellIndex),
                icon = spell.icon
            })
        end
    end
    return info
end

-- Update status effects
function Combat.updateStatusEffects(self, player)
    -- Update player buffs and mana regeneration
    player:updateMagic()
    
    -- Update enemy attack reduction
    if self.enemy.attackReductionDuration and self.enemy.attackReductionDuration > 0 then
        self.enemy.attackReductionDuration = self.enemy.attackReductionDuration - 1
        
        if self.enemy.attackReductionDuration <= 0 then
            self:addMessage(self.enemy.name .. "'s attack returned to normal")
            self.enemy.attackReduction = 0
        end
    end
end

-- Player attack logic
function Combat.playerAttack(self, player)
    local damage = math.max(1, player.attack - self.enemy.defense)
    local isCritical = math.random() < Config.combat.critChance
    
    if isCritical then
        damage = damage * Config.combat.critMultiplier
        self:addMessage("Critical hit! You deal " .. damage .. " damage!")
    else
        self:addMessage("You attack for " .. damage .. " damage")
    end
    
    self.enemy.hp = math.max(0, self.enemy.hp - damage)
end

-- Enemy attack logic
function Combat.enemyAttack(self, player)
    -- Apply attack reduction if active
    local effectiveAttack = self.enemy.attack
    if self.enemy.attackReduction and self.enemy.attackReduction > 0 then
        effectiveAttack = math.max(1, effectiveAttack - self.enemy.attackReduction)
    end
    
    local damage = math.max(1, effectiveAttack - player.defense)
    local isCritical = math.random() < Config.combat.critChance
    
    if isCritical then
        damage = damage * Config.combat.critMultiplier
        self:addMessage(self.enemy.name .. " critical hit for " .. damage .. " damage!")
    else
        self:addMessage(self.enemy.name .. " attacks for " .. damage .. " damage")
    end
    
    player.hp = math.max(0, player.hp - damage)
end

-- Add a message to the combat log
function Combat.addMessage(self, msg)
    -- Insert at position 1 (top/newest first)
    table.insert(self.messages, 1, msg)
    -- Remove oldest message if exceeding max
    if #self.messages > self.maxMessages then
        table.remove(self.messages)
    end
    self.hud:addMessageToLog(msg)
end

-- Adjust battle speed
function Combat.adjustSpeed(self, amount)
    self.battleSpeed = math.max(0.1, math.min(2.0, self.battleSpeed + amount))
    self:addMessage("Battle speed: " .. string.format("%.1f", self.battleSpeed))
    return self.battleSpeed
end

-- Toggle auto skill usage
function Combat.toggleAutoSkills(self)
    self.autoUseSkills = not self.autoUseSkills
    self:addMessage("Auto skills: " .. (self.autoUseSkills and "ON" or "OFF"))
    return self.autoUseSkills
end

-- Select a skill to use (for manual skill activation)
function Combat.selectSkill(self, index)
    if index > 0 and index <= #self.playerSkills then
        local skill = self.playerSkills[index]
        
        if skill.currentCooldown <= 0 then
            self.selectedSkillIndex = index
            self:addMessage("Selected skill: " .. skill.name)
            return true
        else
            self:addMessage(skill.name .. " is on cooldown: " .. string.format("%.1f", skill.currentCooldown) .. "s")
            return false
        end
    end
    
    return false
end

-- Get cooldown information for UI
function Combat.getSkillInfo(self)
    local info = {}
    for i, skill in ipairs(self.playerSkills) do
        table.insert(info, {
            name = skill.name,
            description = skill.description,
            cooldown = skill.cooldown,
            currentCooldown = skill.currentCooldown,
            isReady = skill.currentCooldown <= 0
        })
    end
    return info
end

-- Draw a combat entity (player or enemy)
function Combat.drawCombatEntity(self, entity, x, y, attackTimer, isPlayer)
    local charSize = 32
    
    -- Add shaking when about to attack
    local shake = 0
    if attackTimer > 0.8 then
        shake = math.random(-3, 3)
    end
    
    -- Add visual feedback for attacks
    local size = 1.0
    if attackTimer < 0.2 then
        size = 1.2 -- "Pop" effect right after attacking
    end
    
    -- Draw status effects
    if not isPlayer and entity.status then
        -- Draw status indicator
        love.graphics.setFont(love.graphics.newFont(Config.fontPath, 16))
        
        if entity.status.type == "burn" then
            -- Draw fire particles
            for i = 1, 10 do
                local fireX = x + math.random(-20, 20)
                local fireY = y + math.random(-30, 10)
                love.graphics.setColor(1, 0.5, 0, 0.7)
                love.graphics.circle("fill", fireX, fireY, math.random(2, 5))
            end
            
            love.graphics.setColor(1, 0.3, 0, 1)
            love.graphics.printf("BURNING", x - 50, y - 80, 100, "center")
        end
    end
    
    -- Draw the character
    love.graphics.setFont(love.graphics.newFont(Config.fontPath, charSize * size * 0.8))
    love.graphics.setColor(entity.color)
    love.graphics.printf(entity.char, x - charSize + shake, y - charSize/2 + shake, charSize * 2, "center")
    
    -- Draw name and stats
    love.graphics.setColor(Config.colors.text)
    love.graphics.printf(isPlayer and "You" or entity.name, x - 100, y - 60, 200, "center")
    
    -- HP bar
    local barWidth = 100
    local hpRatio = entity.hp / entity.maxHp
    
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", x - barWidth/2, y + 30, barWidth, 10)
    love.graphics.setColor(Config.colors.health)
    love.graphics.rectangle("fill", x - barWidth/2, y + 30, barWidth * hpRatio, 10)
    
    -- HP text
    love.graphics.setColor(Config.colors.text)
    love.graphics.printf(entity.hp .. "/" .. entity.maxHp, x - 50, y + 45, 100, "center")
    
    -- Combat stats
    local attackText = entity.attack
    if not isPlayer and entity.attackReduction and entity.attackReduction > 0 then
        attackText = (entity.attack - entity.attackReduction) .. " (-" .. entity.attackReduction .. ")"
    end
    
    love.graphics.printf("ATK: " .. attackText .. "   DEF: " .. entity.defense, x - 100, y + 65, 200, "center")
    
    -- Draw combat effects
    if attackTimer < 0.3 then -- Just attacked
        for i = 1, 5 do
            local angle = math.random() * math.pi * 2
            local dist = math.random(20, 40)
            local px = x + math.cos(angle) * dist
            local py = y + math.sin(angle) * dist
            love.graphics.setColor(1, 1, 0, 1 - attackTimer/0.3)
            love.graphics.circle("fill", px, py, 2)
        end
    end
    
    -- Draw skill icons for player
    if isPlayer then
        self:drawSkillIcons(x, y + 95)
    end
end

-- Draw skill icons
function Combat.drawSkillIcons(self, x, y)
    local iconSize = 40
    local spacing = 10
    local totalWidth = (#self.playerSkills * (iconSize + spacing)) - spacing
    local startX = x - totalWidth / 2
    
    for i, skill in ipairs(self.playerSkills) do
        local iconX = startX + (i-1) * (iconSize + spacing)
        
        -- Draw skill background
        if skill.currentCooldown <= 0 then
            love.graphics.setColor(0.2, 0.6, 0.9, 0.7)
        else
            love.graphics.setColor(0.3, 0.3, 0.3, 0.7)
        end
        love.graphics.rectangle("fill", iconX, y, iconSize, iconSize, 5, 5)
        
        -- Draw skill border
        love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
        love.graphics.rectangle("line", iconX, y, iconSize, iconSize, 5, 5)
        
        -- Draw skill name
        love.graphics.setFont(love.graphics.newFont(Config.fontPath, 10))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(skill.name, iconX, y + 5, iconSize, "center")
        
        -- Draw cooldown overlay
        if skill.currentCooldown > 0 then
            -- Cooldown text
            love.graphics.setFont(love.graphics.newFont(Config.fontPath, 16))
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(string.format("%.1f", skill.currentCooldown), iconX, y + iconSize/2 - 8, iconSize, "center")
            
            -- Cooldown overlay
            love.graphics.setColor(0, 0, 0, 0.5)
            local cooldownRatio = skill.currentCooldown / skill.cooldown
            love.graphics.rectangle("fill", iconX, y + iconSize * (1 - cooldownRatio), iconSize, iconSize * cooldownRatio, 0, 0, 5, 5)
        end
    end
end

return Combat