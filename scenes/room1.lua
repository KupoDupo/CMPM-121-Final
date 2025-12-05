local Character = require("character")
local Cannonball = require("cannonball")
local Cannon = require("cannon")
local Inventory = require("inventory")

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
local key_object
local key_item = { x = 0, z = -4.5, visible = false, collected = false }
local worldBounds = { minX = -12, maxX = 12, minZ = -12, maxZ = 12 }
local inventory
local cannonLoaded = false
local aimingMode = false
local missedShot = false
local missCount = 0
local gameOver = false
local mouseWorldX, mouseWorldZ = 0, 0
local isHoveringInteractive = false
local nearForwardDoor = false  -- Track if player is near forward exit
local interactionMessage = ""
local messageTimer = 0
local showTutorial = false
local tutorialText = {
    "Welcome to Escape the Haunted House!",
    "",
    "Controls:",
    "- Point and click to move around",
    "- Click objects to interact with them",
    "- Drag items from your inventory",
    "  to use them on objects",
    "",
    "Click anywhere to continue..."
}

function room1_scene:load()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)

    inventory = globalInventory  -- Use global inventory
    
    -- Check if tutorial should be shown
    if _G.showTutorialPopup then
        showTutorial = true
        _G.showTutorialPopup = false  -- Clear the flag
    end
    
    -- Restore player position from save or use default
    local startX, startY, startZ = 0, 0, 0
    print("=== ROOM1 LOAD ===")
    print("Checking for _G.savedPlayerPosition:", _G.savedPlayerPosition and "YES" or "NO")
    if _G.savedPlayerPosition then
        startX = _G.savedPlayerPosition.x
        startY = _G.savedPlayerPosition.y
        startZ = _G.savedPlayerPosition.z
        print("Restored player position:", startX, startY, startZ)
        _G.savedPlayerPosition = nil  -- Clear after use
    else
        print("Using default player position")
    end
    player = Character.new("Hero", startX, startY, startZ)
    _G.currentPlayer = player  -- Make globally accessible for save system
    
    -- Spawn Cannonball at (3, 3)
    cannonball = Cannonball.new(1, 3)
    
    -- Spawn a cannon (we place it to the left)
    cannon = Cannon.new(-6, 0)

    -- Locked door: place at the back of the (smaller) map (moved closer into frame)
    door = { x = 0, z = -6, locked = true }
    
    -- Restore room state if loading from save
    print("Checking for _G.room1State:", _G.room1State and "YES" or "NO")
    if _G.room1State then
        local state = _G.room1State
        print("Restoring room1 state:")
        print("  doorLocked:", state.doorLocked)
        print("  doorFallen:", state.doorFallen)
        print("  cannonballExists:", state.cannonballExists)
        door.locked = state.doorLocked
        door.fallen = state.doorFallen
        if state.cannonballPosition then
            cannonball = Cannonball.new(state.cannonballPosition.x, state.cannonballPosition.z)
        end
        cannonball.exists = state.cannonballExists
        cannonLoaded = state.cannonLoaded
        missCount = state.missCount
        gameOver = state.gameOver
        if state.keyVisible ~= nil then
            key_item.visible = state.keyVisible
        end
        if state.keyCollected ~= nil then
            key_item.collected = state.keyCollected
        end
        _G.room1State = nil  -- Clear after use
        print("Room1 state restored successfully")
    else
        print("No room1 state to restore - using defaults")
    end
    print("==================")

    -- create a dedicated object for the door so it doesn't reuse the floor tile transforms
    door_object = dream:loadObject("assets/cube")
    
    -- Create wall objects on both sides of the door
    wall_left = dream:loadObject("assets/cube")
    wall_right = dream:loadObject("assets/cube")
    key_object = dream:loadObject("assets/key")
    
    floor_tile = dream:loadObject("assets/cube")

    sun = dream:newLight("sun", dream.vec3(10, 10, 10), dream.vec3(1, 1, 1), 1.5)
    sun:addNewShadow()
end

