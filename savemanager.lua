local SaveManager = {}

-- Save system configuration
SaveManager.autoSaveInterval = 10  -- Auto-save every 10 seconds
SaveManager.maxSaveSlots = 5       -- Support up to 5 manual save slots
SaveManager.autoSaveFile = "autosave.json"
SaveManager.lastAutoSaveTime = 0

-- Utility function to serialize tables to JSON
local function tableToJSON(t, indent)
    indent = indent or ""
    local result = "{\n"
    local first = true
    for k, v in pairs(t) do
        if not first then
            result = result .. ",\n"
        end
        first = false
        
        local key = type(k) == "number" and '["' .. k .. '"]' or '["' .. tostring(k) .. '"]'
        result = result .. indent .. "  " .. key .. ": "
        
        if type(v) == "table" then
            result = result .. tableToJSON(v, indent .. "  ")
        elseif type(v) == "string" then
            result = result .. '"' .. v:gsub('"', '\\"') .. '"'
        elseif type(v) == "boolean" then
            result = result .. tostring(v)
        elseif type(v) == "number" then
            result = result .. tostring(v)
        else
            result = result .. "null"
        end
    end
    result = result .. "\n" .. indent .. "}"
    return result
end

-- Utility function to deserialize JSON to tables
local function jsonToTable(json)
    if not json or json == "" then 
        print("jsonToTable: empty or nil input")
        return nil 
    end
    
    -- Convert JSON to Lua table syntax
    local luaCode = json
    -- Replace ["key"]: with ["key"] =
    luaCode = luaCode:gsub('%["([^"]+)"%]%s*:%s*', '["%1"] = ')
    -- Replace "key": with ["key"] =
    luaCode = luaCode:gsub('"([^"]+)"%s*:%s*', '["%1"] = ')
    -- Replace remaining colons with equals (for nested objects)
    luaCode = luaCode:gsub(':%s*', ' = ')
    
    -- Wrap in return statement
    luaCode = "return " .. luaCode
    
    print("Attempting to parse Lua code...")
    
    -- Safely load and execute
    local func, err = load(luaCode)
    if not func then
        print("jsonToTable: load failed -", err)
        return nil
    end
    
    local success, result = pcall(func)
    
    if success and result then
        print("jsonToTable: successfully parsed")
        if type(result) == "table" then
            print("  currentScene:", result.currentScene)
            print("  version:", result.version)
            print("  timestamp:", result.timestamp)
        end
        return result
    else
        print("jsonToTable: execution failed -", tostring(result))
        return nil
    end
end

-- Get current game state for saving
function SaveManager.captureGameState(currentScene, player, inventory)
    local state = {
        version = "1.0",
        timestamp = os.time(),
        currentScene = currentScene,
        playerPosition = {
            x = player and player:getX() or 0,
            y = player and player:getY() or 0,
            z = player and player:getZ() or 0
        },
        inventory = {},
        sceneStates = {}
    }
    
    -- Capture inventory
    if inventory and inventory.items then
        for itemName, itemData in pairs(inventory.items) do
            table.insert(state.inventory, {
                name = itemName,
                displayName = itemData.displayName
            })
        end
    end
    
    -- Capture scene-specific states
    -- Room 1 state
    if _G.room1State then
        state.sceneStates.room1 = {
            doorLocked = _G.room1State.doorLocked,
            doorFallen = _G.room1State.doorFallen,
            cannonballExists = _G.room1State.cannonballExists,
            cannonballPosition = _G.room1State.cannonballPosition,
            cannonLoaded = _G.room1State.cannonLoaded,
            missCount = _G.room1State.missCount,
            gameOver = _G.room1State.gameOver
        }
    end
    
    -- Room 2 state
    if _G.room2State then
        state.sceneStates.room2 = {
            blockPositions = _G.room2State.blockPositions,
            pressurePlates = _G.room2State.pressurePlates,
            bridgeExtended = _G.room2State.bridgeExtended,
            doorLocked = _G.room2State.doorLocked,
            keyCollected = _G.room2State.keyCollected,
            keySpawned = _G.room2State.keySpawned
        }
    end
    
    -- Room 3 state
    if _G.room3State then
        state.sceneStates.room3 = {
            keyCollected = _G.room3State.keyCollected,
            doorUnlocked = _G.room3State.doorUnlocked
        }
    end
    
    return state
end

