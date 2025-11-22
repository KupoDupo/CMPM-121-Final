--local eyeball = {}

--function eyeball.new(x, z)
--    local self = {}
--    self.x = x
--    self.z = z
--    self.exists = true 

--    -- 1. Load the Eyeball Model
--    local status, object = pcall(dream.loadObject, dream, "assets/eyeball.dae")
    
--    -- Fallback if file is missing
--    if not status or not object then
--        print("ERROR: 'assets/eyeball.dae' not found! Using Cube.")
--        local vertices = {
--            {-0.2,0,0}, {0.2,0,0}, {0,0.5,0} -- Tiny Triangle
--        }
--        object = dream:newObject(dream:newMesh("eye_fallback", vertices, nil, "simple"))
        
--        -- Make fallback BRIGHT PURPLE so you know it failed
--        local mat = dream:newMaterial()
--        mat.color = {1, 0, 1, 1} 
--        mat.emission = {1, 0, 1}
--        object.material = mat
--    else
--        -- [[ 2. FORCE VISIBILITY ]]
--        -- If loaded, we paint it Bright White so shadows don't hide it.
--        local mat = dream:newMaterial()
--        mat.color = {1, 1, 1, 1} -- White
--        mat.roughness = 0.1      -- Wet/Shiny
--        mat.cullMode = "none"    -- Draw both sides (Fixes inside-out models)
--    end

--    self.object = object

--    -- 2. Material Settings (Wet/Shiny)
--    local mat = dream:newMaterial()
--    mat.roughness = 0.05 -- Very Wet
--    mat.color = {1, 1, 1, 1}
--    mat.cullMode = "none"
    
--    -- Force material onto every part of the eyeball model
--    if self.object.meshes then
--        for _, mesh in pairs(self.object.meshes) do
--            mesh.material = mat
--        end
--    end
--    self.object.material = mat

--    -- 3. Draw Function
--    function self:draw()
--        if not self.exists then return end
        
--        self.object:resetTransform()
--        -- Float 0.5 units above ground
--        self.object:translate(self.x, 0.5, self.z)
        
--        -- Scale down (DAE models are often huge)
--        self.object:scale(10)
        
--        -- Spin Animation
--        self.object:rotateY(love.timer.getTime())
        
--        dream:draw(self.object)
--    end

--    return self
--end

--return eyeball

local eyeball = {}

function eyeball.new(x, z)
    local self = {}
    self.x = x
    self.z = z
    self.exists = true 

    -- 1. Load the Eyeball Model
    -- We try to load "assets/eyeball.dae"
    -- We use pcall so the game doesn't crash if the file is missing
    local status, object = pcall(dream.loadObject, dream, "assets/eyeball")
    
    -- Fallback if file is missing or fails to load
    if not status or not object then
        print("ERROR: Eyeball model not found! Using Cube.")
        local vertices = {
            {-0.2,0,0}, {0.2,0,0}, {0,0.5,0}, -- Front
            {-0.2,0,-0.2}, {0.2,0,-0.2}, {0,0.5,-0.2} -- Back
        }
        object = dream:newObject(dream:newMesh("eye_fallback", vertices, nil, "simple"))
    end
    
    local tex_status, texture = pcall(love.graphics.newImage, "assets/textures/Eye_D.jpg")
    
    if tex_status and texture then
        print("Texture Loaded Successfully!")
    else
        print("ERROR: Could not load texture 'assets/textures/Eye_D.jpg'")
        texture = nil -- Keep going without texture if missing
    end

    self.object = object

    -- 2. Force Visibility (Bright White Material)
    local mat = dream:newMaterial()
    mat.color = {1, 1, 1, 1} -- White
    mat.roughness = 0.1      -- Shiny
    mat.cullMode = "none"    -- Draw both sides
    
    -- Apply to all parts recursively
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
        if texture then
          mat.albedoTexture = texture
        end
    end
    
    paintRecursive(self.object, mat)

    -- 3. Draw Function
    function self:draw()
        if not self.exists then return end
        
        self.object:resetTransform()
        self.object:translate(self.x, 1.0, self.z)
        
        -- Scale: 0.5 is a safe starting point
        self.object:scale(0.5) 
        
        -- Spin Animation
        self.object:rotateY(love.timer.getTime())
        
        dream:draw(self.object)

        -- DEBUG BOX (Standard Love2D Drawing)
        -- Draws a green box on screen where the eye SHOULD be.
        -- If this box appears but is empty, the model is invisible.
        if dream.camera.worldToScreen then
             local sx, sy = dream.camera:worldToScreen(self.x, 1.0, self.z)
             if sx then
                 love.graphics.setColor(0, 1, 0)
                 love.graphics.rectangle("line", sx - 10, sy - 10, 20, 20)
             end
        end
    end

    return self
end

return eyeball