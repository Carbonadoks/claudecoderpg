-- main.lua for ASCII roguelike with auto-battle
-- Main entry point and game loop

-- Utility functions and config
local Utils = require("utils/Utils")
local Config = require("config/Config")

-- Core systems
local GameState = require("core/GameState")
local Camera = require("core/Camera")

-- Map and FOV
local InfiniteMap = require("map/InfiniteMap")
local FOV = require("map/FOV")

-- Entities
local Player = require("entities/Player")
local Enemy = require("entities/Enemy")
local EnemyManager = require("entities/EnemyManager")
local Item = require("entities/Item")
local ItemManager = require("entities/ItemManager")

-- Systems
local Combat = require("systems/Combat")
local Weather = require("systems/Weather")

-- UI components
local UI = require("ui/UI")
local HUD = require("ui/HUD")
local CombatUI = require("ui/CombatUI")
local CharacterMenu = require("ui/CharacterMenu")
local Timer = require("utils.timer")

-- Game variables
local gameState
local camera
local map
local fov
local player
local enemyManager
local itemManager
local combatSystem
local weatherSystem
local hud
local combatUI
local characterMenu
local timer
local messages
local hoveredTile

-- Movement variables
local heldKeys = {}
local lastMovementTime = 0
local movementDelay = 0.15  -- Time between held key movements (seconds)

-- Animation variables
local currentFrame = 0
local animationSpeed = 0.05

-- FPS limiting
local min_dt = 1/60
local next_time

-- Loading function - runs once at start
function love.load()
    -- System setup
    math.randomseed(os.time())
    love.keyboard.setKeyRepeat(true)
    
    -- FPS limit setup
    min_dt = 1/Config.targetFPS
    next_time = love.timer.getTime()
    
    -- Graphics setup
    local defaultFont = love.graphics.newFont(Config.fontPath, Config.defaultFontSize)
    local bigFont = love.graphics.newFont(Config.fontPath, Config.bigFontSize)
    local smallFont = love.graphics.newFont(Config.fontPath, Config.smallFontSize)
    love.graphics.setFont(defaultFont)
    
    -- Screen setup
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Initialize core systems
    camera = Camera.new()
    gameState = GameState.new()
    
    -- Initialize game
    initializeGame()
    timer = Timer()
end

-- Initialize or reset the game
function initializeGame()
    -- Get screen dimensions
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Initialize infinite map
    map = InfiniteMap.new()
    
    -- Create player at origin (0, 0 in world coordinates, which becomes 1, 1 in Lua)
    player = Player.new(1, 1)
    
    -- Load initial chunks around player
    map:loadChunksAroundPlayer(player.x, player.y)
    
    -- Initialize entity managers
    enemyManager = EnemyManager.new(map)
    itemManager = ItemManager.new(map)
    
    -- Load chunk-based enemies into enemy manager
    syncChunkEnemiesToManager()
    
    -- Generate initial items
    itemManager:generateItems(8, enemyManager, player.x, player.y)
    
    -- Initialize FOV
    fov = FOV.new(map, player)
    fov:update()
    hud = HUD.new(player, map)
    
    -- Initialize systems
    combatSystem = Combat.new(hud)
    weatherSystem = Weather.new(100, 100, Config.tileSize)  -- Use reasonable size for weather system
    weatherSystem:randomizeWeather()
    
    -- Initialize UI
    characterMenu = CharacterMenu.new(player)
    combatUI = CombatUI.new(player, combatSystem)
    
    -- Set up game states
    registerGameStates()
    gameState:changeState(Config.gameStates.exploring)
    
    -- Reset animation variables
    currentFrame = 0
    
    -- Reset movement variables
    heldKeys = {}
    lastMovementTime = 0
    
    -- Initialize mouse hover tracking
    local mouseX, mouseY = love.mouse.getPosition()
    updateHoveredTile(mouseX, mouseY)
end

