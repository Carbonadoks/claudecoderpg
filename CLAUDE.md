# CLAUDE.md - Guidelines for Coding Agents

## Project: ASCII Roguelike with Infinite World and Auto-battle

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
- Chunk-based loading for infinite world performance

#### Game-Specific Patterns
- State-based game flow (exploring, combat, gameover)
- Entity component system for player/enemies
- Chunk-based infinite world generation
- Dynamic FOV with sparse arrays for infinite coordinates

## Current Game Features

### Infinite Procedural World
- **Chunk-based generation**: 32x32 tile chunks loaded dynamically around player
- **Biome system**: Forest, Mountains, Lakes, Meadows, Plains with unique terrain
- **Guaranteed connectivity**: Cross-chunk paths ensure no impassable regions
- **Memory management**: Automatic chunk loading/unloading (max 50 chunks)
- **Noise-based terrain**: Consistent world generation using seeded noise functions

### Movement & Controls
- **Held key movement**: Hold WASD or arrow keys for continuous movement
- **Smooth camera**: Follows player with shake effects and visual feedback
- **Infinite exploration**: No world boundaries, explore endlessly in any direction
- **Character menu**: Press 'C' to view stats, spells, skills, and inventory

### Combat System
- **Turn-based combat**: Enter combat by walking into enemies
- **Spell system**: Magic spells with cooldown timers (like skills)
- **Auto-battle**: Combat progresses automatically with visual feedback
- **Skill variety**: Multiple combat skills with different cooldowns and effects
- **Level progression**: Gain XP, level up, learn new spells

### Entity Systems
- **Chunk-based enemies**: Enemies generated with terrain, persistent per chunk
- **Biome-appropriate spawning**: Enemy density varies by terrain type
- **Item generation**: Items spawn around player with appropriate distribution
- **Dynamic loading**: Entities sync automatically as chunks load/unload

## Current Code Structure (Modular OOP)

### main.lua
- **Dependencies**: All modules below
- **Purpose**: Main entry point, game loop, and state management
- **Key systems**:
  - Game state management (exploring, combat, gameover)
  - Held key movement handling with timing
  - Camera integration with world/UI separation
  - Chunk-based enemy synchronization

### utils/Utils.lua
- **Dependencies**: None
- **Purpose**: Utility functions
- **Key functions**:
  - `math.clamp`: Constrain values between min/max
  - `math.lerp`: Linear interpolation for smooth animations
  - `distance`: Calculate distance between points

### config/Config.lua
- **Dependencies**: None
- **Purpose**: Game settings, constants, and data
- **Contents**:
  - Screen dimensions and tile settings
  - Color definitions and visual settings
  - Game states enumeration
  - Terrain types with walkability and animations
  - Enemy types and stats
  - Item types and effects
  - Spell definitions with cooldowns

### core/Camera.lua
- **Dependencies**: Utils, Config
- **Purpose**: View transformations and visual effects
- **Key features**:
  - Smooth following of player through infinite world
  - Screen shake effects for combat feedback
  - Zoom and scaling for combat emphasis
  - Shader effects (vignette, distortion, scanlines)
  - Separation of world vs UI transformations

### core/GameState.lua
- **Dependencies**: None
- **Purpose**: Manage game state transitions
- **Key functions**:
  - State registration with callbacks
  - Smooth transitions between exploring/combat/gameover
  - State-specific update and draw functions

### map/InfiniteMap.lua
- **Dependencies**: Config, Utils
- **Purpose**: Infinite procedural world generation
- **Key systems**:
  - **Chunk management**: 32x32 chunks with coordinate conversion
  - **Biome generation**: Noise-based biome placement and terrain
  - **Path connectivity**: Guaranteed walkable paths through all chunks
  - **Enemy integration**: Enemies generated per chunk with biome density
  - **Memory optimization**: Automatic chunk loading/unloading
- **Key functions**:
  - `generateChunk`: Create terrain, paths, enemies for chunk
  - `ensureChunkConnectivity`: Add guaranteed walkable paths
  - `loadChunksAroundPlayer`: Dynamic chunk loading
  - `getAllEnemyData`: Get enemies from loaded chunks

### map/FOV.lua
- **Dependencies**: Utils, Config
- **Purpose**: Field of view for infinite world
- **Key features**:
  - **Dynamic sparse arrays**: No pre-allocation for infinite coordinates
  - **Ray casting**: 180-ray FOV calculation with distance falloff
  - **Exploration memory**: Tracks previously explored tiles
  - **Smooth FOV**: Gap-filling algorithm for better visuals
  - **Performance optimization**: Range-limited processing

### entities/Entity.lua
- **Dependencies**: None
- **Purpose**: Base entity class
- **Properties**: Position, character, color, animation
- **Methods**: Creation, update, drawing with animation support

