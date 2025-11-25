local cannon = {}

function cannon.new(x, z)
    local self = {}
    x = x or 0
    z = z or 0
    self.x = x
    self.z = z
    self.yaw = 0

    -- Try to load a cannon model (OBJ + MTL present); fallback to a cube-like object
    local status, object = pcall(dream.loadObject, dream, "assets/cannon-mobile")
    if not status or not object then
        local vertices = {{-0.3,0,0}, {0.3,0,0}, {0,0.6,0}, {-0.3,0,-0.3}, {0.3,0,-0.3}, {0,0.6,-0.3}}
        object = dream:newObject(dream:newMesh("cannon_fallback", vertices, nil, "simple"))
    end

    self.object = object

    -- Ensure the model has a usable material and texture (MTL may reference a different path)
    local img_status, colormap = pcall(love.graphics.newImage, "assets/colormap.png")
    if not img_status then colormap = nil end

    local mat = dream:newMaterial()
    mat.color = {1, 1, 1, 1}
    mat.roughness = 0.6
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

    -- Small mesh used for projectiles
    local p_vertices = {{-0.08,0,0},{0.08,0,0},{0,0.16,0},{-0.08,0,-0.08},{0.08,0,-0.08},{0,0.16,-0.08}}
    local projMesh = dream:newObject(dream:newMesh("proj_fallback", p_vertices, nil, "simple"))

    local projectiles = {}

    function self:aimAt(tx, tz)
        local dx = tx - x
        local dz = tz - z
        self.yaw = math.atan2(dx, dz)
    end

    function self:shoot(tx, tz)
        local dx = tx - x
        local dz = tz - z
        local dist = math.sqrt(dx*dx + dz*dz)
        if dist == 0 then return end
        local speed = 18
        local vx = (dx / dist) * speed
        local vz = (dz / dist) * speed
        table.insert(projectiles, {x = x, z = z, vx = vx, vz = vz, alive = true})
    end

    function self:update(dt, door)
        -- update projectiles
        for i = #projectiles, 1, -1 do
            local p = projectiles[i]
            if not p.alive then
                table.remove(projectiles, i)
            else
                p.x = p.x + p.vx * dt
                p.z = p.z + p.vz * dt

                -- simple lifetime cut-off
                if math.abs(p.x - x) > 100 or math.abs(p.z - z) > 100 then
                    p.alive = false
                end

                -- check collision with door
                if door and door.locked then
                    local ddx = p.x - (door.x or 0)
                    local ddz = p.z - (door.z or 0)
                    local d = math.sqrt(ddx*ddx + ddz*ddz)
                    if d < 1.0 then
                        door.locked = false
                        p.alive = false
                        print("Door unlocked!")
                    end
                end
            end
        end
    end

    function self:draw()
        -- draw cannon
        self.object:resetTransform()
        self.object:translate(x, 0, z)
        self.object:rotateY(self.yaw or 0)
        self.object:scale(0.6)
        dream:draw(self.object)

        -- draw projectiles
        for _, p in ipairs(projectiles) do
            projMesh:resetTransform()
            projMesh:translate(p.x, 0.4, p.z)
            projMesh:scale(0.2)
            dream:draw(projMesh)
        end
    end

    return self
end

return cannon
