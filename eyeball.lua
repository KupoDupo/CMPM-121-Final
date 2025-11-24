local eyeball = {}

function eyeball.new(x, z)
    local self = {}
    self.x = x
    self.z = z
    self.exists = true 

    -- 1. Load Model
    -- Tries to load "assets/eyeball" (which finds the .dae file)
    local status, object = pcall(dream.loadObject, dream, "assets/eyeball")
    
    if not status or not object then
        print("ERROR: Eyeball Model Failed. Using Cube.")
        local vertices = {{-0.2,0,0}, {0.2,0,0}, {0,0.5,0}, {-0.2,0,-0.2}, {0.2,0,-0.2}, {0,0.5,-0.2}}
        object = dream:newObject(dream:newMesh("eye_fallback", vertices, nil, "simple"))
    end

    self.object = object

    -- 2. Load Textures (Color AND Normal Map)
    -- We use pcall to avoid crashing if a file is missing
    local c_status, colorTex = pcall(love.graphics.newImage, "assets/textures/Eye_D.jpg")
    local n_status, normalTex = pcall(love.graphics.newImage, "assets/textures/Eye_N.jpg")

    if not c_status then colorTex = nil print("Missing Eye_D.jpg") end
    if not n_status then normalTex = nil print("Missing Eye_N.jpg") end

    -- 3. Realistic Material Settings
    local mat = dream:newMaterial()
    mat.color = {1, 1, 1, 1}  -- White base (so texture colors are accurate)
    mat.roughness = 0.05      -- Very Wet/Shiny
    mat.metallic = 0.0        -- Organic, not metal
    mat.specular = 1.0        -- Strong reflection
    mat.cullMode = "none"     -- Draw both sides (fixes invisible angles)
    
    -- Assign Textures
    if colorTex then mat.albedoTexture = colorTex end
    if normalTex then mat.normalTexture = normalTex end 
    
    -- 4. Force Material onto every part of the model
    -- This override is required because DAE files have their own internal materials
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
    
    paintRecursive(self.object, mat)

    -- 5. Draw Function
    function self:draw()
        if not self.exists then return end
        
        self.object:resetTransform()
        self.object:translate(self.x, 1.0, self.z)
        
        -- Scale: 0.5 (Adjust if eye is too big/small)
        self.object:scale(0.5)
        
        -- Spin Animation
        self.object:rotateY(love.timer.getTime())
        
        dream:draw(self.object)
    end
    
    function self:getX() return x end
    function self:getZ() return z end
    function self:getObject() return object end

    return self
end

return eyeball