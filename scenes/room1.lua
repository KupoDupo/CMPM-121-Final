local Character = require("character")
local Eyeball = require("eyeball")

local room1_scene = {}
local player
local sun
local item
local floor_tile

function room1_scene:load()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)

    player = Character.new("Hero", 0, 0, 0)
    
    -- Spawn Eyeball at (3, 3)
    eyeball = Eyeball.new(1, 3)
    
    floor_tile = dream:loadObject("assets/cube")

    sun = dream:newLight("sun", dream.vec3(10, 10, 10), dream.vec3(1, 1, 1), 1.5)
    sun:addNewShadow()
end

function room1_scene:update(dt)
    if player then
        player:update(dt)
        
        -- Camera follows player
        dream.camera:resetTransform()
        dream.camera:translate(0, 10, 0) 
        dream.camera:rotateX(-1.58) 
    end
    
    dream:update(dt)
    
end

function room1_scene:draw()
    dream:prepare()
    dream:addLight(sun)
    
    if player then
        player:draw()
        
        -- Draw Eyeball
        if eyeball then eyeball:draw() end
        
        -- Floor Grid
        if floor_tile then
          for x = -10, 10 do
              for z = -10, 10 do
                  floor_tile:resetTransform()
                  floor_tile:translate(x * 3, -1, z * 3)
                  floor_tile:scale(2, 0.1, 2)
                  dream:draw(floor_tile)
              end
          end
        end
    end
    
    dream:present()
    
    -- UI
    love.graphics.setColor(1, 1, 1)
    if eyeball and not eyeball.exists then
        love.graphics.print("EYEBALL COLLECTED!", 10, 10)
    else
        love.graphics.print("Find the Eyeball...", 10, 10)
    end
end

-- [[ UPDATED MOUSE LOGIC ]]
function room1_scene:mousepressed(mouseX, mouseY, button)
    if button == 1 and player then
        local width, height = love.graphics.getDimensions()
        
        -- 1. YOUR CUSTOM MATH
        -- Convert screen click to your specific coordinate system
        local nx = (mouseX / width) * 2 - 1
        local nz = (mouseY / height) * 2 - 1

        -- Scale and flip to match your floor coordinates
        local targetX = nx * 18
        local targetZ = nz * 16

        -- 2. EYEBALL PICKUP LOGIC
        -- We check the distance between the clicked spot (targetX, targetZ) and the eyeball
        local dist = 100
        if eyeball and eyeball.exists then
            dist = math.sqrt((targetX - eyeball.x)^2 + (targetZ - eyeball.z)^2)
        end
        
        -- If clicked close enough (distance < 1.0), pick it up
        if dist < 1.5 then
            eyeball.exists = false
            print("Eyeball collected!")
        else
            -- Otherwise, move the player
            player:walkTo(targetX, targetZ)
        end
        
      if eyeball then
        print("EYEBALL POS:", eyeball.x, eyeball.z, "EXISTS:", eyeball.exists)
      else
        print("NO EYEBALL VARIABLE!")
      end
      print("Clicked World Pos:", targetX, targetZ)
    end
end

return room1_scene