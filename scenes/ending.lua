local Character = require("character")

local ending_scene = {}
local player
local sun
local floor_tile
local victory_object
local inventory
local messageTimer = 0
local fadeIn = 0
local particles = {}
local numParticles = 100
local playerRotation = 0

function ending_scene:load()
    love.graphics.setBackgroundColor(0.05, 0.05, 0.15)
    
    inventory = globalInventory  -- Use global inventory
    player = Character.new("Hero", 0, 0, 0)
    
    floor_tile = dream:loadObject("assets/cube")
    victory_object = dream:loadObject("assets/cube")
    
    sun = dream:newLight("sun", dream.vec3(10, 10, 10), dream.vec3(1, 1, 1), 2.0)
    sun:addNewShadow()
    
    messageTimer = 5
    fadeIn = 0
    
    -- Create celebratory particles
    for i = 1, numParticles do
        table.insert(particles, {
            x = math.random(-8, 8),
            y = math.random(-2, 8),
            z = math.random(-8, 8),
            vx = math.random(-1, 1) * 0.5,
            vy = math.random(1, 3),
            vz = math.random(-1, 1) * 0.5,
            size = math.random(2, 5) / 10,
            color = {math.random(), math.random(), math.random()}
        })
    end
end

function ending_scene:update(dt)
    if player then
        -- Keep player at center
        player.x = 0
        player.z = 0
        player.y = 0
        
        -- Rotate player faster
        playerRotation = playerRotation + dt * 10  -- 10 radians per second
        
        -- Fade in effect
        if fadeIn < 1 then
            fadeIn = fadeIn + dt * 0.5
        end
        
        if messageTimer > 0 then
            messageTimer = messageTimer - dt
        end
        
        -- Update particles
        for _, p in ipairs(particles) do
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.z = p.z + p.vz * dt
            
            -- Reset particles that go too high
            if p.y > 10 then
                p.y = -2
                p.x = math.random(-8, 8)
                p.z = math.random(-8, 8)
            end
        end
        
        -- Fixed overhead camera
        dream.camera:resetTransform()
        dream.camera:translate(0, 8, 0)
        dream.camera:rotateX(-math.pi / 2)
    end
    
    dream:update(dt)
end

function ending_scene:draw()
    dream:prepare()
    dream:addLight(sun)
    
    if player then
        -- Get player's model and draw with rotation
        local playerModel = player:getObject()
        
        if playerModel then
            playerModel:resetTransform()
            playerModel:translate(0, 0, 0)  -- Center position
            playerModel:rotateX(math.pi)  -- Flip horizontally (upside down)
            playerModel:rotateY(playerRotation)  -- Apply rotation around vertical axis
            playerModel:scale(0.5)
            dream:draw(playerModel)
        end
        
        -- Draw floor with special victory color
        if floor_tile then
            local mat = dream:newMaterial()
            mat.color = {0.2, 0.3, 0.5, 1}
            mat.roughness = 0.5
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
            
            for x = -6, 6 do
                for z = -6, 6 do
                    paintRecursive(floor_tile, mat)
                    floor_tile:resetTransform()
                    floor_tile:translate(x * 3, -1, z * 3)
                    floor_tile:scale(2, 0.1, 2)
                    dream:draw(floor_tile)
                end
            end
        end
        
        -- Draw victory monument/pedestal
        if victory_object then
            local mat = dream:newMaterial()
            -- Animated glowing effect
            local glow = math.sin(love.timer.getTime() * 2) * 0.3 + 0.7
            mat.color = {glow, glow * 0.8, 0.2, 1}
            mat.roughness = 0.2
            mat.metallic = 0.5
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
            
            paintRecursive(victory_object, mat)
            victory_object:resetTransform()
            victory_object:translate(0, 1, 0)
            victory_object:rotateY(love.timer.getTime())
            victory_object:scale(1.5, 2.5, 1.5)
            dream:draw(victory_object)
        end
        
        -- Draw floating particles (confetti)
        if #particles > 0 then
            for _, p in ipairs(particles) do
                local confettiCube = dream:loadObject("assets/cube")
                local mat = dream:newMaterial()
                mat.color = {p.color[1], p.color[2], p.color[3], 1}
                mat.roughness = 0.1
                mat.metallic = 0.3
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
                
                paintRecursive(confettiCube, mat)
                confettiCube:resetTransform()
                confettiCube:translate(p.x, p.y, p.z)
                confettiCube:scale(p.size, p.size, p.size)
                dream:draw(confettiCube)
            end
        end
    end
    
    dream:present()
    
    -- Draw inventory
    local mx, my = love.mouse.getPosition()
    inventory:draw(mx, my)
    
    -- Draw victory UI with fade in
    love.graphics.setColor(1, 1, 1, fadeIn)
    
    -- Title
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    love.graphics.setColor(0, 0, 0, fadeIn * 0.5)
    love.graphics.rectangle("fill", 0, height / 2 - 100, width, 200)
    
    -- Victory message
    love.graphics.setColor(1, 1, 0.5, fadeIn)
    love.graphics.printf(_G.localization:get("victory_message"), 0, height / 2 - 60, width, "center")
    
    love.graphics.setColor(0.7, 0.9, 1, fadeIn)
    love.graphics.printf(_G.localization:get("you_escaped"), 0, height / 2 - 20, width, "center")
    
    -- Credits
    love.graphics.setColor(0.6, 0.6, 0.6, fadeIn * 0.7)
    love.graphics.printf(_G.localization:get("thanks_playing"), 0, height / 2 + 40, width, "center")
    
    -- Exit prompt
    if fadeIn >= 1 then
        local pulse = math.sin(love.timer.getTime() * 3) * 0.3 + 0.7
        love.graphics.setColor(1, 1, 1, pulse)
        love.graphics.printf(_G.localization:get("press_esc_exit"), 0, height - 60, width, "center")
    end
    
    love.graphics.setColor(1, 1, 1)
end

function ending_scene:mousepressed(mouseX, mouseY, button)
    if inventory:mousepressed(mouseX, mouseY, button) then
        return
    end
    
    -- Player cannot move on ending screen
    -- Movement disabled
end

function ending_scene:mousemoved(mouseX, mouseY)
    -- Not needed for ending scene, but included for consistency
end

function ending_scene:mousereleased(mouseX, mouseY, button)
    inventory:mousereleased(mouseX, mouseY, button)
end

function ending_scene:keypressed(key)
    -- Check for restart or return to menu
    if key == "escape" then
        -- Reset global inventory
        globalInventory:clear()
        -- Return to menu
        scenery.setScene("menu")
        return true
    end
    
    return inventory:keypressed(key)
end

return ending_scene
