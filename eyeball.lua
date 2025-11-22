local eyeball = {}

function eyeball.new(x, z)
    local self = {}
    self.x = x
    self.z = z
    self.exists = true 

    -- 1. Load the Eyeball Model
    -- We use 'dae/eyeball' because that is the folder name in your zip file.
    -- We use 'dream.loadObject' (DOT) because we are passing it to pcall.
    local status, object = pcall(dream.loadObject, dream, "assets/eyeball.dae")
    
    -- Fallback if file is missing
    if not status or not object then
        print("Eyeball not found! Using placeholder.")
        local vertices = {{-0.2,0,0}, {0.2,0,0}, {0,0.5,0}}
        object = dream:newObject(dream:newMesh("eye_fallback", vertices, nil, "simple"))
    end

    self.object = object

    -- 2. Material Settings (Wet/Shiny)
    local mat = dream:newMaterial()
    mat.roughness = 0.05 -- Very Wet
    mat.color = {1, 1, 1, 1}
    
    -- Force material onto every part of the eyeball model
    if self.object.meshes then
        for _, mesh in pairs(self.object.meshes) do
            mesh.material = mat
        end
    end
    self.object.material = mat

    -- 3. Draw Function
    function self:draw()
        if not self.exists then return end
        
        self.object:resetTransform()
        -- Float 0.5 units above ground
        self.object:translate(self.x, 0.5, self.z)
        
        -- Scale down (DAE models are often huge)
        self.object:scale(0.3)
        
        -- Spin Animation
        self.object:rotateY(love.timer.getTime())
        
        dream:draw(self.object)
    end

    return self
end

return eyeball