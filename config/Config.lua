-- config/Config.lua
-- Game settings and constants

local Config = {}

-- Screen and tile settings
Config.tileSize = 20
Config.defaultFontSize = 16
Config.bigFontSize = 20
Config.smallFontSize = 12
Config.fontPath = "DejaVuSansMono.ttf"
Config.screenWidth = 800
Config.screenHeight = 600
-- FPS settings
Config.targetFPS = 60
Config.minDt = 1/60

-- Game states
Config.gameStates = {
    exploring = "exploring",
    combat = "combat",
    gameover = "gameover"
}

Config.scrollSpeed = 40
-- Colors
Config.colors = {
    player = {0.2, 0.8, 0.2},
    enemy = {0.8, 0.2, 0.2},
    wall = {0.5, 0.5, 0.5},
    floor = {0.2, 0.2, 0.3},
    water = {0.2, 0.4, 0.8},
    deepWater = {0.1, 0.3, 0.7},
    grass = {0.1, 0.6, 0.3},
    tallGrass = {0.1, 0.7, 0.2},
    mountain = {0.6, 0.4, 0.2},
    highMountain = {0.65, 0.45, 0.25},
    tree = {0.0, 0.5, 0.1},
    flowers = {0.9, 0.5, 0.9},
    path = {0.8, 0.7, 0.5},
    stairs = {0.9, 0.9, 0.5},
    door = {0.7, 0.4, 0.1},
    altar = {0.9, 0.9, 0.2},
    item = {0.9, 0.9, 0.1},
    text = {0.9, 0.9, 0.9},
    highlight = {1, 1, 0,1},
    health = {0.8, 0.2, 0.2},
    mana = {0.2, 0.4, 0.8},
    panel = {0.1, 0.1, 0.2, 0.5},
    panelBorder = {0.5, 0.5, 0.7, 0.9},
    cooldown = {0.5, 0.5, 0.5},  -- Gray for skills on cooldown
    ready = {0, 1, 0},
    scrollBar = {0.4, 0.4, 0.4, 0.8},
    scrollBarHover = {0.5, 0.5, 0.5, 0.9}
}

-- Map terrain types
Config.terrainTypes = {
    floor = {char = ".", color = Config.colors.floor, walkable = true, name = "Floor", desc = "Basic dungeon floor"},
    wall = {char = "#", color = Config.colors.wall, walkable = false, name = "Wall", desc = "Solid stone wall"},
    water = {char = "~", color = Config.colors.water, walkable = false, name = "Water", animated = true, desc = "Shallow water, too deep to cross"},
    deepWater = {char = "≈", color = Config.colors.deepWater, walkable = false, name = "Deep Water", animated = true, desc = "Dangerous deep water"},
    grass = {char = '"', color = Config.colors.grass, walkable = true, name = "Grass", animated = true, desc = "Grassy terrain"},
    tallGrass = {char = ";", color = Config.colors.tallGrass, walkable = true, name = "Tall Grass", animated = true, desc = "Thick grass that may hide items"},
    mountain = {char = "^", color = Config.colors.mountain, walkable = false, name = "Mountain", desc = "Rocky mountain terrain"},
    highMountain = {char = "A", color = Config.colors.highMountain, walkable = false, name = "High Mountain", desc = "Steep mountain peaks"},
    tree = {char = "T", color = Config.colors.tree, walkable = false, name = "Tree", animated = true, desc = "A tall tree blocking your path"},
    flowers = {char = "*", color = Config.colors.flowers, walkable = true, name = "Flowers", animated = true, desc = "Beautiful wildflowers"},
    path = {char = "·", color = Config.colors.path, walkable = true, name = "Path", desc = "A well-worn path"},
    stairsDown = {char = ">", color = Config.colors.stairs, walkable = true, name = "Stairs Down", desc = "Stairs leading to a deeper level"},
    stairsUp = {char = "<", color = Config.colors.stairs, walkable = true, name = "Stairs Up", desc = "Stairs leading to the level above"},
    door = {char = "+", color = Config.colors.door, walkable = true, name = "Door", desc = "A wooden door"},
    altar = {char = "O", color = Config.colors.altar, walkable = true, name = "Altar", desc = "A mysterious altar"}
}

