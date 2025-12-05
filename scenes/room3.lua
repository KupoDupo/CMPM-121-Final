local Character = require("character")
local Inventory = require("inventory")

local room3_scene = {}
local player
local sun
local floor_tile
local door
local door_object
local wall_left
local wall_right
local worldBounds = { minX = -12, maxX = 12, minZ = -12, maxZ = 12 }
local inventory
local mouseWorldX, mouseWorldZ = 0, 0
local isHoveringInteractive = false
local interactionMessage = ""
local messageTimer = 0

-- Puzzle state
-- Three keys total: Key_room1, Key_room2, Key_room3
local key_local = { x = 2, z = 2, collected = false }

-- Door with lock tracking
door = { x = 0, z = -6, locked = true, disappeared = false }
local backDoor = { x = 0, z = 8 }  -- Door to go back to Room 2
local backDoor_object
local teleportCooldown = 0  -- Prevent immediate re-teleportation
local nearForwardDoor = false  -- Track if player is near forward exit
local nearBackDoor = false  -- Track if player is near back exit
local locksRemaining = 3  -- Three locks on the door
local keysUsedOnDoor = {
    Key_room1 = false,
    Key_room2 = false,
    Key_room3 = false
}

function room3_scene:load()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
    
    teleportCooldown = 1.0  -- 1 second cooldown after entering room
    
    inventory = globalInventory  -- Use global inventory
    
    -- Restore player position from save or use default
    local startX, startY, startZ = 0, 0, 0
    if _G.savedPlayerPosition then
        startX = _G.savedPlayerPosition.x
        startY = _G.savedPlayerPosition.y
        startZ = _G.savedPlayerPosition.z
        _G.savedPlayerPosition = nil
    end
    player = Character.new("Hero", startX, startY, startZ)
    _G.currentPlayer = player
    
    floor_tile = dream:loadObject("assets/cube")
    door_object = dream:loadObject("assets/cube")
    backDoor_object = dream:loadObject("assets/cube")
    wall_left = dream:loadObject("assets/cube")
    wall_right = dream:loadObject("assets/cube")
    key_object = dream:loadObject("assets/key")
    sun = dream:newLight("sun", dream.vec3(10, 10, 10), dream.vec3(1,1,1), 1.5)
    sun:addNewShadow()
    
    -- Restore room state if loading from save
    if _G.room3State then
        local state = _G.room3State
        key_local.collected = state.keyCollected
        door.locked = not state.doorUnlocked
        door.disappeared = state.doorUnlocked
        if state.keysUsedOnDoor then
            keysUsedOnDoor = state.keysUsedOnDoor
        end
        if state.locksRemaining then
            locksRemaining = state.locksRemaining
        end
        _G.room3State = nil
    end
end

function room3_scene:update(dt)
    -- Update teleport cooldown
    if teleportCooldown > 0 then
        teleportCooldown = teleportCooldown - dt
    end
    
    if player then
        player:update(dt)
        
        -- Capture current state for save system
        _G.room3State = {
            keyCollected = key_local.collected,
            doorUnlocked = door.disappeared,
            keysUsedOnDoor = keysUsedOnDoor,
            locksRemaining = locksRemaining
        }

        if messageTimer > 0 then
            messageTimer = messageTimer - dt
        end

        -- Pick up the local Room 3 key
        if not key_local.collected then
            local dx = player:getX() - key_local.x
            local dz = player:getZ() - key_local.z
            if math.sqrt(dx*dx + dz*dz) < 1.2 then
                key_local.collected = true
                inventory:addItem("Key_room3", "Room 3 Key")
                interactionMessage = _G.localization:get("picked_up_key")
                messageTimer = 3
            end
        end

        -- Check if all locks have been removed
        if locksRemaining == 0 then
            door.locked = false
            door.disappeared = true
        end

        -- Exit through the door
        local px, pz = player:getX(), player:getZ()
        if teleportCooldown <= 0 and door.disappeared and px >= door.x - 1 and px <= door.x + 1 and pz <= door.z + 1 then
            nearForwardDoor = true
            interactionMessage = "Press E to enter Ending"
            messageTimer = 0.1
        else
            nearForwardDoor = false
        end
        
        -- Back door - return to Room 2
        if teleportCooldown <= 0 and px >= backDoor.x - 2 and px <= backDoor.x + 2 and pz >= backDoor.z - 1 then
            nearBackDoor = true
            interactionMessage = "Press E to return to Room 2"
            messageTimer = 0.1
        else
            nearBackDoor = false
        end

        -- Fixed overhead camera
        dream.camera:resetTransform()
        dream.camera:translate(0, 8, 0)
        dream.camera:rotateX(-math.pi / 2)
    end

    dream:update(dt)