-- Save game state to a file
function SaveManager.saveToFile(filename, state)
    local saveDir = love.filesystem.getSaveDirectory()
    local json = tableToJSON(state)
    
    print("Attempting to save to: " .. saveDir .. "/" .. filename)
    print("Save data size: " .. #json .. " bytes")
    
    local success, message = love.filesystem.write(filename, json)
    if success then
        print("✓ Game saved successfully to: " .. saveDir .. "/" .. filename)
        -- Verify the file was written
        local info = love.filesystem.getInfo(filename)
        if info then
            print("✓ Verified file exists, size: " .. info.size .. " bytes")
        else
            print("✗ Warning: File write reported success but file not found!")
        end
        return true
    else
        print("✗ Failed to save game: " .. (message or "unknown error"))
        return false
    end
end

-- Load game state from a file
function SaveManager.loadFromFile(filename)
    local saveDir = love.filesystem.getSaveDirectory()
    print("Attempting to load from: " .. saveDir .. "/" .. filename)
    
    if not love.filesystem.getInfo(filename) then
        print("✗ Save file does not exist: " .. filename)
        return nil
    end
    
    local info = love.filesystem.getInfo(filename)
    print("✓ File found, size: " .. info.size .. " bytes")
    
    local json, err = love.filesystem.read(filename)
    if not json then
        print("✗ Failed to read save file: " .. (err or "unknown error"))
        return nil
    end
    
    print("✓ File read successfully, parsing...")
    
    -- Protect against JSON parsing errors
    local success, state = pcall(jsonToTable, json)
    if success and state then
        print("✓ Save file loaded and parsed successfully!")
        return state
    else
        print("✗ Failed to parse save file: " .. tostring(state))
        return nil
    end
end

-- Restore game state
function SaveManager.restoreGameState(state)
    if not state then
        print("Cannot restore: invalid state")
        return false
    end
    
    -- Restore inventory
    if state.inventory and globalInventory then
        globalInventory:clear()
        for _, itemData in ipairs(state.inventory) do
            globalInventory:addItem(itemData.name, itemData.displayName)
        end
    end
    
    -- Store scene states globally so scenes can access them
    _G.room1State = state.sceneStates and state.sceneStates.room1
    _G.room2State = state.sceneStates and state.sceneStates.room2
    _G.room3State = state.sceneStates and state.sceneStates.room3
    
    -- Store player position to be restored when scene loads
    _G.savedPlayerPosition = state.playerPosition
    
    return true
end

-- Auto-save function (call in update loop)
function SaveManager.updateAutoSave(dt, currentScene, player, inventory)
    SaveManager.lastAutoSaveTime = SaveManager.lastAutoSaveTime + dt
    
    if SaveManager.lastAutoSaveTime >= SaveManager.autoSaveInterval then
        SaveManager.lastAutoSaveTime = 0
        local state = SaveManager.captureGameState(currentScene, player, inventory)
        SaveManager.saveToFile(SaveManager.autoSaveFile, state)
        return true  -- Indicate auto-save occurred
    end
    
    return false
end

-- Manual save to a specific slot
function SaveManager.manualSave(slotNumber, currentScene, player, inventory)
    if slotNumber < 1 or slotNumber > SaveManager.maxSaveSlots then
        print("Invalid save slot: " .. slotNumber)
        return false
    end
    
    local filename = "save_slot_" .. slotNumber .. ".json"
    local state = SaveManager.captureGameState(currentScene, player, inventory)
    return SaveManager.saveToFile(filename, state)
end

-- Load from a specific slot
function SaveManager.loadSlot(slotNumber)
    if slotNumber < 1 or slotNumber > SaveManager.maxSaveSlots then
        print("Invalid save slot: " .. slotNumber)
        return nil
    end
    
    local filename = "save_slot_" .. slotNumber .. ".json"
    return SaveManager.loadFromFile(filename)
end

-- Load auto-save
function SaveManager.loadAutoSave()
    return SaveManager.loadFromFile(SaveManager.autoSaveFile)
end

-- Check if a save exists
function SaveManager.hasSave(filename)
    local info = love.filesystem.getInfo(filename)
    if not info then
        return false
    end
    
    -- Check if file has content (not empty)
    if info.size and info.size > 0 then
        return true
    end
    
    return false
end

-- Get list of available saves
function SaveManager.getAvailableSaves()
    local saves = {}
    
    -- Check auto-save
    if SaveManager.hasSave(SaveManager.autoSaveFile) then
        table.insert(saves, {
            type = "auto",
            filename = SaveManager.autoSaveFile,
            displayName = "Auto-Save"
        })
    end
    
    -- Check manual save slots
    for i = 1, SaveManager.maxSaveSlots do
        local filename = "save_slot_" .. i .. ".json"
        if SaveManager.hasSave(filename) then
            table.insert(saves, {
                type = "manual",
                slot = i,
                filename = filename,
                displayName = "Save Slot " .. i
            })
        end
    end
    
    return saves
end

-- Delete a save file
function SaveManager.deleteSave(filename)
    local success = love.filesystem.remove(filename)
    if success then
        print("Deleted save: " .. filename)
    else
        print("Failed to delete save: " .. filename)
    end
    return success
end

return SaveManager