function room1_scene:update(dt)
    -- Don't update game while tutorial is showing
    if showTutorial then
        return
    end
    
    if player then
        player:update(dt)
        
        -- Capture current state for save system
        _G.room1State = {
            doorLocked = door.locked,
            doorFallen = door.fallen or false,
            cannonballExists = cannonball and cannonball.exists or false,
            cannonballPosition = cannonball and { x = cannonball.x, z = cannonball.z } or { x = 1, z = 3 },
            cannonLoaded = cannonLoaded,
            missCount = missCount,
            gameOver = gameOver,
            keyVisible = key_item.visible,
            keyCollected = key_item.collected
        }
        
        -- Update door explosion/falling animation
        if door and door.exploding then
            door.explosionTime = door.explosionTime + dt
            -- Door falls down over 1 second
            if door.explosionTime > 1.0 then
                door.exploding = false
                door.fallen = true
                -- Make key visible when door is destroyed
                key_item.visible = true
            end
        end
        
        -- Auto-pickup key when player gets close
        if key_item.visible and not key_item.collected then
            local px, pz = player:getX(), player:getZ()
            local distToKey = math.sqrt((px - key_item.x)^2 + (pz - key_item.z)^2)
            if distToKey < 1.0 then
                key_item.collected = true
                inventory:addItem("Key_room1", "Room 1 Key")
                interactionMessage = "Found a key!"
                messageTimer = 2
            end
        end
        
        -- Auto-pickup cannonball when player gets close
        if cannonball and cannonball.exists then
            local px, pz = player:getX(), player:getZ()
            local distToCannonball = math.sqrt((px - cannonball.x)^2 + (pz - cannonball.z)^2)
            if distToCannonball < 1.0 then
                cannonball.exists = false
                local success = inventory:addItem("cannonball", "Cannonball")
                print("Cannonball added to inventory:", success)
                print("Inventory has cannonball:", inventory:hasItem("cannonball"))
                missedShot = false
                interactionMessage = "Cannonball collected!"
                messageTimer = 2
            end
        end
        
        -- Message timer
        if messageTimer > 0 then
            messageTimer = messageTimer - dt
        end
        
        -- Auto-load cannon when player gets close with cannonball
        if cannon and inventory:hasItem("cannonball") and not cannonLoaded then
            local px, pz = player:getX(), player:getZ()
            local distToCannon = math.sqrt((px - cannon.x)^2 + (pz - cannon.z)^2)
            if distToCannon < 1.5 then
                cannonLoaded = true
                inventory:removeItem("cannonball")
                aimingMode = true
                interactionMessage = "Cannon loaded! Click to aim and fire."
                messageTimer = 2
            end
        end
        
        -- Update cannon aim to follow mouse during aiming mode
        if aimingMode and cannon then
            cannon:aimAt(mouseWorldX, mouseWorldZ)
        end
        
        -- Check if player walks through the door opening when door is destroyed
        if door and door.fallen then
            local px, pz = player:getX(), player:getZ()
            local doorLeftX = door.x - 1.0
            local doorRightX = door.x + 1.0
            -- If player crosses through the door opening
            if px >= doorLeftX and px <= doorRightX and pz < door.z - 1.0 then
                nearForwardDoor = true
                interactionMessage = "Press E to go to Room 2"
                messageTimer = 0.1
            else
                nearForwardDoor = false
            end
        else
            nearForwardDoor = false
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
                if not cannonball.exists and not inventory:hasItem("cannonball") then
                    missCount = missCount + 1
                    print("Missed! Attempts remaining:", 3 - missCount)
                    
                    if missCount >= 3 then
                        gameOver = true
                        print("GAME OVER! Cannonball shattered after 3 misses!")
                    else
                        cannonball = Cannonball.new(pos.x, pos.z)
                        missedShot = true
                        print("Cannonball can be picked up again!")
                    end
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
        
        -- Draw key when visible and not collected
        if key_item.visible and not key_item.collected and key_object then
            local mat = dream:newMaterial()
            mat.color = {1, 0.84, 0, 1} -- Gold color
            mat.roughness = 0.2
            mat.metallic = 0.8
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
            
            paintRecursive(key_object, mat)
            key_object:resetTransform()
            key_object:translate(key_item.x, 0.6, key_item.z)
            key_object:scale(0.25, 0.25, 0.25)
            dream:draw(key_object)
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
    if isHoveringInteractive and not inventory.isOpen then
        local mx, my = love.mouse.getPosition()
        love.graphics.setColor(1, 1, 0, 0.8) -- Yellow with transparency
        love.graphics.circle("line", mx, my, 12, 20)
        love.graphics.circle("line", mx, my, 10, 20)
        love.graphics.setColor(1, 1, 1)
    end
    
    -- Draw inventory
    local mx, my = love.mouse.getPosition()
    inventory:draw(mx, my)
    
    -- Draw interaction message
    if messageTimer > 0 then
        love.graphics.setColor(0.2, 0.8, 0.2, math.min(1, messageTimer))
        love.graphics.rectangle("fill", love.graphics.getWidth() / 2 - 150, 60, 300, 40, 5, 5)
        love.graphics.setColor(1, 1, 1, math.min(1, messageTimer))
        love.graphics.printf(interactionMessage, love.graphics.getWidth() / 2 - 145, 72, 290, "center")
    end
    
    -- Draw door transition prompt (large and centered)
    if nearForwardDoor then
        local w, h = love.graphics.getWidth(), love.graphics.getHeight()
        local boxWidth, boxHeight = 400, 80
        local boxX, boxY = w / 2 - boxWidth / 2, h / 2 - boxHeight / 2
        
        -- Background box with border
        love.graphics.setColor(0.1, 0.1, 0.15, 0.95)
        love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 10, 10)
        love.graphics.setColor(0.3, 0.8, 0.3, 1)
        love.graphics.setLineWidth(4)
        love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 10, 10)
        love.graphics.setLineWidth(1)
        
        -- Text
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("[E] Go to Room 2", boxX, boxY + 20, boxWidth, "center")
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.printf("Press E to enter", boxX, boxY + 45, boxWidth, "center")
    end
    
    love.graphics.setColor(1, 1, 1)
    
    -- Objective display
    if gameOver then
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("PUZZLE FAILED!", 10, 60)
        love.graphics.print("The cannonball shattered after 3 misses.", 10, 80)
        love.graphics.setColor(1, 1, 1)
        
        -- Draw restart button
        local buttonX, buttonY = 10, 120
        local buttonWidth, buttonHeight = 130, 30
        local mx, my = love.mouse.getPosition()
        local isHovering = mx >= buttonX and mx <= buttonX + buttonWidth and my >= buttonY and my <= buttonY + buttonHeight
        
        if isHovering then
            love.graphics.setColor(0.3, 0.8, 0.3)
        else
            love.graphics.setColor(0.2, 0.6, 0.2)
        end
        love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", buttonX, buttonY, buttonWidth, buttonHeight)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("RESTART PUZZLE", buttonX + 10, buttonY + 8)
        
        love.graphics.setColor(1, 1, 1)
    elseif door and (door.exploding or door.fallen) then
        love.graphics.print("Objective: LEAVE THE ROOM!", 10, 60)
        love.graphics.setColor(0, 1, 0)
        love.graphics.print("Door destroyed! Head through the opening!", 10, 80)
        love.graphics.setColor(1, 1, 1)
    elseif missedShot then
        love.graphics.setColor(1, 0.5, 0)
        love.graphics.print("Objective: TRY AGAIN - Pick up the cannonball", 10, 60)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Attempts remaining: " .. (3 - missCount), 10, 80)
    elseif not inventory:hasItem("cannonball") then
        love.graphics.print("Objective: Find the Cannonball", 10, 60)
    elseif inventory:hasItem("cannonball") and not cannonLoaded and not aimingMode then
        love.graphics.print("Objective: Load the Cannonball into the Cannon", 10, 60)
        love.graphics.print("(Drag the cannonball from inventory to the cannon)", 10, 80)
    elseif aimingMode then
        love.graphics.print("Objective: BLAST THE DOOR!", 10, 60)
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("BLAST THE DOOR!", 10, 80)
        love.graphics.setColor(1, 1, 1)
        if missCount > 0 then
            love.graphics.setColor(1, 0.5, 0)
            love.graphics.print("Attempts remaining: " .. (3 - missCount), 10, 100)
            love.graphics.setColor(1, 1, 1)
        end
    else
        love.graphics.print("Objective: BLAST THE DOOR!", 10, 60)
    end
    
    -- Draw tutorial popup
    if showTutorial then
        local w, h = love.graphics.getWidth(), love.graphics.getHeight()
        
        -- Semi-transparent overlay
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, w, h)
        
        -- Tutorial box
        local boxWidth, boxHeight = 500, 300
        local boxX, boxY = w / 2 - boxWidth / 2, h / 2 - boxHeight / 2
        
        -- Box background
        love.graphics.setColor(0.15, 0.15, 0.2, 0.95)
        love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 10, 10)
        
        -- Box border
        love.graphics.setColor(0.3, 0.6, 0.8, 1)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 10, 10)
        love.graphics.setLineWidth(1)
        
        -- Draw tutorial text
        love.graphics.setColor(1, 1, 1, 1)
        local textY = boxY + 20
        local lineHeight = 25
        
        for i, line in ipairs(tutorialText) do
            if i == 1 then
                -- Title in larger font
                love.graphics.push()
                love.graphics.setNewFont(20)
                love.graphics.printf(line, boxX, textY, boxWidth, "center")
                love.graphics.pop()
                textY = textY + 35
            elseif i == 3 then
                -- "Controls:" header
                love.graphics.setColor(0.3, 0.8, 1, 1)
                love.graphics.printf(line, boxX + 20, textY, boxWidth - 40, "left")
                love.graphics.setColor(1, 1, 1, 1)
                textY = textY + lineHeight
            elseif line == "" then
                textY = textY + 10
            else
                love.graphics.printf(line, boxX + 20, textY, boxWidth - 40, "left")
                textY = textY + lineHeight
            end
        end
        
        love.graphics.setColor(1, 1, 1)
    end
