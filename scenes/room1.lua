local Character = require("character")
local Cannonball = require("cannonball")
local Cannon = require("cannon")

local room1_scene = {}
local player
local sun
local item
local floor_tile
local cannon
local door
local door_object
local worldBounds = { minX = -12, maxX = 12, minZ = -12, maxZ = 12 }

function room1_scene:load()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)

    player = Character.new("Hero", 0, 0, 0)
    
    -- Spawn Cannonball at (3, 3)
    cannonball = Cannonball.new(1, 3)
    
    -- Spawn a cannon (we place it to the left)
    cannon = Cannon.new(-6, 0)

    -- Locked door: place at the back of the (smaller) map (moved closer into frame)
    door = { x = 0, z = -6, locked = true }

    -- create a dedicated object for the door so it doesn't reuse the floor tile transforms
    door_object = dream:loadObject("assets/cube")
    
    floor_tile = dream:loadObject("assets/cube")

    sun = dream:newLight("sun", dream.vec3(10, 10, 10), dream.vec3(1, 1, 1), 1.5)
    sun:addNewShadow()
end

function room1_scene:update(dt)
    if player then
        player:update(dt)
        
        -- Camera follows player (lower height to zoom in)
        -- Fixed overhead camera (do not follow player)
        dream.camera:resetTransform()
        dream.camera:translate(0, 8, 0)
        dream.camera:rotateX(-math.pi / 2)
    end
    
    dream:update(dt)
    if cannon then cannon:update(dt, door) end
end

function room1_scene:draw()
    dream:prepare()
    dream:addLight(sun)
    
    if player then
        player:draw()
        
        -- Draw Cannonball
        if cannonball then cannonball:draw() end
        
                -- Floor Grid (smaller area to match camera)
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
        -- Draw cannon
        if cannon then cannon:draw() end

        -- Draw door using a dedicated cube object and colored material
        if door and door_object then
            -- color material for door: red when locked, green when unlocked
            local mat = dream:newMaterial()
            if door.locked then
                -- brown wood-like color when locked
                mat.color = {0.45, 0.27, 0.07, 1}
            else
                mat.color = {0.2, 1, 0.2, 1}
            end
            mat.roughness = 0.6
            mat.metallic = 0.0
            mat.cullMode = "none"

            local function paintRecursive(obj, material)
                if obj.meshes then
                    for _, mesh in pairs(obj.meshes) do
                        mesh.material = material
                    end
                end
                if obj.objects then
                    for _, child in pairs(obj.objects) do
                        paintRecursive(child, material)
                    end
                end
            end

            paintRecursive(door_object, mat)

            door_object:resetTransform()
            door_object:translate(door.x, 1.5, door.z)
            if door.locked then
                door_object:scale(1.5, 3.0, 0.2)
            else
                -- unlocked: smaller/flat to indicate open
                door_object:scale(0.2, 0.2, 0.2)
            end
            dream:draw(door_object)
        end
    
    dream:present()
    
    -- UI
    love.graphics.setColor(1, 1, 1)
    if cannonball and not cannonball.exists then
        love.graphics.print("CANNONBALL COLLECTED!", 10, 10)
    else
        love.graphics.print("Find the Cannonball...", 10, 10)
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
        local targetZ = nz * 18

        -- Clamp target so player doesn't walk out of the camera bounds
        if targetX < worldBounds.minX then targetX = worldBounds.minX end
        if targetX > worldBounds.maxX then targetX = worldBounds.maxX end
        if targetZ < worldBounds.minZ then targetZ = worldBounds.minZ end
        if targetZ > worldBounds.maxZ then targetZ = worldBounds.maxZ end

        -- 2. CANNONBALL PICKUP LOGIC
        -- We check the distance between the clicked spot (targetX, targetZ) and the cannonball
        local dist = 100
        if cannonball and cannonball.exists then
            dist = math.sqrt((targetX - cannonball.x)^2 + (targetZ - cannonball.z)^2)
        end
        
        -- If clicked close enough (distance < 1.0), pick it up
            if dist < .5 then
                cannonball.exists = false
                print("Cannonball collected!")
            else
                -- Otherwise, move the player
                -- Prevent walking past a locked door: if the door is locked and the
                -- clicked target would cross the door plane within the door's X range,
                -- clamp the target to stay on the player's current side of the door.
                if door and door.locked then
                    local doorHalfWidth = 1.0
                    local doorLeftX = door.x - doorHalfWidth
                    local doorRightX = door.x + doorHalfWidth
                    local buffer = 0.6 -- how far in front of the door to stop

                    -- Only consider clamping when the click is aimed at the door opening horizontally
                    if targetX >= doorLeftX and targetX <= doorRightX then
                        local px, pz = player:getX(), player:getZ()
                        -- If player is on the near/positive Z side and target is beyond door (smaller Z)
                        if pz > door.z and targetZ < door.z then
                            targetZ = door.z + buffer
                            print("Door is locked — cannot move past it.")
                        end
                        -- If player is on the far/negative Z side and target is on the near side
                        if pz < door.z and targetZ > door.z then
                            targetZ = door.z - buffer
                            print("Door is locked — cannot move past it.")
                        end
                    end
                end

                player:walkTo(targetX, targetZ)
            end
        
            if cannonball then
                print("CANNONBALL POS:", cannonball.x, cannonball.z, "EXISTS:", cannonball.exists)
            else
                print("NO CANNONBALL VARIABLE!")
            end
      print("Clicked World Pos:", targetX, targetZ)
    end

    -- Right click: aim & fire cannon at clicked position
    if button == 2 and cannon then
        local width, height = love.graphics.getDimensions()
        local nx = (mouseX / width) * 2 - 1
        local nz = (mouseY / height) * 2 - 1
        local targetX = nx * 18
        local targetZ = nz * 18
        -- clamp cannon target to world bounds so shots stay in-frame
        if targetX < worldBounds.minX then targetX = worldBounds.minX end
        if targetX > worldBounds.maxX then targetX = worldBounds.maxX end
        if targetZ < worldBounds.minZ then targetZ = worldBounds.minZ end
        if targetZ > worldBounds.maxZ then targetZ = worldBounds.maxZ end
        cannon:aimAt(targetX, targetZ)
        cannon:shoot(targetX, targetZ)
        print("Cannon fired at:", targetX, targetZ)
    end
end

return room1_scene