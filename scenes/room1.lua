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
local wall_left
local wall_right
local worldBounds = { minX = -12, maxX = 12, minZ = -12, maxZ = 12 }
local inventory = {}
local cannonLoaded = false
local aimingMode = false
local missedShot = false
local mouseWorldX, mouseWorldZ = 0, 0
local isHoveringInteractive = false

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
    
    -- Create wall objects on both sides of the door
    wall_left = dream:loadObject("assets/cube")
    wall_right = dream:loadObject("assets/cube")
    
    floor_tile = dream:loadObject("assets/cube")

    sun = dream:newLight("sun", dream.vec3(10, 10, 10), dream.vec3(1, 1, 1), 1.5)
    sun:addNewShadow()
end

function room1_scene:update(dt)
    if player then
        player:update(dt)
        
        -- Update door explosion/falling animation
        if door and door.exploding then
            door.explosionTime = door.explosionTime + dt
            -- Door falls down over 1 second
            if door.explosionTime > 1.0 then
                door.exploding = false
                door.fallen = true
            end
        end
        
        -- Auto-pickup cannonball when player gets close
        if cannonball and cannonball.exists then
            local px, pz = player:getX(), player:getZ()
            local distToCannonball = math.sqrt((px - cannonball.x)^2 + (pz - cannonball.z)^2)
            if distToCannonball < 1.0 then
                cannonball.exists = false
                inventory.cannonball = true
                missedShot = false
                print("Cannonball collected and added to inventory!")
            end
        end
        
        -- Auto-load cannon when player gets close with cannonball
        if cannon and inventory.cannonball and not cannonLoaded then
            local px, pz = player:getX(), player:getZ()
            local distToCannon = math.sqrt((px - cannon.x)^2 + (pz - cannon.z)^2)
            if distToCannon < 1.5 then
                cannonLoaded = true
                inventory.cannonball = false
                aimingMode = true
                print("Cannonball loaded! Click to aim and shoot the door.")
            end
        end
        
        -- Update cannon aim to follow mouse during aiming mode
        if aimingMode and cannon then
            cannon:aimAt(mouseWorldX, mouseWorldZ)
        end
        
        -- Camera follows player (lower height to zoom in)
        -- Fixed overhead camera (do not follow player)
        dream.camera:resetTransform()
        dream.camera:translate(0, 8, 0)
        dream.camera:rotateX(-math.pi / 2)
    end
    
    dream:update(dt)
    if cannon then 
        -- Pass wall boundaries for collision
        local walls = {
            leftX = -15, 
            rightX = 15, 
            doorZ = door.z,
            doorLeftX = door.x - 1.0,
            doorRightX = door.x + 1.0
        }
        local stoppedProjectiles = cannon:update(dt, door, walls, worldBounds)
        
        -- Create new cannonball pickups from stopped projectiles
        if stoppedProjectiles and #stoppedProjectiles > 0 then
            for _, pos in ipairs(stoppedProjectiles) do
                -- Only create new cannonball if current one doesn't exist and we don't have one in inventory
                if not cannonball.exists and not inventory.cannonball then
                    cannonball = Cannonball.new(pos.x, pos.z)
                    missedShot = true
                    print("Cannonball can be picked up again!")
                end
            end
        end
    end
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

        -- Draw walls on both sides of the door
        if wall_left and wall_right and door then
            local wall_mat = dream:newMaterial()
            wall_mat.color = {0.55, 0.37, 0.17, 1} -- lighter brown than door
            wall_mat.roughness = 0.6
            wall_mat.metallic = 0.0
            wall_mat.cullMode = "none"

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

            -- Left wall (extends from left edge to door)
            paintRecursive(wall_left, wall_mat)
            wall_left:resetTransform()
            local leftWallX = -15 -- left side of visible room (extended further)
            local leftWallWidth = math.abs(leftWallX - (door.x - 1.0))
            wall_left:translate(leftWallX + leftWallWidth/2, 1.5, door.z)
            wall_left:scale(leftWallWidth, 3.0, 0.2)
            dream:draw(wall_left)

            -- Right wall (extends from door to right edge)
            paintRecursive(wall_right, wall_mat)
            wall_right:resetTransform()
            local rightWallX = 15
            local rightWallWidth = math.abs(rightWallX - (door.x + 1.0))
            wall_right:translate(door.x + 1.0 + rightWallWidth/2, 1.5, door.z)
            wall_right:scale(rightWallWidth, 3.0, 0.2)
            dream:draw(wall_right)
        end

        -- Draw door using a dedicated cube object and colored material
        if door and door_object then
            -- color material for door: darker brown when locked, green when unlocked
            local mat = dream:newMaterial()
            if door.locked then
                -- darker brown wood color when locked
                mat.color = {0.35, 0.20, 0.05, 1}
            elseif door.exploding then
                -- Flash orange/red during explosion
                local flash = math.sin(door.explosionTime * 20) * 0.5 + 0.5
                mat.color = {1.0, 0.3 + flash * 0.4, 0.0, 1}
            elseif door.fallen then
                -- Darker brown when fallen
                mat.color = {0.25, 0.15, 0.05, 1}
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
            
            if door.exploding then
                -- Door falling/rotating animation
                local fallProgress = door.explosionTime
                door_object:translate(door.x, 1.5 - fallProgress * 2, door.z)
                door_object:rotateX(fallProgress * math.pi / 2) -- rotate forward
                door_object:scale(1.5, 3.0, 0.2)
            elseif door.fallen then
                -- Door flat on ground
                door_object:translate(door.x, 0.1, door.z - 1.5)
                door_object:rotateX(math.pi / 2)
                door_object:scale(1.5, 3.0, 0.2)
            elseif door.locked then
                door_object:translate(door.x, 1.5, door.z)
                door_object:scale(1.5, 3.0, 0.2)
            else
                -- unlocked: smaller/flat to indicate open
                door_object:translate(door.x, 1.5, door.z)
                door_object:scale(0.2, 0.2, 0.2)
            end
            dream:draw(door_object)
        end
    
    dream:present()
    
    -- Draw aiming trajectory line when in aiming mode
    if aimingMode and cannon then
        love.graphics.setColor(1, 0, 0, 0.8) -- Red trajectory line
        love.graphics.setLineWidth(3)
        
        -- Convert cannon world position to screen
        local width, height = love.graphics.getDimensions()
        local cannonScreenX = (cannon.x / 18 + 1) * width / 2
        local cannonScreenZ = (cannon.z / 18 + 1) * height / 2
        
        -- Draw line from cannon to mouse
        local mx, my = love.mouse.getPosition()
        love.graphics.line(cannonScreenX, cannonScreenZ, mx, my)
        
        -- Draw targeting circle at mouse
        love.graphics.circle("line", mx, my, 15, 20)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1)
        
        -- Draw instruction text
        love.graphics.print("AIMING MODE: Click to shoot!", width/2 - 100, 10)
    end
    
    -- Draw custom cursor if hovering over interactive object
    if isHoveringInteractive then
        local mx, my = love.mouse.getPosition()
        love.graphics.setColor(1, 1, 0, 0.8) -- Yellow with transparency
        love.graphics.circle("line", mx, my, 12, 20)
        love.graphics.circle("line", mx, my, 10, 20)
        love.graphics.setColor(1, 1, 1)
    end
    
    -- UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Inventory:", 10, 10)
    if inventory.cannonball then
        love.graphics.print("- Cannonball", 10, 30)
    end
    
    -- Objective display
    if door and (door.exploding or door.fallen) then
        love.graphics.print("Objective: LEAVE THE ROOM!", 10, 60)
        love.graphics.setColor(0, 1, 0)
        love.graphics.print("Door destroyed! Head through the opening!", 10, 80)
        love.graphics.setColor(1, 1, 1)
    elseif missedShot then
        love.graphics.print("Objective: TRY AGAIN - Pick up the cannonball", 10, 60)
    elseif not inventory.cannonball then
        love.graphics.print("Objective: Find the Cannonball", 10, 60)
    elseif inventory.cannonball and not cannonLoaded and not aimingMode then
        love.graphics.print("Objective: Load the Cannonball into the Cannon", 10, 60)
        love.graphics.print("(Walk near the cannon and click it)", 10, 80)
    elseif aimingMode then
        love.graphics.print("Objective: BLAST THE DOOR!", 10, 60)
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("BLAST THE DOOR!", 10, 80)
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.print("Objective: BLAST THE DOOR!", 10, 60)
    end
