-- Scenery setup
local SceneryInit = require("scenery")
scenery = SceneryInit("menu")

-- Other physics library (might delete later)
local bump = require 'bump-3dpd'

-- Dream engine global variable
dream = require("3DreamEngine")

function love.load()
  dream:init()
  scenery:hook(love)
  scenery.setScene("menu")
end