-- Camera default settings
Config.camera = {
    scale = 1.0,
    rotation = 0,
    vignette = 0.05,
    distortAmount = 0.005
}

-- Enemy spawning settings
Config.enemySpawning = {
    enabled = true,
    interval = 20,
    chance = 0.7,
    maxEnemies = 15
}

-- Weather settings
Config.weatherTypes = {
    clear = 1,
    rain = 2,
    snow = 3,
    fog = 4
}

-- Combat settings
Config.combat = {
    battleSpeed = 0.3,
    maxMessages = 5,
    critChance = 0.1,
    critMultiplier = 2.0
}

-- Enemy types
Config.enemyTypes = {
    {name = "Goblin", char = "g", hp = 30, attack = 8, defense = 2, speed = 8, xp = 200},
    {name = "Orc", char = "o", hp = 50, attack = 12, defense = 4, speed = 7, xp = 200},
    {name = "Troll", char = "T", hp = 80, attack = 18, defense = 6, speed = 5, xp = 62000},
    {name = "Dragon", char = "D", hp = 150, attack = 25, defense = 10, speed = 9, xp = 100},
    {name = "Bandit", char = "b", hp = 40, attack = 10, defense = 3, speed = 9, xp = 200},
    {name = "Skeleton", char = "s", hp = 35, attack = 9, defense = 5, speed = 7, xp = 200},
    {name = "Spider", char = "S", hp = 25, attack = 7, defense = 1, speed = 12, xp = 200}
}

-- Item types
Config.itemTypes = {
    {name = "Health Potion", char = "!", effect = "heal", value = 30},
    {name = "Mana Potion", char = "M", effect = "mana", value = 25},
    {name = "Strength Potion", char = "S", effect = "attack", value = 5},
    {name = "Defense Potion", char = "D", effect = "defense", value = 5},
    {name = "Gold", char = "$", effect = "gold", value = 20},
    {name = "Magic Scroll", char = "?", effect = "heal", value = 50},
    {name = "Speed Potion", char = "V", effect = "speed", value = 2},
    {name = "Treasure Chest", char = "=", effect = "gold", value = 100}
}

-- Spell definitions (simplified)
Config.spells = {
    {
        name = "Magic Missile",
        description = "A reliable magical projectile",
        manaCost = 8,
        damage = {12, 18},
        type = "damage",
        cooldown = 2,
        icon = "*"
    },
    {
        name = "Fireball",
        description = "Explosive fire damage",
        manaCost = 15,
        damage = {18, 25},
        type = "damage",
        cooldown = 4,
        icon = "F"
    },
    {
        name = "Ice Shard",
        description = "Sharp ice projectile",
        manaCost = 12,
        damage = {14, 20},
        type = "damage",
        cooldown = 3,
        icon = "I"
    },
    {
        name = "Lightning Bolt",
        description = "Fast electric attack",
        manaCost = 18,
        damage = {20, 28},
        type = "damage",
        cooldown = 5,
        icon = "L"
    },
    {
        name = "Heal",
        description = "Restore health points",
        manaCost = 10,
        healing = {15, 25},
        type = "heal",
        cooldown = 3,
        icon = "+"
    },
    {
        name = "Shield",
        description = "Temporary defense boost",
        manaCost = 8,
        defenseBoost = 5,
        duration = 5,
        type = "buff",
        cooldown = 6,
        icon = "S"
    },
    {
        name = "Haste",
        description = "Increase attack speed temporarily",
        manaCost = 12,
        speedBoost = 3,
        duration = 4,
        type = "buff",
        cooldown = 7,
        icon = "H"
    }
}

return Config