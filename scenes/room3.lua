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
-- One key is carried over from Room 2 (inventory item name: "Key").
-- The second key is local to Room 3 and will be added to inventory as "Key_room3".
local key_local = { x = 2, z = 2, collected = false }

door = { x = 0, z = -6, locked = true, disappeared = false }

function room3_scene:load()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
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
        _G.room3State = nil
    end
end

function room3_scene:update(dt)
    if player then
        player:update(dt)
        
        -- Capture current state for save system
        _G.room3State = {
            keyCollected = key_local.collected,
            doorUnlocked = door.disappeared
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

        -- Unlock door only when player has the key from Room 2 ("Key")
        -- and the local Room 3 key ("Key_room3").
        if inventory:hasItem("Key") and inventory:hasItem("Key_room3") then
            door.locked = false
            door.disappeared = true
        end

        -- Exit through the door
        local px, pz = player:getX(), player:getZ()
        if door.disappeared and px >= door.x - 1 and px <= door.x + 1 and pz <= door.z + 1 then
            print("Player reached the exit! Loading ending scene...")
            scenery.setScene("ending")
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

    -- Draw interaction messages
    if messageTimer>0 then
        love.graphics.setColor(0.2,0.8,0.2,math.min(1,messageTimer))
        love.graphics.rectangle("fill", love.graphics.getWidth()/2-150,60,300,40,5,5)
        love.graphics.setColor(1,1,1,math.min(1,messageTimer))
        love.graphics.printf(interactionMessage, love.graphics.getWidth()/2-145,72,290,"center")
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
        -- Close inventory after any interaction attempt
        inventory:close()
    end
end

function room3_scene:keypressed(key)
    return inventory:keypressed(key)
end

return room3_scene
