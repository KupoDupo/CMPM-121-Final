local cannonball = {}

function cannonball.new(x, z)
    local self = {}
    self.x = x
    self.z = z
    self.exists = true

    -- 1. Load Model
    -- Try to load a cannon-ball model (use 'assets/cannon-ball')
    local status, object = pcall(dream.loadObject, dream, "assets/cannon-ball")

    if not status or not object then
        print("NOTICE: cannon-ball model not found. Using fallback mesh.")
        local vertices = {{-0.2,0,0}, {0.2,0,0}, {0,0.5,0}, {-0.2,0,-0.2}, {0.2,0,-0.2}, {0,0.5,-0.2}}
        object = dream:newObject(dream:newMesh("cannonball_fallback", vertices, nil, "simple"))
    end

    self.object = object

    -- 2. Load project colormap (if present) and apply as material
    local img_status, colormap = pcall(love.graphics.newImage, "assets/colormap.png")
    if not img_status then colormap = nil end

    local mat = dream:newMaterial()
    mat.color = {1, 1, 1, 1}
    mat.roughness = 0.2
    mat.metallic = 0.1
    mat.cullMode = "none"
    if colormap then mat.albedoTexture = colormap end

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

    -- Draw Function
    function self:draw()
        if not self.exists then return end

        self.object:resetTransform()
        self.object:translate(self.x, 1.0, self.z)
        -- Match scale with projectile cannonball
        self.object:scale(0.8)
        dream:draw(self.object)
    end

    function self:getX() return self.x end
    function self:getZ() return self.z end
    function self:getObject() return self.object end

    return self
end

return cannonball