### entities/Player.lua
- **Dependencies**: Entity, Config, Utils
- **Purpose**: Player character with progression
- **Key features**:
  - **Infinite movement**: No bounds checking for infinite world
  - **Spell system**: Known spells with cooldown management
  - **Skill system**: Combat abilities with varied cooldowns
  - **Progression**: Level up system with stat increases
  - **Magic management**: Mana regeneration and buff tracking

### entities/Enemy.lua
- **Dependencies**: Entity, Config
- **Purpose**: Enemy entities with AI
- **Key features**:
  - Different enemy types with varied stats
  - Animation and visual effects
  - Spawn effects and death handling

### entities/EnemyManager.lua
- **Dependencies**: Enemy, Config, Utils
- **Purpose**: Enemy tracking and coordination
- **Key changes**:
  - **Chunk integration**: Syncs with InfiniteMap enemy data
  - **No timer spawning**: Enemies come from chunk generation
  - **Dynamic loading**: Updates when chunks load/unload

### entities/Item.lua & ItemManager.lua
- **Dependencies**: Entity, Config, Utils
- **Purpose**: Item system and management
- **Key features**:
  - Various item types (health, mana, stat boosts, gold)
  - Player-relative generation for infinite world
  - Pickup mechanics with visual feedback

### systems/Combat.lua
- **Dependencies**: Player, Enemy, Config
- **Purpose**: Turn-based combat system
- **Key features**:
  - **Simplified spell system**: Direct damage/heal/buff effects
  - **Cooldown integration**: Respects player spell cooldowns
  - **Auto-battle**: Automatic turn progression
  - **Visual feedback**: Camera effects and message system

### systems/Weather.lua
- **Dependencies**: Map, Config
- **Purpose**: Weather particle effects
- **Key features**:
  - Particle system for atmospheric effects
  - FOV-based rendering (only draw visible particles)
  - Randomized weather patterns

### ui/UI.lua
- **Dependencies**: Config
- **Purpose**: Base UI component class
- **Features**: Positioning, visibility, update/draw patterns

### ui/HUD.lua
- **Dependencies**: UI, Player, Config
- **Purpose**: Main game interface
- **Key features**:
  - **Infinite minimap**: Shows 25-tile radius around player
  - **Dynamic positioning**: Adapts to screen size
  - **Message scrolling**: Game event logging
  - **Stats display**: Player information and progress

### ui/CharacterMenu.lua
- **Dependencies**: UI, Player, Config
- **Purpose**: Character information screen
- **Key features**:
  - Complete player stats display
  - Spell list with cooldown indicators
  - Skill information and cooldowns
  - Active buff tracking
  - Inventory management

### ui/CombatUI.lua
- **Dependencies**: UI, Combat, Config
- **Purpose**: Combat interface
- **Key features**:
  - **Fullscreen combat**: Immersive battle experience
  - **Scaled UI elements**: Smaller text, optimized layout
  - **Spell panel**: Available spells with cooldown display
  - **Message log**: Combat event tracking
  - **Entity rendering**: Animated combat participants

## Architecture Highlights

### Infinite World System
- **Chunk Coordinate System**: Converts between world coordinates and chunk coordinates
- **Procedural Generation**: Consistent terrain using seeded noise functions
- **Biome Transitions**: Smooth transitions between different terrain types
- **Path Network**: Guaranteed connectivity prevents player from getting stuck
- **Entity Persistence**: Enemies and spawn points saved per chunk

### Performance Optimizations
- **Chunk Loading**: Only loads 5x5 chunks around player (max 25 active)
- **Memory Management**: Unloads distant chunks automatically
- **Dynamic FOV**: Only processes tiles within view range
- **Sparse Arrays**: No pre-allocation for infinite coordinates
- **Efficient Drawing**: Only renders visible tiles and entities

### User Experience
- **Smooth Movement**: Held key movement with appropriate timing
- **Visual Feedback**: Camera shake, zoom, and effects for all actions
- **Persistent World**: Returning to areas shows same terrain and enemies
- **Intuitive Interface**: Clear UI with helpful information displays
- **Progression System**: Meaningful character advancement and spell learning

## Key Implementation Notes

### Movement System
- Hold WASD or arrow keys for continuous movement
- 0.15 second delay between moves prevents too-fast movement
- Automatic chunk loading and enemy syncing on movement
- FOV updates automatically after each move

### Combat Integration
- Walk into enemies to start combat
- Camera effects enhance combat feel (shake, zoom, chromatic aberration)
- Combat UI properly separated from camera transformations
- Spell cooldowns work identical to skill cooldowns

### Enemy System
- Enemies generated during chunk creation (not timer-based)
- Enemy density varies by biome type
- Fewer enemies near starting area for better new player experience
- Defeated enemies removed from both manager and chunk data

### Infinite World Navigation
- No boundaries or edges to the world
- Consistent biome generation creates recognizable regions
- Path network ensures player can always progress
- Minimap shows local area around player position

This represents a complete infinite world roguelike with smooth movement, dynamic content generation, and integrated systems that work seamlessly together.