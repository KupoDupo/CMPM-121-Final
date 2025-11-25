local Character = require("character")

local room2_scene = {}
local player
local sun
local floor_tile

function room2_scene:load()
    love.graphics.setBackgroundColor(0.1, 0.15, 0.2)

    player = Character.new("Hero", 0, 0, 6)  -- Start at back of room
    
    floor_tile = dream:loadObject("assets/cube")

    sun = dream:newLight("sun", dream.vec3(10, 10, 10), dream.vec3(1, 1, 1), 1.5)
    sun:addNewShadow()
end

function room2_scene:update(dt)
    if player then
        player:update(dt)
        
        -- Fixed overhead camera
        dream.camera:resetTransform()
        dream.camera:translate(0, 8, 0)
        dream.camera:rotateX(-math.pi / 2)
    end
    
    dream:update(dt)
end

function room2_scene:draw()
    dream:prepare()
    dream:addLight(sun)
    
    if player then
        player:draw()
        
        -- Floor Grid
        if floor_tile then
            for x = -6, 6 do
                for z = -6, 6 do
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
    love.graphics.print("ROOM 2 - Under Construction", 10, 10)
    love.graphics.print("You made it through!", 10, 30)
end

function room2_scene:mousepressed(mouseX, mouseY, button)
    if button == 1 and player then
        local width, height = love.graphics.getDimensions()
        local nx = (mouseX / width) * 2 - 1
        local nz = (mouseY / height) * 2 - 1
        local targetX = nx * 18
        local targetZ = nz * 18
        player:walkTo(targetX, targetZ)
    end
end

function room2_scene:mousemoved(mouseX, mouseY)
end

return room2_scene
