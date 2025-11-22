-- Scenery setup
local SceneryInit = require("scenery")
scenery = SceneryInit("menu")

-- 3DreamEngine
dream = require("3DreamEngine")

-- Other physics library (might delete later)
local bump = require 'bump-3dpd'
    
function love.load()
  dream:init()
  scenery:hook(love)
  scenery.setScene("menu")
end