end

function room3_scene:draw()
    dream:prepare()
    dream:addLight(sun)

    if player then
        player:draw()

        -- Draw floor
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

    -- Draw walls
    if wall_left and wall_right then
        local wall_mat = dream:newMaterial()
        wall_mat.color = {0.55, 0.37, 0.17, 1}
        wall_mat.roughness = 0.6
        wall_mat.cullMode = "none"

        local function paintRecursive(obj, material)
            if obj.meshes then
                for _, mesh in pairs(obj.meshes) do mesh.material = material end
            end
            if obj.objects then
                for _, child in pairs(obj.objects) do paintRecursive(child, material) end
            end
        end

        -- Left wall
        paintRecursive(wall_left, wall_mat)
        wall_left:resetTransform()
        wall_left:translate(-15 + (door.x-1+15)/2, 1.5, door.z)
        wall_left:scale(math.abs(-15 - (door.x-1)), 3.0, 0.2)
        dream:draw(wall_left)

        -- Right wall
        paintRecursive(wall_right, wall_mat)
        wall_right:resetTransform()
        wall_right:translate(door.x+1 + (15-(door.x+1))/2, 1.5, door.z)
        wall_right:scale(math.abs(15-(door.x+1)), 3.0, 0.2)
        dream:draw(wall_right)
    end

    -- Draw door only if it hasn't disappeared
    if door_object and not door.disappeared then
        local mat = dream:newMaterial()
        mat.color = door.locked and {0.35,0.20,0.05,1} or {0.2,1,0.2,1}
        mat.roughness = 0.6
        mat.cullMode = "none"

        local function paintRecursive(obj, material)
            if obj.meshes then for _, mesh in pairs(obj.meshes) do mesh.material = material end end
            if obj.objects then for _, child in pairs(obj.objects) do paintRecursive(child, material) end end
        end

        paintRecursive(door_object, mat)
        door_object:resetTransform()
        door_object:translate(door.x, 1.5, door.z)
        door_object:scale(2, 3, 0.2)
        dream:draw(door_object)
    end
    
    -- Draw back door
    if backDoor_object then
        local backDoor_mat = dream:newMaterial()
        backDoor_mat.color = {0.2, 0.5, 0.2, 1}  -- Green color to indicate exit
        backDoor_mat.roughness = 0.4
        backDoor_mat.cullMode = "none"
        
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
        
        paintRecursive(backDoor_object, backDoor_mat)
        backDoor_object:resetTransform()
        backDoor_object:translate(backDoor.x, 1.5, backDoor.z)
        backDoor_object:scale(2.0, 3.0, 0.2)
        dream:draw(backDoor_object)
    end

    -- Draw local Room 3 key (player must also have the Room 2 key in inventory to unlock door)
    if key_local and not key_local.collected then
        local mat = dream:newMaterial()
        mat.color = {1, 1, 0.2, 1}
        mat.roughness = 0.2
        mat.cullMode = "none"
        local function paintRecursive(obj, material)
            if obj.meshes then for _, mesh in pairs(obj.meshes) do mesh.material = material end end
            if obj.objects then for _, child in pairs(obj.objects) do paintRecursive(child, material) end end
        end
        paintRecursive(key_object, mat)
        key_object:resetTransform()
        key_object:translate(key_local.x, 0.6, key_local.z)
        key_object:scale(0.4,0.4,0.4)
        dream:draw(key_object)
    end

    dream:present()

    -- Draw inventory
    local mx,my = love.mouse.getPosition()
    inventory:draw(mx,my)

    -- Draw lock squares on the door (convert world coordinates to screen)
    if not door.disappeared then
        local w, h = love.graphics.getDimensions()
        -- Door is at world position (door.x, door.z)
        -- Convert to screen coordinates using the same math as mouse input
        local doorScreenX = (door.x / 9 + 1) * w / 2
        local doorScreenY = (door.z / 9 + 1) * h / 2
        
        local lockSize = 25
        local lockSpacing = 8
        local totalWidth = 3 * lockSize + 2 * lockSpacing
        local startX = doorScreenX - totalWidth / 2
        local startY = doorScreenY - lockSize / 2
        
        for i = 1, 3 do
            local lockX = startX + (i - 1) * (lockSize + lockSpacing)
            local lockY = startY
            
            if i <= locksRemaining then
                -- Draw filled lock square
                love.graphics.setColor(0.6, 0.3, 0.1, 0.9)
                love.graphics.rectangle("fill", lockX, lockY, lockSize, lockSize, 3, 3)
                love.graphics.setColor(0.9, 0.7, 0.3)
                love.graphics.setLineWidth(3)
                love.graphics.rectangle("line", lockX, lockY, lockSize, lockSize, 3, 3)
                love.graphics.setLineWidth(1)
            else
                -- Draw empty/removed lock
                love.graphics.setColor(0.2, 0.2, 0.2, 0.4)
                love.graphics.rectangle("fill", lockX, lockY, lockSize, lockSize, 3, 3)
                love.graphics.setColor(0.4, 0.4, 0.4, 0.6)
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", lockX, lockY, lockSize, lockSize, 3, 3)
                love.graphics.setLineWidth(1)
            end
        end
    end
    
    -- Draw objective text
    love.graphics.setColor(1, 1, 1)
    local hasRoom1Key = inventory:hasItem("Key_room1")
    local hasRoom2Key = inventory:hasItem("Key_room2")
    local hasRoom3Key = inventory:hasItem("Key_room3")
    local totalKeys = (hasRoom1Key and 1 or 0) + (hasRoom2Key and 1 or 0) + (hasRoom3Key and 1 or 0)
    
    if door.disappeared then
        love.graphics.print("Objective: Exit through the door!", 10, 80)
    elseif totalKeys == 3 then
        love.graphics.print("Objective: Use keys on door", 10, 80)
        love.graphics.setColor(0.8, 0.8, 0)
        love.graphics.print("(Open inventory and drag keys to the door)", 10, 100)
    elseif totalKeys < 3 then
        love.graphics.print("Objective: Collect all keys (" .. totalKeys .. "/3)", 10, 80)
    end

    -- Draw interaction messages
    if messageTimer>0 then
        love.graphics.setColor(0.2,0.8,0.2,math.min(1,messageTimer))
        love.graphics.rectangle("fill", love.graphics.getWidth()/2-150,130,300,40,5,5)
        love.graphics.setColor(1,1,1,math.min(1,messageTimer))
        love.graphics.printf(interactionMessage, love.graphics.getWidth()/2-145,142,290,"center")
    end
    
    -- Draw door transition prompts (large and centered)
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
        love.graphics.printf("[E] Enter Ending", boxX, boxY + 20, boxWidth, "center")
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.printf("Press E to proceed", boxX, boxY + 45, boxWidth, "center")
    elseif nearBackDoor then
        local w, h = love.graphics.getWidth(), love.graphics.getHeight()
        local boxWidth, boxHeight = 400, 80
        local boxX, boxY = w / 2 - boxWidth / 2, h / 2 - boxHeight / 2
        
        -- Background box with border (different color for back door)
        love.graphics.setColor(0.1, 0.1, 0.15, 0.95)
        love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 10, 10)
        love.graphics.setColor(0.8, 0.6, 0.3, 1)
        love.graphics.setLineWidth(4)
        love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 10, 10)
        love.graphics.setLineWidth(1)
        
        -- Text
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("[E] Return to Room 2", boxX, boxY + 20, boxWidth, "center")
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.printf("Press E to go back", boxX, boxY + 45, boxWidth, "center")
    end

    love.graphics.setColor(1,1,1)
    
    -- Draw objectives
    love.graphics.setFont(_G.localization:getFont())
    love.graphics.print(_G.localization:get("room3_title"), 10, 10)
    
    if door.disappeared then
        love.graphics.setColor(0, 1, 0)
        love.graphics.print(_G.localization:get("room3_door_unlocked"), 10, 40)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(_G.localization:get("room3_obj_exit"), 10, 60)
    else
        love.graphics.print(_G.localization:get("room3_obj_find_keys"), 10, 40)
        local keysCollected = 0
        if inventory:hasItem("Key") then keysCollected = keysCollected + 1 end
        if inventory:hasItem("Key_room3") then keysCollected = keysCollected + 1 end
        love.graphics.print(_G.localization:get("room3_keys_collected") .. keysCollected .. "/2", 10, 60)
    end
    
    love.graphics.setColor(1,1,1)
