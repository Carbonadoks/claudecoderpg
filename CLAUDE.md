# CLAUDE.md - Guidelines for Coding Agents

## Project: ASCII Roguelike with Auto-battle

### Run Commands
- Launch game: `love .`
- Install LÖVE: https://love2d.org/ (if not already installed)

### Code Style Guidelines

#### Formatting
- Use spaces for indentation (4 spaces per level)
- Keep line length under 100 characters
- Use single line comments with `--` for explanations
- Group related functions together

#### Naming Conventions
- `camelCase` for variables and functions
- `terrainTypes`, `gameStates` for enum-like tables
- Descriptive names that reflect purpose (e.g., `updateFOV`, `drawCombatEntity`)

#### Structure
- Functions are organized by purpose (utility, game logic, drawing)
- Related data is grouped in tables (player, enemies, items)
- Constants are defined at the top of the file or in tables

#### Error Handling
- Use bounds checking before accessing array indices
- Validate player input with clear error messages
- Provide defaults for missing values

#### Performance
- Optimize drawing operations to maintain high FPS
- Use math.clamp for value constraints
- Cache calculations where possible

#### Game-Specific Patterns
- State-based game flow (exploring, combat, gameover)
- Entity component system for player/enemies
- Terrain represented by character + attributes

## Current Code Structure Analysis

### main.lua
The current main.lua file contains all game code in a monolithic structure.

#### Dependencies:
- LÖVE Framework (2D game engine)
- DejaVuSansMono.ttf (font file)

#### Main Functions:
1. **Utility Functions**
   - `math.clamp`: Constrain a value between min and max
   - `math.lerp`: Linear interpolation between values

2. **Game Initialization**
   - `love.load`: Initialize game state, graphics, and settings
   - `initShaders`: Setup shaders for visual effects
   - `initializeGame`: Setup player, map, enemies, and game state

3. **Map Generation**
   - `generateMap`: Create the basic map structure
   - `addBiome`: Add biome regions (forest, mountains, lake, meadow)
   - `generatePaths`: Create paths between map regions
   - `addDecorativeElements`: Add special terrain features
   - `generateSpawnPoints`: Create enemy spawn locations

4. **Entity Management**
   - `generateEnemies`: Spawn new enemies on the map
   - `generateItems`: Place items on the map
   - `isEnemyAt/getEnemyAt`: Check for enemies at coordinates
   - `isItemAt/getItemAt`: Check for items at coordinates
   - `pickupItem`: Process item collection

5. **Player Movement & Input**
   - `love.keypressed`: Handle keyboard input
   - `movePlayer`: Process player movement

6. **Field of View**
   - `updateFOV`: Calculate visible tiles
   - `castRay`: Line-of-sight calculation
   - `smoothFOV`: Refine FOV for better visuals
   - `hasLineOfSight`: Check if two points can see each other

7. **Game Loop**
   - `love.update`: Main game update loop
   - `updateCamera`: Handle camera positioning and effects
   - `shakeCamera`: Apply shake effect to camera
   - `updateHoveredTile`: Track mouse position on map
   - `updateWeather`: Update weather particles
   - `updateEnemySpawning`: Handle enemy spawning system

8. **Combat System**
   - `startCombat`: Initialize combat with an enemy
   - `updateCombat`: Process combat turns
   - `playerAttack/enemyAttack`: Handle attack logic
   - `addCombatMessage`: Display combat events
   - `levelUp`: Increase player stats

9. **Rendering**
   - `love.draw`: Main rendering function
   - `drawExploringScreen`: Render exploration state
   - `drawMap`: Render the terrain
   - `drawPlayer/drawEnemies/drawItems`: Render entities
   - `drawWeather`: Render weather effects
   - `drawStats/drawMinimap`: Render UI elements
   - `drawTerrainPanel/drawTileTooltip/drawLegend`: Render informational panels
   - `drawCombatScreen`: Render combat interface
   - `drawCombatEntity`: Render entity in combat
   - `drawGameOverScreen`: Render game over screen

## Planned OOP Structure

The code will be modularized into the following files:

### main.lua
- Dependencies: All modules below
- Purpose: Main entry point and game loop
- Key functions: 
  - `love.load`: Initialize game
  - `love.update`: Update game state
  - `love.draw`: Render game
  - `love.keypressed`: Handle input