end

-- [[ UPDATED MOUSE LOGIC ]]
function room1_scene:mousepressed(mouseX, mouseY, button)
    if button == 1 and player then
        -- If in aiming mode, shoot the cannon
        if aimingMode and cannon then
            local width, height = love.graphics.getDimensions()
            local nx = (mouseX / width) * 2 - 1
            local nz = (mouseY / height) * 2 - 1
            local targetX = nx * 18
            local targetZ = nz * 18
            
            -- Clamp target to world bounds
            if targetX < worldBounds.minX then targetX = worldBounds.minX end
            if targetX > worldBounds.maxX then targetX = worldBounds.maxX end
            if targetZ < worldBounds.minZ then targetZ = worldBounds.minZ end
            if targetZ > worldBounds.maxZ then targetZ = worldBounds.maxZ end
            
            cannon:aimAt(targetX, targetZ)
            cannon:shoot(targetX, targetZ)
            aimingMode = false
            cannonLoaded = false
            print("Cannon fired at:", targetX, targetZ)
            return
        end
        
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
        -- Apply Z offset to correct hitbox alignment
        local dist = 100
        if cannonball and cannonball.exists then
            local hitboxOffsetZ = 4 -- offset to lower the hitbox
            dist = math.sqrt((targetX - cannonball.x)^2 + (targetZ - (cannonball.z + hitboxOffsetZ))^2)
            print("Distance to cannonball:", dist, "Threshold: 0.5")
        end
        
        -- If clicking on cannonball, walk to it
            if dist < 0.5 then
                -- Walk to the actual cannonball position
                player:walkTo(cannonball.x, cannonball.z)
            else
                -- Check if clicking near cannon
                if cannon then
                    local cannonDist = math.sqrt((targetX - cannon.x)^2 + (targetZ - cannon.z)^2)
                    if cannonDist < 2.0 then
                        if inventory.cannonball and not cannonLoaded then
                            -- Walk to cannon to load it
                            player:walkTo(cannon.x, cannon.z)
                            print("Walking to cannon to load it...")
                        elseif not inventory.cannonball and not cannonLoaded then
                            -- Examine cannon without cannonball
                            print("This is an old cannon. Maybe we can load it with something...")
                        end
                        return
                    end
                end
                
                -- Otherwise, move the player
                -- Prevent walking past the wall/door barrier
                if door then
                    local doorHalfWidth = 1.0
                    local doorLeftX = door.x - doorHalfWidth
                    local doorRightX = door.x + doorHalfWidth
                    local buffer = 0.6 -- how far in front of the wall/door to stop

                    local px, pz = player:getX(), player:getZ()
                    
                    -- Block movement through the entire wall/door plane
                    -- If player is on the near/positive Z side and target is beyond wall (smaller Z)
                    if pz > door.z and targetZ < door.z then
                        -- Allow passing only through the door opening when unlocked
                        if door.locked or targetX < doorLeftX or targetX > doorRightX then
                            targetZ = door.z + buffer
                            if door.locked and targetX >= doorLeftX and targetX <= doorRightX then
                                print("Door is locked — cannot move past it.")
                            else
                                print("Cannot move through the wall.")
                            end
                        end
                    end
                    -- If player is on the far/negative Z side and target is on the near side
                    if pz < door.z and targetZ > door.z then
                        if door.locked or targetX < doorLeftX or targetX > doorRightX then
                            targetZ = door.z - buffer
                            if door.locked and targetX >= doorLeftX and targetX <= doorRightX then
                                print("Door is locked — cannot move past it.")
                            else
                                print("Cannot move through the wall.")
                            end
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
end

function room1_scene:mousemoved(mouseX, mouseY)
    -- Convert mouse position to world coordinates
    local width, height = love.graphics.getDimensions()
    local nx = (mouseX / width) * 2 - 1
    local nz = (mouseY / height) * 2 - 1
    mouseWorldX = nx * 18
    mouseWorldZ = nz * 18
    
    -- Check if hovering over interactive objects
    isHoveringInteractive = false
    
    -- Check cannonball
    if cannonball and cannonball.exists then
        local hitboxOffsetZ = 3.5 -- offset to lower the hitbox
        local dist = math.sqrt((mouseWorldX - cannonball.x)^2 + (mouseWorldZ - (cannonball.z + hitboxOffsetZ))^2)
        if dist < 0.5 then
            isHoveringInteractive = true
        end
    end
    
    -- Check cannon (if cannonball is in inventory and not loaded)
    if inventory.cannonball and not cannonLoaded and cannon then
        local cannonDist = math.sqrt((mouseWorldX - cannon.x)^2 + (mouseWorldZ - cannon.z)^2)
        if cannonDist < 2.0 then
            isHoveringInteractive = true
        end
    end
end

return room1_scene