-- Sync enemies from loaded chunks to enemy manager
function syncChunkEnemiesToManager()
    local Config = require("config/Config")
    local Enemy = require("entities/Enemy")
    
    -- Get all enemy data from chunks
    local allEnemyData = map:getAllEnemyData()
    
    -- Clear existing enemies
    enemyManager.enemies = {}
    
    -- Create Enemy objects from chunk data
    for _, enemyData in ipairs(allEnemyData) do
        -- Choose enemy type based on biome or random
        local enemyType = Config.enemyTypes[math.random(#Config.enemyTypes)]
        local enemy = Enemy.new(enemyData.x, enemyData.y, enemyType)
        table.insert(enemyManager.enemies, enemy)
    end
end

-- Handle held key movement
function handleHeldKeyMovement(dt)
    -- Only process movement if in exploring state and character menu is closed
    if gameState.currentState ~= Config.gameStates.exploring or characterMenu.isVisible then
        return
    end
    
    -- Check if enough time has passed since last movement
    if love.timer.getTime() - lastMovementTime < movementDelay then
        return
    end
    
    -- Check for held movement keys
    local dx, dy = 0, 0
    
    if love.keyboard.isDown("up", "w") then dy = -1
    elseif love.keyboard.isDown("down", "s") then dy = 1 end
    
    if love.keyboard.isDown("left", "a") then dx = -1
    elseif love.keyboard.isDown("right", "d") then dx = 1 end
    
    -- Process movement if a direction was selected
    if dx ~= 0 or dy ~= 0 then
        local success, result, entity, index = player:move(dx, dy, map, {enemies = enemyManager.enemies, items = itemManager.items})
        
        if success then
            -- Load chunks around new player position
            map:loadChunksAroundPlayer(player.x, player.y)
            
            -- Sync enemies from newly loaded chunks
            syncChunkEnemiesToManager()
            
            -- Update field of view after movement
            fov:update()
            if result == "item" then
                -- Pick up the item
                camera:shake(1.2, 0.15)
                local message = player:pickupItem(entity)
                hud:addMessage(message)
                
                -- Remove item from manager
                table.remove(itemManager.items, index)
            end
            
            -- Update last movement time
            lastMovementTime = love.timer.getTime()
        else
            -- Handle collision results
            if result == "blocked" then
                hud:addMessage("You can't move there.")
                camera:shake(1.5, 0.1) -- Small camera shake for wall bump
            elseif result == "enemy" then
                -- Start combat with the enemy
                camera:shake(3, 0.3)
                camera:setScale(1.1) -- Zoom in slightly
                camera.chromaAmount = 0.006 -- Increase aberration
                
                combatSystem:start(player,entity)
                gameState:changeState(Config.gameStates.combat)
            end
            
            -- Update last movement time even for failed moves to prevent spam
            lastMovementTime = love.timer.getTime()
        end
    end
end

-- Register all game states with their callbacks
function registerGameStates()
    -- Exploring state
    gameState:registerState(Config.gameStates.exploring, {
        enter = function(state)
            -- Reset camera effects when returning to exploration
            camera.vignette = Config.camera.vignette
            camera.targetScale = 1.0
            camera.distortAmount = Config.camera.distortAmount
            camera.rotation = Config.camera.rotation
        end,
        
        update = function(state, dt)
            -- Handle held key movement
            handleHeldKeyMovement(dt)
            
            -- Update camera to follow player
            local screenWidth = love.graphics.getWidth()
            local screenHeight = love.graphics.getHeight()
            camera:setTarget(
                player.x * Config.tileSize - screenWidth / 2,
                player.y * Config.tileSize - screenHeight / 2
            )
            
            -- Update player animation
            player:update(dt, currentFrame)
            
            -- Update enemy animations
            enemyManager:update(dt, currentFrame)
            
            -- Update weather effects
            weatherSystem:update(dt, currentFrame)
            
            -- Update enemy animations only (spawning now handled by chunks)
            enemyManager:update(dt, currentFrame)
        end,
        
        -- Define draw layers for easier separation
        drawLayers = {"drawMap", "drawWeather", "drawEnemies", "drawItems", "drawPlayer", "hud"},
        
        -- Individual draw functions for each layer
        drawMap = function(state)
            map:draw(fov.visibleTiles, fov.exploredTiles, currentFrame)
        end,
        
        drawWeather = function(state)
            weatherSystem:draw(fov.visibleTiles)
        end,
        
        drawEnemies = function(state)
            enemyManager:draw(Config.tileSize, currentFrame, fov.visibleTiles)
        end,
        
        drawItems = function(state)
            itemManager:draw(Config.tileSize, currentFrame, fov.visibleTiles)
        end,
        
        drawPlayer = function(state)
            player:draw(Config.tileSize, currentFrame)
        end,
        
        -- HUD drawing function (will be called after shaders)
        drawHUD = function(state)
            hud:draw(map, fov.visibleTiles, enemyManager.enemies, enemyManager.spawning)
        end,
        
        -- Legacy draw function (still used by default GameState manager)

        
        draw = function(state)
            -- This draw function is no longer used for exploring state
            -- Drawing is handled directly in love.draw() for proper camera separation
        end,
        
        keypressed = function(state, key)
            -- Check if character menu is open and handle its input first
            if characterMenu.isVisible then
                if key == "c" or key == "escape" then
                    characterMenu:hide()
                end
                return  -- Don't process other keys when menu is open
            end
            
            -- Handle movement keys
            local dx, dy = 0, 0
            
            if key == "up" or key == "w" then dy = -1
            elseif key == "down" or key == "s" then dy = 1
            elseif key == "left" or key == "a" then dx = -1
            elseif key == "right" or key == "d" then dx = 1
            elseif key == "h" or key == "f1" then
                -- Toggle help screen
                hud:toggleLegend()
                return
            elseif key == "e" then
                -- Enemy spawning now handled by chunks
                hud:addMessage("Enemies are generated with chunks")
                return
            elseif key == "c" then
                -- Toggle character menu
                characterMenu:toggle()
                return
            end
            
            -- Process movement if a direction was selected
            if dx ~= 0 or dy ~= 0 then
                local success, result, entity, index = player:move(dx, dy, map, {enemies = enemyManager.enemies, items = itemManager.items})
                
                if success then
                    -- Load chunks around new player position
                    map:loadChunksAroundPlayer(player.x, player.y)
                    
                    -- Sync enemies from newly loaded chunks
                    syncChunkEnemiesToManager()
                    
                    -- Update field of view after movement
                    fov:update()
                    if result == "item" then
                        -- Pick up the item
                        camera:shake(1.2, 0.15)
                        local message = player:pickupItem(entity)
                        hud:addMessage(message)
                        
                        -- Remove item from manager
                        table.remove(itemManager.items, index)
                    end
                else
                    -- Handle collision results
                    if result == "blocked" then
                        hud:addMessage("You can't move there.")
                        camera:shake(1.5, 0.1) -- Small camera shake for wall bump
                    elseif result == "enemy" then
                        -- Start combat with the enemy
                        camera:shake(3, 0.3)
                        camera:setScale(1.1) -- Zoom in slightly
                        camera.chromaAmount = 0.006 -- Increase aberration
                        
                        combatSystem:start(player,entity)
                        gameState:changeState(Config.gameStates.combat)
                    end
                end
            end
        end
    })
    
    -- Combat state
    gameState:registerState(Config.gameStates.combat, {
        enter = function(state)
            -- Enhance shader effects for combat mode
            camera.vignette = 0.5  -- Stronger vignette in combat
            camera:setScale(1.1)  -- Slight zoom in for combat
            camera.chromaAmount = 0.005  -- Enhance chromatic aberration for combat
            camera.distortAmount = 0.01  -- Enhance distortion for combat
            
            -- Shake camera when battle starts
            camera:shake(3, 0.5)
        end,
        
        update = function(state, dt)
            -- Update combat system
            local result = combatSystem:update(dt, player)
            
            -- Check for combat end
            if result and not combatSystem.endMessagesAdded then
                combatSystem.endMessagesAdded = true  -- Prevent message spam
                
                if result == "victory" then
                    -- Apply victory camera effect
                    camera:shake(2, 0.3)
                    
                    -- Add victory message to combat log
                    combatSystem:addMessage("VICTORY! You emerge triumphant!")
                    
                    -- Check for level up
                    if player.xp >= player.xpToLevel then
                        local message = player:levelUp()
                        hud:addMessage(message)
                        combatSystem:addMessage("LEVEL UP! You feel stronger!")
                        
                        -- Level up visual effects
                        camera:shake(2.5, 0.4)
                        camera:setScale(1.15)
                        camera.chromaAmount = 0.008
                        
                        -- Schedule a reset of camera parameters
                        timer:after(0.8, function()
                             camera:setScale(1.0)
                            camera.chromaAmount = 0.002
                         end)
                    end
                    
                    -- Remove the enemy from the manager and from chunk data
                    for i, enemy in ipairs(enemyManager.enemies) do
                        if enemy == combatSystem.enemy then
                            -- Remove from chunk data
                            map:removeEnemyData(enemy.x, enemy.y)
                            -- Remove from manager
                            table.remove(enemyManager.enemies, i)
                            break
                        end
                    end
                    
                    -- Return to exploring with a delay
                    combatSystem:addMessage("Returning to exploration...")
                    timer:after(1.5, function()
                        gameState:changeState(Config.gameStates.exploring)
                        combatSystem.endMessagesAdded = false  -- Reset flag for next combat
                    end)
                    
                    -- Enemies are now handled by chunk generation system
                    
                    -- Maybe spawn an item
                    if math.random() < 0.4 then
                        itemManager:generateItems(1, enemyManager, player.x, player.y)
                    end
                elseif result == "defeat" then
                    -- Apply defeat camera effect
                    camera:shake(5, 1.0)
                    camera.vignette = 0.7  -- Increase vignette on death
                    camera.distortAmount = 0.03  -- Increase distortion
                    
                    gameState:changeState(Config.gameStates.gameover)
                end
            end
        end,
        
        draw = function(state)
            combatUI:draw(currentFrame)
        end,
        
        keypressed = function(state, key)
            -- Combat speed controls during battle
            if key == "+" or key == "=" then
                -- Increase battle speed
                combatSystem.battleSpeed = math.min(2.0, combatSystem.battleSpeed + 0.1)
                combatSystem:addMessage("Battle speed: " .. string.format("%.1f", combatSystem.battleSpeed))
            elseif key == "-" then
                -- Decrease battle speed
                combatSystem.battleSpeed = math.max(0.1, combatSystem.battleSpeed - 0.1)
                combatSystem:addMessage("Battle speed: " .. string.format("%.1f", combatSystem.battleSpeed))
            elseif key >= "1" and key <= "7" then
                -- Cast spell by number
                local spellNum = tonumber(key)
                if spellNum <= #player.knownSpells then
                    local spellIndex = player.knownSpells[spellNum]
                    combatSystem:selectSpell(spellIndex, player)
                end
            elseif key == "m" then
                -- Toggle auto spells/skills
                combatSystem:toggleAutoSkills()
            end
        end
    })
    
    -- Game over state
    gameState:registerState(Config.gameStates.gameover, {
        enter = function(state)
            -- Game over effects applied in state transition
        end,
        
        update = function(state, dt)
            -- Nothing to update in game over state
        end,
        
        draw = function(state)
            -- Draw game over screen
            love.graphics.setColor(0.1, 0.1, 0.1)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
            
            local bigFont = love.graphics.newFont(Config.fontPath, Config.bigFontSize)
            love.graphics.setFont(bigFont)
            love.graphics.setColor(0.8, 0.2, 0.2)
            love.graphics.printf("GAME OVER", 0, love.graphics.getHeight()/3, love.graphics.getWidth(), "center")
            
            local defaultFont = love.graphics.newFont(Config.fontPath, Config.defaultFontSize)
            love.graphics.setFont(defaultFont)
            love.graphics.setColor(Config.colors.text)
            love.graphics.printf("You reached level " .. player.level, 0, love.graphics.getHeight()/3 + 50, love.graphics.getWidth(), "center")
            
            love.graphics.printf("Press ENTER to play again", 0, love.graphics.getHeight()/3 + 100, love.graphics.getWidth(), "center")
        end,
        
        keypressed = function(state, key)
            if key == "return" then
                -- Reset camera effects on new game
                camera.targetScale = 1.0
                camera.vignette = Config.camera.vignette
                camera.distortAmount = Config.camera.distortAmount
                
                -- Start a new game
                initializeGame()
            end
        end
    })
end

-- Main update function
function love.update(dt)
    -- Frame rate limiting
    next_time = next_time + min_dt
    
    -- Update animation frame
    currentFrame = (currentFrame + dt * animationSpeed * 60) % 1
    
    -- Update camera
    camera:update(dt)
    
    -- Update game state
    gameState:update(dt)
    timer:update(dt)
    hud:update(dt, hoveredTile)
    characterMenu:update(dt)
    
    -- Maintain steady FPS
    local current_time = love.timer.getTime()
    if next_time <= current_time then
        next_time = current_time
        return
    end
    love.timer.sleep(next_time - current_time)
end

-- Main drawing function
function love.draw()
    -- Different drawing approach based on game state
    if gameState.currentState == Config.gameStates.exploring then
        -- Draw world with camera transformations
        camera:startCapture()
        -- Draw world elements only
        map:draw(fov.visibleTiles, fov.exploredTiles, currentFrame)
        weatherSystem:draw(fov.visibleTiles)
        enemyManager:draw(Config.tileSize, currentFrame, fov.visibleTiles)
        itemManager:draw(Config.tileSize, currentFrame, fov.visibleTiles)
        player:draw(Config.tileSize, currentFrame)
        camera:endCapture()
        
        -- Draw UI elements without camera transformations
        hud:draw(map, fov.visibleTiles, enemyManager.enemies, enemyManager.spawning)
        characterMenu:draw()
    elseif gameState.currentState == Config.gameStates.combat then
        -- COMBAT STATE: Apply camera effects but draw UI at fixed positions
        love.graphics.push()
        -- Apply only camera effects (shake, scale) without position transform
        if camera.shakeTime > 0 then
            love.graphics.translate(camera.shakeX, camera.shakeY)
        end
        love.graphics.scale(camera.scale, camera.scale)
        
        -- Draw combat UI
        combatUI:draw(currentFrame)
        
        love.graphics.pop()
    else
        -- OTHER STATES (gameover): Draw normally
        gameState:draw()
    end
end

-- Handle key presses
function love.keypressed(key)
    -- Pass key press to current game state
    gameState:keypressed(key)
end

function love.wheelmoved(x,y)
    hud:wheelmoved(x,y)
end

-- Handle mouse movement for tile hovering
function love.mousemoved(x, y)
    updateHoveredTile(x, y)
end

-- Convert screen coordinates to tile coordinates and update hovered tile
function updateHoveredTile(mouseX, mouseY)
    if not map or gameState.currentState ~= Config.gameStates.exploring then
        hoveredTile = nil
        return
    end
    
    -- Convert screen coordinates to world coordinates accounting for camera transformations
    -- Apply reverse camera transformation
    local worldX = mouseX + camera.x
    local worldY = mouseY + camera.y
    
    -- Convert to tile coordinates
    local tileX = math.floor(worldX / Config.tileSize) + 1
    local tileY = math.floor(worldY / Config.tileSize) + 1
    
    -- For infinite worlds, we don't check bounds - just get the terrain
    local terrain = map:getTileAt(tileX, tileY)
    
    if terrain then
        hoveredTile = {
            x = tileX,
            y = tileY,
            terrain = terrain,
            entity = nil,
            entityType = nil
        }
        
        -- Check for entities at this position
        -- Check for player
        if player.x == tileX and player.y == tileY then
            hoveredTile.entity = player
            hoveredTile.entityType = "player"
        else
            -- Check for enemies
            for _, enemy in ipairs(enemyManager.enemies) do
                if enemy.x == tileX and enemy.y == tileY then
                    hoveredTile.entity = enemy
                    hoveredTile.entityType = "enemy"
                    break
                end
            end
            
            -- Check for items (if no enemy found)
            if not hoveredTile.entity then
                for _, item in ipairs(itemManager.items) do
                    if item.x == tileX and item.y == tileY then
                        hoveredTile.entity = item
                        hoveredTile.entityType = "item"
                        break
                    end
                end
            end
        end
    else
        hoveredTile = nil
    end
end
