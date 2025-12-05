local Character = require("character")
local Inventory = require("inventory")

local room2_scene = {}
local player
local sun
local floor_tile
local gap_object
local bridge_object
local plate_objects = {}
local block_objects = {}
local door_object
local worldBounds = { minX = -12, maxX = 12, minZ = -12, maxZ = 12 }
local mouseWorldX, mouseWorldZ = 0, 0
local isHoveringInteractive = false
local selectedBlock = nil
local inventory
local interactionMessage = ""
local messageTimer = 0
local playerDead = false
local deathTimer = 0
local key_object
local key = { x = 5, z = 5, collected = false}
local keySpawned = false

-- Puzzle state
local blocks = {}
local pressurePlates = {}
local bridge = { extended = false }
local door = { x = 0, z = -9, locked = true }
local initialBlockPositions = {}
local placedBoxes = {}  -- Boxes placed on pressure plates from inventory

function room2_scene:load()
    love.graphics.setBackgroundColor(0.1, 0.15, 0.2)

    inventory = globalInventory  -- Use global inventory
    
    -- Restore player position from save or use default
    local startX, startY, startZ = 0, 0, 8
    if _G.savedPlayerPosition then
        startX = _G.savedPlayerPosition.x
        startY = _G.savedPlayerPosition.y
        startZ = _G.savedPlayerPosition.z
        _G.savedPlayerPosition = nil
    end
    player = Character.new("Hero", startX, startY, startZ)
    _G.currentPlayer = player
    
    floor_tile = dream:loadObject("assets/cube")
    gap_object = dream:loadObject("assets/cube")
    bridge_object = dream:loadObject("assets/cube")
    door_object = dream:loadObject("assets/cube")
    key_object = dream:loadObject("assets/key")
    
    -- Create 3 pressure plates in front of the gap
    pressurePlates = {
        { x = -4, z = 0, activated = false, id = 1 },
        { x = 0, z = 0, activated = false, id = 2 },
        { x = 4, z = 0, activated = false, id = 3 }
    }
    
    -- Create 3 moveable blocks scattered around the room
    blocks = {
        { x = -6, z = 6, width = 1.2, height = 1.2, depth = 1.2, exists = true },
        { x = 3, z = 5, width = 1.2, height = 1.2, depth = 1.2, exists = true },
        { x = 6, z = 3, width = 1.2, height = 1.2, depth = 1.2, exists = true }
    }
    
    -- Check if boxes are already in inventory and mark them as not existing in world
    for i = 1, #blocks do
        if inventory:hasItem("box" .. i) then
            blocks[i].exists = false
        end
    end
    
    -- Save initial block positions for respawn
    initialBlockPositions = {
        { x = -6, z = 6 },
        { x = 3, z = 5 },
        { x = 6, z = 3 }
    }
    
    -- Restore room state if loading from save
    if _G.room2State then
        local state = _G.room2State
        if state.blockStates then
            for i, blockState in ipairs(state.blockStates) do
                if blocks[i] then
                    blocks[i].x = blockState.x
                    blocks[i].z = blockState.z
                    blocks[i].exists = blockState.exists
                end
            end
        end
        if state.pressurePlates then
            for i, plateState in ipairs(state.pressurePlates) do
                if pressurePlates[i] then
                    pressurePlates[i].activated = plateState.activated
                end
            end
        end
        if state.placedBoxes then
            placedBoxes = state.placedBoxes
        end
        bridge.extended = state.bridgeExtended
        door.locked = state.doorLocked
        key.collected = state.keyCollected
        keySpawned = state.keySpawned
        _G.room2State = nil
    end
    
    -- Create visual objects for blocks
    for i = 1, #blocks do
        block_objects[i] = dream:loadObject("assets/crate")
    end
    
    -- Create visual objects for pressure plates
    for i = 1, #pressurePlates do
        plate_objects[i] = dream:loadObject("assets/cube")
    end

    sun = dream:newLight("sun", dream.vec3(10, 10, 10), dream.vec3(1, 1, 1), 1.5)
    sun:addNewShadow()