end

function room3_scene:mousepressed(mx,my,button)
    if inventory:mousepressed(mx,my,button) then return end
    if button==1 and player then
        if inventory.isOpen then return end

        -- Convert click to world coords
        local w,h = love.graphics.getDimensions()
        local nx = (mx/w)*2 - 1
        local nz = (my/h)*2 - 1
        local targetX,targetZ = nx*9, nz*9
        if targetX<worldBounds.minX then targetX=worldBounds.minX end
        if targetX>worldBounds.maxX then targetX=worldBounds.maxX end
        if targetZ<worldBounds.minZ then targetZ=worldBounds.minZ end
        if targetZ>worldBounds.maxZ then targetZ=worldBounds.maxZ end

        -- Block walls only if door exists
        if not door.disappeared then
            local doorHalf = 1.0
            local doorLeft, doorRight = door.x - doorHalf, door.x + doorHalf
            local px,pz = player:getX(),player:getZ()
            if pz > door.z and targetZ < door.z then
                if door.locked or targetX<doorLeft or targetX>doorRight then
                    targetZ = door.z + 0.6
                end
            end
            if pz < door.z and targetZ > door.z then
                if door.locked or targetX<doorLeft or targetX>doorRight then
                    targetZ = door.z - 0.6
                end
            end
        end

        player:walkTo(targetX,targetZ)
    end
