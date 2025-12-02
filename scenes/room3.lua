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
door = { x = 0, z = -6, locked = true }
local key2 = { x = 2, z = 2, collected = false }
local keySpawned = true

function room3_scene:load()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)

    inventory = Inventory.new()
    player = Character.new("Hero", 0, 0, 0)

    floor_tile = dream:loadObject("assets/cube")
    door_object = dream:loadObject("assets/cube")
    wall_left = dream:loadObject("assets/cube")
    wall_right = dream:loadObject("assets/cube")

    sun = dream:newLight("sun", dream.vec3(10, 10, 10), dream.vec3(1, 1, 1), 1.5)
    sun:addNewShadow()
end

function room3_scene:update(dt)
    if player then
        player:update(dt)

        -- Message timer
        if messageTimer > 0 then
            messageTimer = messageTimer - dt
        end

        -- Key 2 pickup
        if keySpawned and not key2.collected then
            local dx = player:getX() - key2.x
            local dz = player:getZ() - key2.z
            if math.sqrt(dx*dx + dz*dz) < 1.2 then
                key2.collected = true
                inventory:addItem("Key2")
                interactionMessage = "You picked up the second key!"
                messageTimer = 3
            end
        end

        -- Unlock door if both keys are collected
        if inventory:hasItem("Key") and inventory:hasItem("Key2") then
            door.locked = false
        end

        -- Exit zone check
        local px, pz = player:getX(), player:getZ()
        if not door.locked and px >= -2 and px <= 2 and pz <= door.z + 1 then
            print("Player reached the final exit! Loading ending scene...")
            scenery.setScene("ending") -- Replace with your ending scene
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
    if wall_left and wall_right and door then
        local wall_mat = dream:newMaterial()
        wall_mat.color = {0.55, 0.37, 0.17, 1}
        wall_mat.roughness = 0.6
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

        -- Left wall
        paintRecursive(wall_left, wall_mat)
        wall_left:resetTransform()
        local leftWallX = -15
        local leftWallWidth = math.abs(leftWallX - (door.x - 1.0))
        wall_left:translate(leftWallX + leftWallWidth/2, 1.5, door.z)
        wall_left:scale(leftWallWidth, 3.0, 0.2)
        dream:draw(wall_left)

        -- Right wall
        paintRecursive(wall_right, wall_mat)
        wall_right:resetTransform()
        local rightWallX = 15
        local rightWallWidth = math.abs(rightWallX - (door.x + 1.0))
        wall_right:translate(door.x + 1.0 + rightWallWidth/2, 1.5, door.z)
        wall_right:scale(rightWallWidth, 3.0, 0.2)
        dream:draw(wall_right)
    end

    -- Draw door
    if door and door_object then
        local mat = dream:newMaterial()
        if door.locked then
            mat.color = {0.35, 0.20, 0.05, 1}
        else
            mat.color = {0.2, 1, 0.2, 1}
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

    -- Draw second key
    if keySpawned and not key2.collected then
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

        paintRecursive(door_object, mat)
        door_object:resetTransform()
        door_object:translate(key2.x, 0.6, key2.z)
        door_object:scale(0.4, 0.4, 0.4)
        dream:draw(door_object)
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

        love.graphics.setColor(1, 1, 1)
    if door.locked then
        love.graphics.print("Objective: Collect both keys to unlock the final door", 10, 40)
    else
        love.graphics.setColor(0, 1, 0)
        love.graphics.print("Final door unlocked! Step through to finish!", 10, 40)
        love.graphics.setColor(1, 1, 1)
    end
end

function room3_scene:mousepressed(mouseX, mouseY, button)
    -- Check inventory first
    if inventory:mousepressed(mouseX, mouseY, button) then
        return
    end
    if button == 1 and player then
        -- Don't allow world interaction if inventory is open
        if inventory.isOpen then
            return
        end

        -- Convert click to world coordinates
        local width, height = love.graphics.getDimensions()
        local nx = (mouseX / width) * 2 - 1
        local nz = (mouseY / height) * 2 - 1
        local targetX = nx * 9
        local targetZ = nz * 9

        -- Clamp to world bounds
        if targetX < worldBounds.minX then targetX = worldBounds.minX end
        if targetX > worldBounds.maxX then targetX = worldBounds.maxX end
        if targetZ < worldBounds.minZ then targetZ = worldBounds.minZ end
        if targetZ > worldBounds.maxZ then targetZ = worldBounds.maxZ end

        player:walkTo(targetX, targetZ)
    end
end

function room3_scene:mousemoved(mouseX, mouseY)
    local width, height = love.graphics.getDimensions()
    local nx = (mouseX / width) * 2 - 1
    local nz = (mouseY / height) * 2 - 1
    mouseWorldX = nx * 9
    mouseWorldZ = nz * 9
end

function room3_scene:mousereleased(mouseX, mouseY, button)
    inventory:mousereleased(mouseX, mouseY, button)
end

function room3_scene:keypressed(key)
    return inventory:keypressed(key)
end

return room3_scene
