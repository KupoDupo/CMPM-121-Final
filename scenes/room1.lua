local room1_scene = {}
local character = require('character')

local player
local sun

function room1_scene:load()
  love.graphics.setBackgroundColor(0.4, 0.6, 0.9)
  player = character.new('player', 1, 1, 1)
  sun = dream:newLight("sun", dream.vec3(5, 10, 5), dream.vec3(1, 0.9, 0.8), 1.5)
  sun:setShadow(true)
end
  
function room1_scene:draw()
  --[[player:draw()
  love.graphics.setColor(212, 65, 36)
  love.graphics.print("Room 1 yay!", 400, 300)--]]
  
  -- Add light to scene
  if sun then dream:addLight(sun) end

  if player then
    player:draw()
    
    -- Draw Floor (using player's cube mesh flattened)
    local floorObj = player:getObject()
    for x = -5, 5 do
      for z = -5, 5 do
        floorObj:resetTransform()
        floorObj:translate(x * 2, -1, z * 2)
        floorObj:scale(2, 0.1, 2)
        dream:draw(floorObj)
      end
    end
  end
    
    -- 2D UI Overlay
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Room 1 - Click to Move!", 10, 10)
end

function room1_scene:update(dt)
  if player then
    player:update(dt)
    
    -- Camera follows player
    dream.camera:reset()
    dream.camera:translate(player:getX(), 10, player:getZ() + 10)
    dream.camera:lookAt(player:getX(), 0, player:getZ())
  end
end

function room1_scene:mousepressed(x, y, button)
  if button == 1 and player then
    -- Raycast to find where we clicked on the floor
    local ro, rd = dream.camera:getRay(x, y)
    
    -- Check if looking down (rd.y < 0)
    if rd.y < -0.001 then
      local t = (0 - ro.y) / rd.y
      local hitX = ro.x + rd.x * t
      local hitZ = ro.z + rd.z * t
      
      -- Move player
      player:walkTo(hitX, hitZ)
    end
  end
end

return room1_scene