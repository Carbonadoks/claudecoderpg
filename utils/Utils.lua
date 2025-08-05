-- utils/Utils.lua
-- Utility functions used throughout the game

local Utils = {}

-- Constrain a value between min and max
function Utils.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Linear interpolation between two values
function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

-- Calculate distance between two points
function Utils.distance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

-- Check if point is within bounds
function Utils.isInBounds(x, y, minX, minY, maxX, maxY)
    return x >= minX and x <= maxX and y >= minY and y <= maxY
end

-- Random float between min and max
function Utils.randomFloat(min, max)
    return min + math.random() * (max - min)
end

-- Random integer between min and max (inclusive)
function Utils.randomInt(min, max)
    return math.floor(min + math.random() * (max - min + 1))
end

-- Deep copy a table
function Utils.deepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Utils.deepCopy(orig_key)] = Utils.deepCopy(orig_value)
        end
        setmetatable(copy, Utils.deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function Utils.printTable(t, indent)
    indent = indent or 0
    local indentStr = string.rep("  ", indent)
    
    for k, v in pairs(t) do
        local keyStr = tostring(k)
        
        if type(v) == "table" then
            print(indentStr .. keyStr .. " = {")
            Utils.printTable(v, indent + 1)
            print(indentStr .. "}")
        else
            local valueStr = tostring(v)
            print(indentStr .. keyStr .. " = " .. valueStr)
        end
    end
end


return Utils