end

-- [[ UPDATED MOUSE LOGIC ]]
function room1_scene:mousepressed(mouseX, mouseY, button)
    -- Close tutorial popup if showing
    if showTutorial and button == 1 then
        showTutorial = false
        return
    end
    
    -- Check inventory first
    if inventory:mousepressed(mouseX, mouseY, button) then
        return
    end
    
    if button == 1 and player then
        -- Don't allow world interaction if inventory is open
        if inventory.isOpen then
            return
        end
        
        -- Check for restart button click if game is over
        if gameOver then
            local buttonX, buttonY = 10, 120
            local buttonWidth, buttonHeight = 120, 30
            if mouseX >= buttonX and mouseX <= buttonX + buttonWidth and mouseY >= buttonY and mouseY <= buttonY + buttonHeight then
                -- Restart the puzzle
                gameOver = false
                missCount = 0
                missedShot = false
                inventory:clear()
                cannonLoaded = false
                aimingMode = false
                door.locked = true
                door.exploding = false
                door.fallen = false
                door.explosionTime = 0
                cannonball = Cannonball.new(1, 3)
                key_item.visible = false
                key_item.collected = false
                interactionMessage = "Puzzle restarted!"
                messageTimer = 2
            end
            return
        end
        
        -- If in aiming mode, shoot the cannon
        if aimingMode and cannon then
            local width, height = love.graphics.getDimensions()
            local nx = (mouseX / width) * 2 - 1
            local nz = (mouseY / height) * 2 - 1
            local targetX = nx * 9
            local targetZ = nz * 9
            
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
        local targetX = nx * 9
        local targetZ = nz * 9

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
    mouseWorldX = nx * 9
    mouseWorldZ = nz * 9
    
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
    if inventory:hasItem("cannonball") and not cannonLoaded and cannon then
        local cannonDist = math.sqrt((mouseWorldX - cannon.x)^2 + (mouseWorldZ - cannon.z)^2)
        if cannonDist < 2.0 then
            isHoveringInteractive = true
        end
    end
    
    -- Check key
    if key_item.visible and not key_item.collected then
        local keyDist = math.sqrt((mouseWorldX - key_item.x)^2 + (mouseWorldZ - key_item.z)^2)
        if keyDist < 1.0 then
            isHoveringInteractive = true
        end
    end
