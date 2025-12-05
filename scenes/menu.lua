local menu_scene = {} -- This is the scene table Scenery will use
local SaveManager = require("savemanager")

-- Create table for buttons and function to create the buttons
local buttons = {}
local languageButtons = {}
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
    titleFontArabic = nil
    titleFontChinese = nil
    buttonFontArabic = nil
    buttonFontChinese = nil
    
    -- Try to load larger fonts for titles
    local success, font = pcall(love.graphics.newFont, "assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf", 40)
    if success then titleFontArabic = font end
    
    success, font = pcall(love.graphics.newFont, "assets/fonts/NotoSansSC-VariableFont_wght.ttf", 40)
    if success then titleFontChinese = font end
    
    -- Try to load smaller fonts for buttons (14pt)
    success, font = pcall(love.graphics.newFont, "assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf", 14)
    if success then buttonFontArabic = font end
    
    success, font = pcall(love.graphics.newFont, "assets/fonts/NotoSansSC-VariableFont_wght.ttf", 14)
    if success then buttonFontChinese = font end
    
    buttons = {}
    languageButtons = {}
    lastCheckTime = 0  -- Force immediate check
    
    -- Build language selection buttons
    menu_scene:buildLanguageButtons()
    
    -- Build buttons immediately on load
    menu_scene:rebuildButtons()
end

function menu_scene:buildLanguageButtons()
    languageButtons = {}
    local languages = _G.localization:getAvailableLanguages()
    -- Use fixed position that works at different window sizes
    local buttonHeight = 30
    local buttonWidth = 150
    
    for i, lang in ipairs(languages) do
        table.insert(languageButtons, newButton(
            0,  -- X position will be calculated in draw
            0,  -- Y position will be calculated in draw
            buttonWidth,
            buttonHeight,
            lang.name,
            function()
                _G.localization:setLanguage(lang.code)
                menu_scene:rebuildButtons()  -- Rebuild main buttons with new language
            end
        ))
    end
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
        table.insert(buttons, newButton(100, 100, 150, 40, _G.localization:get("menu_continue"), function()
            print("=== CONTINUE BUTTON CLICKED ===")
            local state = SaveManager.loadAutoSave()
            if state and state.currentScene then
                print("Loaded state for scene: " .. state.currentScene)
                print("Player position:", state.playerPosition.x, state.playerPosition.y, state.playerPosition.z)
                print("Inventory items:", #(state.inventory or {}))
                
                -- Set the global player reference BEFORE restoring state
                _G.currentPlayer = nil  -- Will be created by scene
                
                -- Set flag to prevent auto-save during restoration
                setRestoringGame(true)
                
                -- Restore the game state
                SaveManager.restoreGameState(state)
                
                print("Set _G.savedPlayerPosition:", _G.savedPlayerPosition and "YES" or "NO")
                if _G.room1State then print("Room1 state restored") end
                if _G.room2State then print("Room2 state restored") end
                if _G.room3State then print("Room3 state restored") end
                
                -- Load the scene
                scenery.setScene(state.currentScene)
                
                -- Clear restoration flag after scene is loaded
                setRestoringGame(false)
                
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
    table.insert(buttons, newButton(100, newGameY, 150, 40, _G.localization:get("menu_new_game"), function()
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
    table.insert(buttons, newButton(100, quitY, 150, 40, _G.localization:get("menu_quit"), function()
        love.event.quit()
    end))
end

function menu_scene:draw()
    love.graphics.clear(0.1, 0.1, 0.2)
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    
    love.graphics.setColor(1, 1, 1)
    
    -- Set appropriate title font based on language
    if _G.localization.currentLanguage == "ar" and titleFontArabic then
        love.graphics.setFont(titleFontArabic)
    elseif _G.localization.currentLanguage == "zh" and titleFontChinese then
        love.graphics.setFont(titleFontChinese)
    else
        love.graphics.setFont(titleFont)
    end
    
    -- Draw title with RTL support
    local titleText = _G.localization:get("menu_title")
    love.graphics.printf(titleText, 0, height / 2 - 50, width, "center")
    
    -- Draw language selection label
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(_G.localization:getFont())
    love.graphics.print(_G.localization:get("menu_language") .. ":", width - 160, 10)
    
    -- Draw language buttons with updated positions
    for i, btn in ipairs(languageButtons) do
        -- Update button positions based on current window size
        btn.x = width - 160
        btn.y = 40 + (i - 1) * 35
        
        -- Highlight current language
        local isCurrent = btn.text == _G.localization:getLanguageName()
        
        if btn.isPressed then
            love.graphics.setColor(0.4, 0.4, 0.4)
        elseif btn.isHovered then
            love.graphics.setColor(0.6, 0.6, 0.6)
        elseif isCurrent then
            love.graphics.setColor(0.3, 0.7, 0.3)  -- Green for current language
        else
            love.graphics.setColor(0.8, 0.8, 0.8)
        end
        
        love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height)
        love.graphics.setColor(0, 0, 0)
        
        -- Set the appropriate font for each language button
        if btn.text == "中文" or btn.text:match("[\228-\233]") then
            -- Chinese characters - use smaller button font
            love.graphics.setFont(buttonFontChinese or _G.localization.chineseFont or _G.localization:getFont())
        elseif btn.text == "العربية" or btn.text:match("[\216-\219]") then
            -- Arabic characters - use smaller button font
            love.graphics.setFont(buttonFontArabic or _G.localization.arabicFont or _G.localization:getFont())
        else
            -- English or other
            love.graphics.setFont(_G.localization:getFont())
        end
        
        love.graphics.printf(btn.text, btn.x, btn.y + 5, btn.width, "center")
    end
    
    -- Draw main menu buttons
    love.graphics.setFont(_G.localization:getFont())
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
        love.graphics.printf(btn.text, btn.x, btn.y + 5, btn.width, "center")
    end
    
    -- Display save file location info
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(_G.localization:getFont())
    local saveDir = love.filesystem.getSaveDirectory()
    love.graphics.print(_G.localization:get("save_location") .. saveDir, 10, height - 20)
end
function menu_scene:update(dt)
    -- Don't constantly rebuild buttons - only check initially
    -- (Removed periodic checking that was causing infinite loop)
    
    -- Update button state for main buttons and language buttons
    local mouseX, mouseY = love.mouse.getPosition()
    for _, btn in pairs(buttons) do
        -- Check for hover
        btn.isHovered = (mouseX >= btn.x and mouseX <= btn.x + btn.width and
                         mouseY >= btn.y and mouseY <= btn.y + btn.height)
    end
    for _, btn in pairs(languageButtons) do
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
        for _, btn in pairs(languageButtons) do
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
        for _, btn in pairs(languageButtons) do
            if btn.isPressed and btn.isHovered and btn.callback then
                btn.callback() -- Execute the button's function
            end
            btn.isPressed = false
        end
    end
end

-- The scene file MUST return the table containing the callback methods
return menu_scene
