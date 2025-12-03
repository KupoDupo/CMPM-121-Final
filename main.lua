-- Scenery setup
local SceneryInit = require("scenery")
scenery = SceneryInit("menu")

-- 3DreamEngine
dream = require("3DreamEngine")

-- Other physics library (might delete later)
local bump = require 'bump-3dpd'

-- Global persistent inventory
local Inventory = require("inventory")
globalInventory = Inventory.new()

-- Save system
local SaveManager = require("savemanager")

-- Track current scene and auto-save notification
local currentSceneName = "menu"
local autoSaveNotification = ""
local autoSaveTimer = 0

-- Override scenery.setScene to track scene changes and trigger auto-save
local originalSetScene = scenery.setScene
function scenery.setScene(key, data)
    currentSceneName = key
    
    -- Auto-save on scene transitions (except menu)
    if key ~= "menu" and key ~= "ending" then
        local player = _G.currentPlayer
        local state = SaveManager.captureGameState(key, player, globalInventory)
        SaveManager.saveToFile(SaveManager.autoSaveFile, state)
        autoSaveNotification = "Game Auto-Saved"
        autoSaveTimer = 2
        print("Auto-saved on scene transition to: " .. key)
    end
    
    originalSetScene(key, data)
end
    
function love.load()
  dream:init()
  scenery:hook(love)
  
  -- Print save directory for debugging
  print("===========================================")
  print("Save Directory: " .. love.filesystem.getSaveDirectory())
  print("===========================================")
  
  scenery.setScene("menu")
end

-- Debug keypressed
function love.keypressed(key)
    if key == "f5" then
        -- Manual save trigger for testing
        print("\n=== F5 PRESSED: Manual Save Test ===")
        local player = _G.currentPlayer
        if player then
            local state = SaveManager.captureGameState(currentSceneName, player, globalInventory)
            local success = SaveManager.saveToFile(SaveManager.autoSaveFile, state)
            print("Manual save result: " .. tostring(success))
        else
            print("No player found - start a game first")
        end
        print("====================================\n")
    elseif key == "f6" then
        -- Manual load test
        print("\n=== F6 PRESSED: Manual Load Test ===")
        print("Checking for: " .. SaveManager.autoSaveFile)
        local state = SaveManager.loadAutoSave()
        if state then
            print("✓ Load successful!")
            print("  Scene: " .. tostring(state.currentScene))
            print("  Version: " .. tostring(state.version))
        else
            print("✗ Load failed")
        end
        print("====================================\n")
    end
end

-- Update function to handle auto-save timer
function love.update(dt)
    -- Update auto-save notification timer
    if autoSaveTimer > 0 then
        autoSaveTimer = autoSaveTimer - dt
    end
    
    -- Periodic auto-save (only in gameplay scenes)
    if currentSceneName ~= "menu" and currentSceneName ~= "ending" then
        local player = _G.currentPlayer
        if SaveManager.updateAutoSave(dt, currentSceneName, player, globalInventory) then
            autoSaveNotification = "Game Auto-Saved"
            autoSaveTimer = 2
            print("Periodic auto-save triggered")
        end
    end
end

-- Draw auto-save notification
function love.draw()
    -- Draw auto-save notification with icon
    if autoSaveTimer > 0 then
        local alpha = math.min(1, autoSaveTimer)
        local x = love.graphics.getWidth() - 170
        local y = love.graphics.getHeight() - 45
        
        -- Background box
        love.graphics.setColor(0.2, 0.2, 0.2, 0.9 * alpha)
        love.graphics.rectangle("fill", x, y, 160, 35, 5, 5)
        
        -- Border
        love.graphics.setColor(0.2, 1, 0.2, alpha)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x, y, 160, 35, 5, 5)
        
        -- Save icon (floppy disk style)
        love.graphics.setColor(0.2, 1, 0.2, alpha)
        local iconX = x + 10
        local iconY = y + 8
        -- Outer rectangle
        love.graphics.rectangle("fill", iconX, iconY, 16, 18)
        -- Inner detail (dark square)
        love.graphics.setColor(0.2, 0.2, 0.2, alpha)
        love.graphics.rectangle("fill", iconX + 3, iconY + 10, 10, 6)
        -- Top notch
        love.graphics.rectangle("fill", iconX + 10, iconY, 6, 4)
        
        -- Text
        love.graphics.setColor(0.2, 1, 0.2, alpha)
        love.graphics.print(autoSaveNotification, x + 32, y + 10)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineWidth(1)
    end
end