end

function room1_scene:mousereleased(mouseX, mouseY, button)
    -- Check if dragging item from inventory
    local droppedItem = inventory:mousereleased(mouseX, mouseY, button)
    
    if droppedItem then
        -- Convert mouse to world coordinates
        local width, height = love.graphics.getDimensions()
        local nx = (mouseX / width) * 2 - 1
        local nz = (mouseY / height) * 2 - 1
        local dropX = nx * 9
        local dropZ = nz * 9
        
        -- Check if dropping on cannon
        if droppedItem == "cannonball" and cannon and not cannonLoaded then
            local cannonDist = math.sqrt((dropX - cannon.x)^2 + (dropZ - cannon.z)^2)
            if cannonDist < 3.0 then
                -- Valid interaction - walk to cannon and load
                player:walkTo(cannon.x, cannon.z)
                interactionMessage = "Walking to cannon to load..."
                messageTimer = 2
                inventory:close()
            else
                interactionMessage = "Too far from cannon to load!"
                messageTimer = 2
            end
        else
            -- Invalid interaction
            if droppedItem == "cannonball" and cannonLoaded then
                interactionMessage = "Cannon is already loaded!"
            else
                interactionMessage = "Can't use that here."
            end
            messageTimer = 2
        end
    end
end

function room1_scene:keypressed(key)
    if key == "e" then
        if nearForwardDoor then
            print("Transitioning to Room 2!")
            scenery.setScene("room2")
            return true
        end
    end
    return inventory:keypressed(key)
end

return room1_scene