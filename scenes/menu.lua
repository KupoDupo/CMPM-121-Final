local menu_scene = {} -- This is the scene table Scenery will use
local SaveManager = require("savemanager")

-- Create table for buttons and function to create the buttons
local buttons = {}
local function newButton(x, y, width, height, text, callback)
    return {
        x = x,
        y = y,
        width = width,
        height = height,
        text = text,
        callback = callback,
        isHovered = false,
        isPressed = false
    }
end

local lastCheckTime = 0
local checkInterval = 0.5  -- Check every half second

function menu_scene:load()
    titleFont = love.graphics.newFont(40)
    buttons = {}
    lastCheckTime = 0  -- Force immediate check
    
    -- Build buttons immediately on load
    menu_scene:rebuildButtons()
end

function menu_scene:rebuildButtons()
    buttons = {}
    
    print("=== MENU - Checking for saves ===")
    print("Save directory: " .. love.filesystem.getSaveDirectory())
    print("Looking for: " .. SaveManager.autoSaveFile)
    
    -- List all files
    local files = love.filesystem.getDirectoryItems("")
    print("Files in save directory (" .. #files .. " files):")
    for _, file in ipairs(files) do
        local info = love.filesystem.getInfo(file)
        if info then
            print("  - " .. file .. " (" .. info.size .. " bytes)")
        end
    end
    
    -- Check if there's a valid auto-save available
    local hasAutoSave = false
    if SaveManager.hasSave(SaveManager.autoSaveFile) then
        print("✓ Auto-save file found!")
        -- Try to load it to verify it's valid
        local testLoad = SaveManager.loadAutoSave()
        if testLoad then
            print("Loaded state contents:")
            print("  version:", testLoad.version)
            print("  timestamp:", testLoad.timestamp)
            print("  currentScene:", testLoad.currentScene)
            print("  playerPosition:", testLoad.playerPosition and "YES" or "NO")
            print("  inventory:", testLoad.inventory and #testLoad.inventory or "NO")
            print("  sceneStates:", testLoad.sceneStates and "YES" or "NO")
            
            if testLoad.currentScene then
                hasAutoSave = true
                print("✓ Auto-save is valid, scene: " .. testLoad.currentScene)
            else
                print("✗ Auto-save missing currentScene field")
            end
        else
            print("✗ Auto-save exists but failed to load")
        end
    else
        print("✗ No auto-save file found")
    end
    
    print("Show Continue button: " .. tostring(hasAutoSave))
    print("=================================")
    
    -- Create the "Continue" button if auto-save exists and is valid
    if hasAutoSave then
        table.insert(buttons, newButton(100, 100, 150, 40, "Continue", function()
            print("=== CONTINUE BUTTON CLICKED ===")
            local state = SaveManager.loadAutoSave()
            if state and state.currentScene then
                print("Loaded state for scene: " .. state.currentScene)
                print("Player position:", state.playerPosition.x, state.playerPosition.y, state.playerPosition.z)
                print("Inventory items:", #(state.inventory or {}))
                
                -- Set the global player reference BEFORE restoring state
                _G.currentPlayer = nil  -- Will be created by scene
                
                -- Restore the game state
                SaveManager.restoreGameState(state)
                
                print("Set _G.savedPlayerPosition:", _G.savedPlayerPosition and "YES" or "NO")
                if _G.room1State then print("Room1 state restored") end
                if _G.room2State then print("Room2 state restored") end
                if _G.room3State then print("Room3 state restored") end
                
                -- Load the scene
                scenery.setScene(state.currentScene)
                print("Scene set to:", state.currentScene)
                print("===============================")
            else
                print("Failed to load auto-save - file may be corrupted")
                -- Start new game as fallback
                _G.room1State = nil
                _G.room2State = nil
                _G.room3State = nil
                _G.savedPlayerPosition = nil
                globalInventory:clear()
                scenery.setScene("room1")
            end
        end))
    end
    
    -- Create the "New Game" button
    local newGameY = hasAutoSave and 160 or 100
    table.insert(buttons, newButton(100, newGameY, 150, 40, "New Game", function()
        -- Clear any existing save state
        _G.room1State = nil
        _G.room2State = nil
        _G.room3State = nil
        _G.savedPlayerPosition = nil
        globalInventory:clear()
        
        scenery.setScene("room1") 
        print("Starting new game!") 
    end))

    -- Create the "Quit" button
    local quitY = hasAutoSave and 220 or 160
    table.insert(buttons, newButton(100, quitY, 150, 40, "Quit", function()
        love.event.quit()
    end))
end

function menu_scene:draw()
    love.graphics.clear(0.1, 0.1, 0.2)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(titleFont)
    love.graphics.printf("Escape the Haunted House!", 0, 300, love.graphics.getWidth(), "center")
    
    love.graphics.setNewFont(14)
    for _, btn in pairs(buttons) do
        if btn.isPressed then
            love.graphics.setColor(0.4, 0.4, 0.4) -- Pressed Color
        elseif btn.isHovered then
            love.graphics.setColor(0.6, 0.6, 0.6) -- Hover Color
        else
            love.graphics.setColor(0.8, 0.8, 0.8) -- Default Color
        end
            
        love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(btn.text, btn.x + 5, btn.y + 5)
    end
    
    -- Display save file location info
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setNewFont(10)
    local saveDir = love.filesystem.getSaveDirectory()
    love.graphics.print("Save Location: " .. saveDir, 10, love.graphics.getHeight() - 20)
end

function menu_scene:update(dt)
    -- Don't constantly rebuild buttons - only check initially
    -- (Removed periodic checking that was causing infinite loop)
    
    -- Update button state
    local mouseX, mouseY = love.mouse.getPosition()
    for _, btn in pairs(buttons) do
        -- Check for hover
        btn.isHovered = (mouseX >= btn.x and mouseX <= btn.x + btn.width and
                         mouseY >= btn.y and mouseY <= btn.y + btn.height)
    end
end

-- Updates the isPressed / isHovered variables for the button when pressed 
function menu_scene:mousepressed(x, y, button)
    if button == 1 then -- Left mouse button
        for _, btn in pairs(buttons) do
            if btn.isHovered then
                btn.isPressed = true
            end
        end
    end
end

-- Updates the isPressed / isHovered variables for the button when released
function menu_scene:mousereleased(x, y, button)
    if button == 1 then
        for _, btn in pairs(buttons) do
            if btn.isPressed and btn.isHovered and btn.callback then
                btn.callback() -- Execute the button's function
            end
            btn.isPressed = false
        end
    end
end

-- The scene file MUST return the table containing the callback methods
return menu_scene