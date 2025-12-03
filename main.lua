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
local isRestoringGame = false  -- Flag to prevent auto-save during restoration
local saveIcon = nil  -- Will hold the save icon image

-- Override scenery.setScene to track scene changes and trigger auto-save
local originalSetScene = scenery.setScene
function scenery.setScene(key, data)
    currentSceneName = key
    
    -- Auto-save on scene transitions (except menu and when restoring)
    if key ~= "menu" and key ~= "ending" and not isRestoringGame then
        local player = _G.currentPlayer
        local state = SaveManager.captureGameState(key, player, globalInventory)
        SaveManager.saveToFile(SaveManager.autoSaveFile, state)
        autoSaveNotification = "Game Auto-Saved"
        autoSaveTimer = 2
        print("Auto-saved on scene transition to: " .. key)
    elseif isRestoringGame then
        print("Skipping auto-save during game restoration")
    end
    
    originalSetScene(key, data)
end

-- Expose function to control restoration flag
function setRestoringGame(value)
    isRestoringGame = value
end
    
function love.load()
  dream:init()
  
  -- Load save icon
  saveIcon = love.graphics.newImage("assets/save-icon.png")
  
  -- Print save directory for debugging
  print("===========================================")
  print("Save Directory: " .. love.filesystem.getSaveDirectory())
  print("===========================================")
  
  -- Hook scenery but exclude update and draw so we can handle them ourselves
  local callbacksToHook = {}
  for k in pairs(love.handlers) do
    if k ~= "update" and k ~= "draw" then
      table.insert(callbacksToHook, k)
    end
  end
  scenery:hook(love, callbacksToHook)
  
  scenery.setScene("menu")
end

-- Debug keypressed - handled by scenery hook

-- Update function - call scenery update then our logic
function love.update(dt)
    -- Call scenery update for current scene
    scenery:update(dt)
    
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

-- Draw function - call scenery draw then our overlay
function love.draw()
    -- Call scenery draw for current scene
    scenery:draw()
    
    -- Draw auto-save notification with icon on top of everything
    if autoSaveTimer > 0 and saveIcon then
        local alpha = math.min(1, autoSaveTimer)
        local iconSize = 32  -- Size of the icon
        local padding = 10
        local textWidth = love.graphics.getFont():getWidth(autoSaveNotification)
        local boxWidth = iconSize + textWidth + padding * 3
        local boxHeight = iconSize + padding * 2
        
        local x = love.graphics.getWidth() - boxWidth - 15
        local y = love.graphics.getHeight() - boxHeight - 15
        
        -- Background box
        love.graphics.setColor(0.2, 0.2, 0.2, 0.9 * alpha)
        love.graphics.rectangle("fill", x, y, boxWidth, boxHeight, 5, 5)
        
        -- Border
        love.graphics.setColor(0.2, 1, 0.2, alpha)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x, y, boxWidth, boxHeight, 5, 5)
        
        -- Draw save icon image
        love.graphics.setColor(1, 1, 1, alpha)
        local iconX = x + padding
        local iconY = y + padding
        local scaleX = iconSize / saveIcon:getWidth()
        local scaleY = iconSize / saveIcon:getHeight()
        love.graphics.draw(saveIcon, iconX, iconY, 0, scaleX, scaleY)
        
        -- Text
        love.graphics.setColor(0.2, 1, 0.2, alpha)
        love.graphics.print(autoSaveNotification, iconX + iconSize + padding, y + (boxHeight - love.graphics.getFont():getHeight()) / 2)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineWidth(1)
    end
end