end

function room2_scene:update(dt)
    if player then
        player:update(dt)
        
        -- Capture current state for save system
        local blockStates = {}
        for i, block in ipairs(blocks) do
            table.insert(blockStates, { x = block.x, z = block.z, exists = block.exists })
        end
        local plateStates = {}
        for i, plate in ipairs(pressurePlates) do
            table.insert(plateStates, { activated = plate.activated })
        end
        _G.room2State = {
            blockStates = blockStates,
            pressurePlates = plateStates,
            placedBoxes = placedBoxes,
            bridgeExtended = bridge.extended,
            doorLocked = door.locked,
            keyCollected = key.collected,
            keySpawned = keySpawned
        }
        
        -- Death timer
        if playerDead then
            deathTimer = deathTimer + dt
            return  -- Don't update game logic while dead
        end
        
        -- Message timer
        if messageTimer > 0 then
            messageTimer = messageTimer - dt
        end
        
        -- Check if player fell into gap
        local px, pz = player:getX(), player:getZ()
        local inGapX = px >= -3 and px <= 3
        local inGapZ = pz >= -4 and pz <= -1
        
        if inGapX and inGapZ and not bridge.extended then
            -- Player fell into the gap!
            playerDead = true
            deathTimer = 0
            interactionMessage = _G.localization:get("fell_into_gap")
            messageTimer = 3
            return
        end
        
        -- Auto-pickup boxes when player gets close
        for i, block in ipairs(blocks) do
            if block.exists then
                local dx = player:getX() - block.x
                local dz = player:getZ() - block.z
                local distToBlock = math.sqrt(dx*dx + dz*dz)
                if distToBlock < 1.0 then
                    block.exists = false
                    local success = inventory:addItem("box" .. i, "Box " .. i)
                    print("Box " .. i .. " added to inventory:", success)
                    interactionMessage = "Box " .. i .. " collected!"
                    messageTimer = 2
                end
            end
        end
        
        -- Auto-pickup placed boxes when player gets close
        for i = #placedBoxes, 1, -1 do
            local placedBox = placedBoxes[i]
            local dx = player:getX() - placedBox.x
            local dz = player:getZ() - placedBox.z
            local distToBox = math.sqrt(dx*dx + dz*dz)
            if distToBox < 1.0 then
                -- Re-add the box with its original ID
                local boxId = placedBox.id
                table.remove(placedBoxes, i)
                inventory:addItem("box" .. boxId, "Box " .. boxId)
                interactionMessage = "Box " .. boxId .. " collected!"
                messageTimer = 2
            end
        end
        
        -- Check which pressure plates are activated
        for i, plate in ipairs(pressurePlates) do
            plate.activated = false
            -- Check if any placed box is on this plate
            for j, placedBox in ipairs(placedBoxes) do
                local dx = placedBox.x - plate.x
                local dz = placedBox.z - plate.z
                local dist = math.sqrt(dx*dx + dz*dz)
                if dist < 0.8 then  -- Box is close enough to activate
                    plate.activated = true
                    break
                end
            end
        end
        
        -- Check if all plates are activated to extend bridge
        local allActivated = true
        for _, plate in ipairs(pressurePlates) do
            if not plate.activated then
                allActivated = false
                break
            end
        end
        
        if allActivated and not bridge.extended then
            bridge.extended = true
            keySpawned = true
            door.locked = false
            print("Bridge extended! All pressure plates activated! Pick up the Key")
        
        end
        
        -- Key pickup
        if keySpawned and not key.collected then
          local dx = player:getX() - key.x
          local dz = player:getZ() - key.z
          if math.sqrt(dx*dx + dz*dz) < 1.2 then
            key.collected = true
            inventory:addItem("Key")   -- Or whatever your inventory uses
            interactionMessage = _G.localization:get("picked_up_key")
            messageTimer = 3
          end
        end
        -- Fixed overhead camera
        dream.camera:resetTransform()
        dream.camera:translate(0, 8, 0)
        dream.camera:rotateX(-math.pi / 2)
    end
    if bridge.extended then
      local px, pz = player:getX(), player:getZ()
      -- Define exit zone at far end of bridge
      if px >= -2 and px <= 2 and pz <= door.z + 1 and not playerDead then
        -- Transition to Room 3
        print("Player reached the exit! Loading next scene...")
        scenery.setScene("room3")-- Make sure your sceneManager has room3 loaded
      end
    end
  
    
    
    dream:update(dt)
