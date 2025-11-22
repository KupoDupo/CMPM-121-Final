local Character = require("character")
local Eyeball = require("eyeball")

local scene = {}
local player
local sun
local item

function scene:load()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)

    player = Character.new("Hero", 0, 0, 0)
    
    -- Spawn Eyeball at (3, 3)
    eyeball = Eyeball.new(3, 3)

    sun = dream:newLight("sun", dream.vec3(10, 10, 10), dream.vec3(1, 1, 1), 1.5)
    sun:addNewShadow()
end

function scene:update(dt)
    if player then
        player:update(dt)
        
        -- Camera follows player
        dream.camera:resetTransform()
        dream.camera:translate(player:getX(), 10, player:getZ()) 
        dream.camera:rotateX(-1.58) 
    end
    
    -- Spin eyeball
    if eyeball and eyeball.exists then
        eyeball.object:rotateY(dt)
    end
    
    dream:update(dt)
end

function scene:draw()
    dream:prepare()
    dream:addLight(sun)
    
    if player then
        player:draw()
        
        -- Draw Eyeball
        if eyeball then eyeball:draw() end
        
        -- Floor Grid
        local floorObj = player:getObject()
        for x = -10, 10 do
            for z = -10, 10 do
                floorObj:resetTransform()
                --floorObj:translate(x * 3, -1, z * 3)
                floorObj:scale(2, 0.1, 2)
                dream:draw(floorObj)
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
function scene:mousepressed(mouseX, mouseY, button)
    if button == 1 and player then
        local width, height = love.graphics.getDimensions()
        
        -- 1. YOUR CUSTOM MATH
        -- Convert screen click to your specific coordinate system
        local nx = (mouseX / width) * 2 - 1
        local nz = (mouseY / height) * 2 - 1

        -- Scale and flip to match your floor coordinates
        local scale = 10
        local targetX = -nx * 16
        local targetZ = -nz * 10  -- flip Z because screen y goes down

        -- 2. EYEBALL PICKUP LOGIC
        -- We check the distance between the clicked spot (targetX, targetZ) and the eyeball
        local dist = 100
        if eyeball and eyeball.exists then
            dist = math.sqrt((targetX - eyeball.x)^2 + (targetZ - eyeball.z)^2)
        end
        
        -- If clicked close enough (distance < 1.0), pick it up
        if dist < 1.0 then
            eyeball.exists = false
            print("Eyeball collected!")
        else
            -- Otherwise, move the player
            player:walkTo(targetX, targetZ)
        end
    end
end

return scene