### utils/Utils.lua
- Dependencies: None
- Purpose: Utility functions
- Key functions:
  - `math.clamp`: Constrain values
  - `math.lerp`: Linear interpolation

### config/Config.lua
- Dependencies: None
- Purpose: Game settings and constants
- Contents:
  - Screen dimensions
  - Tile settings
  - Colors
  - Game states (enum)
  - Terrain types

### core/Camera.lua
- Dependencies: Utils
- Purpose: Handle view transformations
- Key functions:
  - `new`: Create camera instance
  - `update`: Update camera position
  - `shake`: Apply screen shake
  - `applyShaders`: Apply visual effects

### core/GameState.lua
- Dependencies: None
- Purpose: Manage game state transitions
- Key functions:
  - `new`: Create state manager
  - `changeState`: Switch game states
  - `getCurrentState`: Get current state
  - `updateCurrentState`: Update active state

### map/Map.lua
- Dependencies: Config, Utils
- Purpose: Terrain and map management
- Key functions:
  - `new`: Create map instance
  - `generate`: Generate map layout
  - `addBiome`: Add terrain biomes
  - `getTileAt`: Get tile at coordinates
  - `isTileWalkable`: Check if tile can be traversed

### map/FOV.lua
- Dependencies: Map
- Purpose: Field of view calculations
- Key functions:
  - `new`: Create FOV calculator
  - `update`: Recalculate visible tiles
  - `castRay`: Line-of-sight ray casting
  - `isVisible`: Check if tile is visible

### entities/Entity.lua
- Dependencies: Map, Utils
- Purpose: Base entity class
- Properties:
  - position (x, y)
  - character representation
  - color
- Methods:
  - `new`: Create entity
  - `update`: Update entity state
  - `draw`: Render entity

### entities/Player.lua
- Dependencies: Entity, FOV, Map
- Purpose: Player character implementation
- Key functions:
  - `new`: Create player instance
  - `move`: Handle movement
  - `pickup`: Collect items
  - `levelUp`: Increase stats
  - `draw`: Render player

### entities/Enemy.lua
- Dependencies: Entity, Map
- Purpose: Enemy implementation
- Key functions:
  - `new`: Create enemy
  - `update`: Update enemy state
  - `draw`: Render enemy
  - `spawn`: Create enemy at location

### entities/EnemyManager.lua
- Dependencies: Enemy, Map
- Purpose: Manage enemy spawning and tracking
- Key functions:
  - `new`: Create manager
  - `generateEnemies`: Spawn enemies
  - `updateSpawning`: Handle spawn timing
  - `isEnemyAt/getEnemyAt`: Find enemies

### entities/Item.lua
- Dependencies: Entity
- Purpose: Game items implementation
- Key functions:
  - `new`: Create item
  - `use`: Apply item effect
  - `draw`: Render item

### entities/ItemManager.lua
- Dependencies: Item, Map
- Purpose: Manage items on map
- Key functions:
  - `new`: Create manager
  - `generateItems`: Create and place items
  - `isItemAt/getItemAt`: Find items

### systems/Combat.lua
- Dependencies: Player, Enemy
- Purpose: Battle system
- Key functions:
  - `new`: Create combat instance
  - `start`: Begin combat
  - `update`: Process combat turns
  - `attack`: Calculate damage
  - `isOver`: Check if combat is complete

### systems/Weather.lua
- Dependencies: Map
- Purpose: Weather effects
- Key functions:
  - `new`: Create weather system
  - `update`: Update weather particles
  - `draw`: Render weather effects

### ui/UI.lua
- Dependencies: Config
- Purpose: Base UI class
- Key functions:
  - `new`: Create UI element
  - `update`: Update UI state
  - `draw`: Render UI

### ui/HUD.lua
- Dependencies: UI, Player
- Purpose: Game status display
- Key functions:
  - `new`: Create HUD
  - `drawStats`: Show player stats
  - `drawMinimap`: Show map overview
  - `drawMessages`: Show game messages

### ui/Panel.lua
- Dependencies: UI
- Purpose: Information panels
- Key functions:
  - `new`: Create panel
  - `update`: Update panel content
  - `draw`: Render panel

### ui/CombatUI.lua
- Dependencies: UI, Combat
- Purpose: Combat interface
- Key functions:
  - `new`: Create combat UI
  - `drawCombatScreen`: Render combat view
  - `drawCombatEntity`: Render entity in combat
  - `drawMessages`: Show combat events