end

function room2_scene:draw()
    dream:prepare()
    dream:addLight(sun)
    
    if player then
        player:draw()
        
        -- Draw Floor Grid (with gap in the middle)
        if floor_tile then
            for x = -6, 6 do
                for z = -6, 6 do
                    -- Skip tiles in the gap area (-3 to 3 on Z, between -1 and -4)
                    local isGap = (z >= -4 and z <= -1 and x >= -3 and x <= 3)
                    if not isGap then
                        floor_tile:resetTransform()
                        floor_tile:translate(x * 3, -1, z * 3)
                        floor_tile:scale(2, 0.1, 2)
                        dream:draw(floor_tile)
                    end
                end
            end
        end
        
        -- Draw the gap (dark void)
        if gap_object then
            local mat = dream:newMaterial()
            mat.color = {0.05, 0.05, 0.1, 1}
            mat.roughness = 0.8
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
            
            paintRecursive(gap_object, mat)
            gap_object:resetTransform()
            gap_object:translate(0, -2, -7.5)
            gap_object:scale(9, 0.1, 9)
            dream:draw(gap_object)
        end
        
        -- Draw bridge (extends when all plates activated)
        if bridge_object and bridge.extended then
            local mat = dream:newMaterial()
            mat.color = {0.6, 0.5, 0.3, 1}
            mat.roughness = 0.6
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
            
            paintRecursive(bridge_object, mat)
            bridge_object:resetTransform()
            bridge_object:translate(0, -0.8, -7.5)
            bridge_object:scale(3, 0.2, 9)
            dream:draw(bridge_object)
        end
        
        -- Draw pressure plates
        for i, plate in ipairs(pressurePlates) do
            if plate_objects[i] then
                local mat = dream:newMaterial()
                if plate.activated then
                    mat.color = {0.2, 0.8, 0.2, 1}  -- Green when activated
                else
                    mat.color = {0.5, 0.5, 0.5, 1}  -- Gray when inactive
                end
                mat.roughness = 0.4
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
                
                paintRecursive(plate_objects[i], mat)
                plate_objects[i]:resetTransform()
                plate_objects[i]:translate(plate.x, -0.9, plate.z)
                plate_objects[i]:scale(0.8, 0.1, 0.8)
                dream:draw(plate_objects[i])
            end
        end
        
        -- Draw moveable blocks (only if they exist/not picked up)
        for i, block in ipairs(blocks) do
            if block.exists and block_objects[i] then
                local mat = dream:newMaterial()
                mat.color = {0.6, 0.4, 0.2, 1}  -- Brown stone
                mat.roughness = 0.7
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
                
                paintRecursive(block_objects[i], mat)
                block_objects[i]:resetTransform()
                block_objects[i]:translate(block.x, 0.6, block.z)
                block_objects[i]:rotateX(math.pi)
                block_objects[i]:scale(block.width, block.height, block.depth)
                dream:draw(block_objects[i])
            end
        end
        
        -- Draw placed boxes from inventory
        for i, placedBox in ipairs(placedBoxes) do
            -- Use the appropriate block object based on box ID
            local objIndex = placedBox.id
            if objIndex and block_objects[objIndex] then
                local mat = dream:newMaterial()
                mat.color = {0.6, 0.4, 0.2, 1}  -- Brown stone
                mat.roughness = 0.7
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
                
                paintRecursive(block_objects[objIndex], mat)
                block_objects[objIndex]:resetTransform()
                block_objects[objIndex]:translate(placedBox.x, 0.6, placedBox.z)
                block_objects[objIndex]:rotateX(math.pi)
                block_objects[objIndex]:scale(1.2, 1.2, 1.2)
                dream:draw(block_objects[objIndex])
            end
        end
        
        -- Draw door
        if door and door_object then
            local mat = dream:newMaterial()
            if door.locked then
                mat.color = {0.35, 0.20, 0.05, 1}  -- Brown when locked
            else
                mat.color = {0.2, 1, 0.2, 1}  -- Green when unlocked
            end
            mat.roughness = 0.6
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
            door_object:scale(2, 3, 0.2)
            dream:draw(door_object)
        end
        if keySpawned and not key.collected then
          local mat = dream:newMaterial()
          mat.color = {1, 1, 0.2, 1}
          mat.roughness = 0.2
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
    key_object:translate(key.x, 0.6, key.z)
    key_object:scale(0.4, 0.4, 0.4)
    dream:draw(key_object)
