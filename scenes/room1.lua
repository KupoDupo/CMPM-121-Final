local Character = require("character")

local scene = {}

local player
local sun

function scene:load()
    love.graphics.setBackgroundColor(0.4, 0.6, 0.9)

    -- Create Player
    player = Character.new("Hero", 0, 0, 0)
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

function scene:mousepressed(mouseX, mouseY, button)
    if button == 1 and player then
        local width, height = love.graphics.getDimensions()
        
        -- Convert screen click to -1..1 range
        local nx = (mouseX / width) * 2  - 2
        local nz = (mouseY / height) * 2 - 2

        -- Scale and flip to match your floor coordinates
        local scale = 10
        local targetX = -nx * scale
        local targetZ = -nz * scale  -- flip Z because screen y goes down

        player:walkTo(targetX, targetZ)
    end
end

return scene