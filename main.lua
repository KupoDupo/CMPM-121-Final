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
    
function love.load()
  dream:init()
  scenery:hook(love)
  scenery.setScene("menu")
end