local room1_scene = {}
local character = require('character')

local player;

function room1_scene:load()
  player = character.new('player', 1, 1)
end
  
function room1_scene:draw()
  player:draw()
  love.graphics.setColor(212, 65, 36)
  love.graphics.print("Room 1 yay!", 400, 300)
end

function room1_scene:update(dt)
  player:update(dt)
end

return room1_scene