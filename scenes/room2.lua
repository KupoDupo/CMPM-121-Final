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
        { x = -6, z = 6, width = 1.2, height = 1.2, depth = 1.2, beingDragged = false },
        { x = 3, z = 5, width = 1.2, height = 1.2, depth = 1.2, beingDragged = false },
        { x = 6, z = 3, width = 1.2, height = 1.2, depth = 1.2, beingDragged = false }
    }
    
    -- Save initial block positions for respawn
    initialBlockPositions = {
        { x = -6, z = 6 },
        { x = 3, z = 5 },
        { x = 6, z = 3 }
    }
    
    -- Restore room state if loading from save
    if _G.room2State then
        local state = _G.room2State
        if state.blockPositions then
            for i, pos in ipairs(state.blockPositions) do
                if blocks[i] then
                    blocks[i].x = pos.x
                    blocks[i].z = pos.z
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
        local blockPositions = {}
        for i, block in ipairs(blocks) do
            table.insert(blockPositions, { x = block.x, z = block.z })
        end
        local plateStates = {}
        for i, plate in ipairs(pressurePlates) do
            table.insert(plateStates, { activated = plate.activated })
        end
        _G.room2State = {
            blockPositions = blockPositions,
            pressurePlates = plateStates,
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
            interactionMessage = "You fell into the gap!"
            messageTimer = 3
            return
        end
        
        -- Move selected block with mouse
        if selectedBlock then
            blocks[selectedBlock].x = mouseWorldX
            blocks[selectedBlock].z = mouseWorldZ
            
            -- Clamp block position to world bounds
            blocks[selectedBlock].x = math.max(worldBounds.minX, math.min(worldBounds.maxX, blocks[selectedBlock].x))
            blocks[selectedBlock].z = math.max(worldBounds.minZ, math.min(worldBounds.maxZ, blocks[selectedBlock].z))
        end
        
        -- Check which pressure plates are activated
        for i, plate in ipairs(pressurePlates) do
            plate.activated = false
            -- Check if any block is on this plate
            for j, block in ipairs(blocks) do
                local dx = block.x - plate.x
                local dz = block.z - plate.z
                local dist = math.sqrt(dx*dx + dz*dz)
                if dist < 0.8 then  -- Block is close enough to activate
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
            interactionMessage = "You picked up a key!"
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
        
        -- Draw moveable blocks
        for i, block in ipairs(blocks) do
            if block_objects[i] then
                local mat = dream:newMaterial()
                if selectedBlock == i then
                    mat.color = {0.9, 0.7, 0.3, 1}  -- Highlight selected block
                else
                    mat.color = {0.6, 0.4, 0.2, 1}  -- Brown stone
                end
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
    love.graphics.print("Room 2: Pressure Plate Bridge", 10, 10)
    
    -- Death screen
    if playerDead then
        -- Dark overlay
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
        -- Death message
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf("YOU FELL!", 0, love.graphics.getHeight() / 2 - 60, love.graphics.getWidth(), "center")
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("You fell into the gap and died.", 0, love.graphics.getHeight() / 2 - 20, love.graphics.getWidth(), "center")
        
        -- Respawn button
        love.graphics.setColor(0.3, 0.3, 0.4, 0.9)
        love.graphics.rectangle("fill", love.graphics.getWidth() / 2 - 60, love.graphics.getHeight() / 2 + 20, 120, 40, 5, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("RESPAWN", love.graphics.getWidth() / 2 - 60, love.graphics.getHeight() / 2 + 30, 120, "center")
        
        return
    end
    
    -- Objective
    local activatedCount = 0
    for _, plate in ipairs(pressurePlates) do
        if plate.activated then activatedCount = activatedCount + 1 end
    end
    
    if bridge.extended then
        love.graphics.setColor(0, 1, 0)
        love.graphics.print("Bridge activated! Cross to the exit!", 10, 40)
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.print("Objective: Place blocks on all pressure plates", 10, 40)
        love.graphics.print(string.format("Plates activated: %d/3", activatedCount), 10, 60)
        love.graphics.print("Drag blocks by clicking and holding", 10, 80)
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
                selectedBlock = nil
                
                -- Reset blocks to initial positions
                for i, block in ipairs(blocks) do
                    block.x = initialBlockPositions[i].x
                    block.z = initialBlockPositions[i].z
                end
                
                -- Reset bridge and door
                bridge.extended = false
                door.locked = true
                
                interactionMessage = "Respawned! Be careful not to fall."
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
        
        if not selectedBlock then
            -- Try to select a block
            for i, block in ipairs(blocks) do
                local dx = player:getX() - block.x
                local dz = player:getZ() - block.z
                local dist = math.sqrt(dx*dx + dz*dz)
                
                -- Can only grab blocks within range
                if dist < 2.0 then
                    selectedBlock = i
                    return
                end
            end
            
            -- No block selected, move player
            if player and not player.isMoving then
                local width, height = love.graphics.getDimensions()
                local nx = (mouseX / width) * 2 - 1
                local nz = (mouseY / height) * 2 - 1
                local targetX = nx * 9
                local targetZ = nz * 9
                player:walkTo(targetX, targetZ)
            end
        else
            -- Release the selected block
            selectedBlock = nil
        end
    end
end

function room2_scene:mousemoved(mouseX, mouseY)
    local width, height = love.graphics.getDimensions()
    mouseWorldX = (mouseX / width) * 2 - 1
    mouseWorldX = mouseWorldX * 18
    mouseWorldZ = (mouseY / height) * 2 - 1
    mouseWorldZ = mouseWorldZ * 18
    
    -- Check if hovering over any block
    isHoveringInteractive = false
    if player then
        for i, block in ipairs(blocks) do
            local dx = player:getX() - block.x
            local dz = player:getZ() - block.z
            local dist = math.sqrt(dx*dx + dz*dz)
            
            -- Check distance to block (with Z-offset compensation)
            local blockDx = mouseWorldX - block.x
            local blockDz = mouseWorldZ - block.z
            local blockDist = math.sqrt(blockDx*blockDx + blockDz*blockDz)
            
            if dist < 2.0 and blockDist < 1.0 then
                isHoveringInteractive = true
                break
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
