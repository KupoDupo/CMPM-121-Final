SceneryInit = require("scenery")
-- "menu" is the scene key (a string)
local scenery = SceneryInit("menu") 
scenery:hook(love)

local bump = require 'bump-3dpd'

dream = require("3DreamEngine/3DreamEngine")
dream:init()

objects = {
  sphere = dream:loadObject("examples/Physics/objects/sphere", { cleanup = false })
  }