end

function room3_scene:mousemoved(mx,my)
    local w,h = love.graphics.getDimensions()
    local nx = (mx/w)*2 - 1
    local nz = (my/h)*2 - 1
    mouseWorldX, mouseWorldZ = nx*9, nz*9
end

function room3_scene:mousereleased(mx,my,button)
    local droppedItem = inventory:mousereleased(mx,my,button)
    
    if droppedItem then
        -- Check if it's a key being used on the door
        if (droppedItem == "Key_room1" or droppedItem == "Key_room2" or droppedItem == "Key_room3") and not door.disappeared then
            -- Check if this key hasn't been used yet
            if not keysUsedOnDoor[droppedItem] then
                -- Convert mouse to world coordinates to check if near door
                local w,h = love.graphics.getDimensions()
                local nx = (mx/w)*2 - 1
                local nz = (my/h)*2 - 1
                local dropX, dropZ = nx*9, nz*9
                
                -- Check if dropped near the door (within reasonable range)
                local distToDoor = math.sqrt((dropX - door.x)^2 + (dropZ - door.z)^2)
                
                if distToDoor < 3.0 then
                    -- Use the key on the door
                    keysUsedOnDoor[droppedItem] = true
                    locksRemaining = locksRemaining - 1
                    inventory:removeItem(droppedItem)
                    
                    local keyNames = {
                        Key_room1 = "Room 1 Key",
                        Key_room2 = "Room 2 Key",
                        Key_room3 = "Room 3 Key"
                    }
                    
                    interactionMessage = "Used " .. keyNames[droppedItem] .. " on door! (" .. locksRemaining .. " locks remaining)"
                    messageTimer = 3
                    
                    -- Check if all locks are removed
                    if locksRemaining == 0 then
                        door.locked = false
                        door.disappeared = true
                        interactionMessage = "All locks removed! The door is open!"
                        messageTimer = 3
                    end
                else
                    interactionMessage = "Too far from the door!"
                    messageTimer = 2
                end
            else
                interactionMessage = "Already used this key on the door!"
                messageTimer = 2
            end
        end
        
        -- Close inventory after any interaction attempt
        inventory:close()
    end
end

function room3_scene:keypressed(key)
    if key == "escape" then
        print("Returning to main menu...")
        scenery.setScene("menu")
        return true
    elseif key == "s" then
        local SaveManager = require("savemanager")
        local player = _G.currentPlayer
        if SaveManager.manualSave(1, "room3", player, globalInventory) then
            _G.manualSaveNotification = _G.localization:get("manual_save_notification")
            _G.manualSaveTimer = 2
            print("Manual save successful")
        end
        return true
    elseif key == "e" then
        if nearForwardDoor then
            print("Player reached the exit! Loading ending scene...")
            scenery.setScene("ending")
            return true
        elseif nearBackDoor then
            print("Returning to Room 2...")
            _G.savedPlayerPosition = { x = 0, y = 0, z = -7 }  -- Spawn near forward door in room 2
            _G.previousRoom = "room3"  -- Track where we came from
            scenery.setScene("room2")
            return true
        end
    end
    return inventory:keypressed(key)
end

return room3_scene