end
    end
    
    dream:present()
    
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
    
    -- Draw custom cursor if hovering over block
    if isHoveringInteractive and not inventory.isOpen then
        local mx, my = love.mouse.getPosition()
        love.graphics.setColor(1, 0.8, 0, 0.8)
        love.graphics.circle("line", mx, my, 12, 20)
        love.graphics.circle("line", mx, my, 10, 20)
        love.graphics.setColor(1, 1, 1)
    end
    
    -- UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(_G.localization:get("room2_title"), 10, 10)
    
    -- Death screen
    if playerDead then
        -- Dark overlay
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
        -- Death message
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf(_G.localization:get("you_fell"), 0, love.graphics.getHeight() / 2 - 60, love.graphics.getWidth(), "center")
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(_G.localization:get("fell_died"), 0, love.graphics.getHeight() / 2 - 20, love.graphics.getWidth(), "center")
        
        -- Respawn button
        love.graphics.setColor(0.3, 0.3, 0.4, 0.9)
        love.graphics.rectangle("fill", love.graphics.getWidth() / 2 - 60, love.graphics.getHeight() / 2 + 20, 120, 40, 5, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(_G.localization:get("respawn"), love.graphics.getWidth() / 2 - 60, love.graphics.getHeight() / 2 + 30, 120, "center")
        
        return
    end
    
    -- Objective
    local activatedCount = 0
    for _, plate in ipairs(pressurePlates) do
        if plate.activated then activatedCount = activatedCount + 1 end
    end
    
    if bridge.extended then
        love.graphics.setColor(0, 1, 0)
        love.graphics.print(_G.localization:get("bridge_activated"), 10, 40)
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.print(_G.localization:get("room2_objective"), 10, 40)
        love.graphics.print(_G.localization:get("plates_activated") .. string.format("%d/3", activatedCount), 10, 60)
        love.graphics.print(_G.localization:get("drag_blocks_hint"), 10, 80)
    end
end

function room2_scene:mousepressed(mouseX, mouseY, button)
    if button == 1 then
        -- Check for respawn button if player is dead
        if playerDead then
            local buttonX = love.graphics.getWidth() / 2 - 60
            local buttonY = love.graphics.getHeight() / 2 + 20
            local buttonWidth = 120
            local buttonHeight = 40
            
            if mouseX >= buttonX and mouseX <= buttonX + buttonWidth and
               mouseY >= buttonY and mouseY <= buttonY + buttonHeight then
                -- Respawn player
                playerDead = false
                deathTimer = 0
                player = Character.new("Hero", 0, 0, 8)
                
                -- Reset blocks to initial positions and make them pickupable again
                for i, block in ipairs(blocks) do
                    block.x = initialBlockPositions[i].x
                    block.z = initialBlockPositions[i].z
                    block.exists = true
                    -- Remove from inventory if picked up
                    inventory:removeItem("box" .. i)
                end
                
                -- Clear placed boxes
                placedBoxes = {}
                
                -- Reset bridge and door
                bridge.extended = false
                door.locked = true
                
                interactionMessage = _G.localization:get("respawned")
                messageTimer = 2
            end
            return
        end
    end
    
    -- Check inventory first
    if inventory:mousepressed(mouseX, mouseY, button) then
        return
    end
    
    if button == 1 then
        -- Don't allow world interaction if inventory is open
        if inventory.isOpen then
            return
        end
        
        -- Convert mouse to world coordinates
        local width, height = love.graphics.getDimensions()
        local nx = (mouseX / width) * 2 - 1
        local nz = (mouseY / height) * 2 - 1
        local targetX = nx * 9
        local targetZ = nz * 9
        
        -- Check if clicking on a box
        for i, block in ipairs(blocks) do
            if block.exists then
                local hitboxOffsetZ = 0
                local dist = math.sqrt((targetX - block.x)^2 + (targetZ - (block.z + hitboxOffsetZ))^2)
                if dist < 0.8 then
                    -- Walk to the box
                    player:walkTo(block.x, block.z)
                    return
                end
            end
        end
        
        -- Check if clicking on a placed box
        for i, placedBox in ipairs(placedBoxes) do
            local hitboxOffsetZ = 0
            local dist = math.sqrt((targetX - placedBox.x)^2 + (targetZ - (placedBox.z + hitboxOffsetZ))^2)
            if dist < 0.8 then
                -- Walk to the placed box
                player:walkTo(placedBox.x, placedBox.z)
                return
            end
        end
        
        -- Otherwise, move player
        if player and not player.isMoving then
            player:walkTo(targetX, targetZ)
        end
    end
end

function room2_scene:mousemoved(mouseX, mouseY)
    local width, height = love.graphics.getDimensions()
    mouseWorldX = (mouseX / width) * 2 - 1
    mouseWorldX = mouseWorldX * 18
    mouseWorldZ = (mouseY / height) * 2 - 1
    mouseWorldZ = mouseWorldZ * 18
    
    -- Check if hovering over any box
    isHoveringInteractive = false
    if player and not inventory.isOpen then
        local width, height = love.graphics.getDimensions()
        local nx = (mouseX / width) * 2 - 1
        local nz = (mouseY / height) * 2 - 1
        local targetX = nx * 9
        local targetZ = nz * 9
        
        for i, block in ipairs(blocks) do
            if block.exists then
                local blockDist = math.sqrt((targetX - block.x)^2 + (targetZ - block.z)^2)
                if blockDist < 0.8 then
                    isHoveringInteractive = true
                    break
                end
            end
        end
        
        -- Check placed boxes too
        if not isHoveringInteractive then
            for i, placedBox in ipairs(placedBoxes) do
                local blockDist = math.sqrt((targetX - placedBox.x)^2 + (targetZ - placedBox.z)^2)
                if blockDist < 0.8 then
                    isHoveringInteractive = true
                    break
                end
            end
        end
    end
end

function room2_scene:mousereleased(mouseX, mouseY, button)
    -- Check if dragging item from inventory
    local droppedItem = inventory:mousereleased(mouseX, mouseY, button)
    
    if droppedItem then
        -- Convert mouse to world coordinates
        local width, height = love.graphics.getDimensions()
        local nx = (mouseX / width) * 2 - 1
        local nz = (mouseY / height) * 2 - 1
        local dropX = nx * 9
        local dropZ = nz * 9
        
        -- Example interaction logic - you can add items and interactions here
        interactionMessage = "That item doesn't work here."
        messageTimer = 2
    end
end

function room2_scene:keypressed(key)
    return inventory:keypressed(key)
end

return room2_scene
