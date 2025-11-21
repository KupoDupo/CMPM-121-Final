local Character = require("character")

local scene = {}

local player
local sun

function scene:load()
    love.graphics.setBackgroundColor(0.4, 0.6, 0.9)

    -- Create Player (This now loads player.obj internally)
    player = Character.new("Hero", 0, 0, 0)

    -- Setup Light
    -- Use bright intensity (1.5) to make sure we see the model
    sun = dream:newLight("sun", dream.vec3(5, 10, 5), dream.vec3(1, 0.9, 0.8), 1.5)
    sun:addNewShadow()
end

function scene:update(dt)
    if player then
        player:update(dt)
        
        -- Camera Logic
        dream.camera:resetTransform()
        -- Position: Follow player with an offset
        dream.camera:translate(player:getX(), 10, player:getZ() + 10)
        -- Rotation: Look down at player
        -- We use rotateX because lookAt() was buggy in your version
        dream.camera:rotateX(-0.8) 
    end
    
    dream:update(dt)
end

function scene:draw()
    dream:prepare()
    dream:addLight(sun)
    
    if player then
        player:draw()
        
        -- Draw Floor Grid using player object as a tile
        local floorObj = player:getObject()
        for x = -5, 5 do
            for z = -5, 5 do
                floorObj:resetTransform()
                floorObj:translate(x * 2, -1, z * 2)
                floorObj:scale(2, 0.1, 2) -- Flatten it
                dream:draw(floorObj)
            end
        end
    end
    
    dream:present()
    
    -- UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Room 1 - Click to Move", 10, 10)
end

function scene:mousepressed(x, y, button)
    if button == 1 and player then
        -- Simple "Top-Down" Raycast Approximation
        -- Since real raycasting was crashing, we estimate based on screen position
        local width, height = love.graphics.getDimensions()
        local dx = (x - width/2) / (height/2)
        local dy = (y - height/2) / (height/2)
        
        -- Adjust these numbers if the mouse click feels "off"
        local zoomScale = 12.0 
        
        local clickX = player:getX() + dx * zoomScale
        local clickZ = player:getZ() + (dy + 0.5) * zoomScale -- +0.5 accounts for camera angle
        
        player:walkTo(clickX, clickZ)
    end
end

return scene