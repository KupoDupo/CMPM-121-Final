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

    -- Load cannonball model for projectiles
    local projStatus, projMesh = pcall(dream.loadObject, dream, "assets/cannon-ball")
    if not projStatus or not projMesh then
        -- Fallback mesh if cannonball model doesn't load
        local p_vertices = {{-0.08,0,0},{0.08,0,0},{0,0.16,0},{-0.08,0,-0.08},{0.08,0,-0.08},{0,0.16,-0.08}}
        projMesh = dream:newObject(dream:newMesh("proj_fallback", p_vertices, nil, "simple"))
    else
        -- Apply same material/texture to projectile
        paintRecursive(projMesh, mat)
    end

    local projectiles = {}

    function self:aimAt(tx, tz)
        local dx = tx - x
        local dz = tz - z
        self.yaw = -math.atan2(dx, dz)
    end

    function self:shoot(tx, tz)
        local dx = tx - x
        local dz = tz - z
        local dist = math.sqrt(dx*dx + dz*dz)
        if dist == 0 then return end
        local speed = 18
        local vx = (dx / dist) * speed
        local vz = (dz / dist) * speed
        
        -- Spawn projectile at the barrel end (front of cannon)
        -- Since the front is the bottom end when model is at 0 rotation,
        -- and rotateY rotates around Y axis, calculate offset based on yaw
        local barrelLength = 0.8 -- distance from center to barrel tip
        local spawnX = x - math.sin(self.yaw) * barrelLength
        local spawnZ = z - math.cos(self.yaw) * barrelLength
        
        table.insert(projectiles, {x = spawnX, z = spawnZ, vx = vx, vz = vz, alive = true, bounces = 0})
    end

    function self:update(dt, door, walls, worldBounds)
        local stoppedProjectiles = {}
        
        -- update projectiles
        for i = #projectiles, 1, -1 do
            local p = projectiles[i]
            if not p.alive then
                table.remove(projectiles, i)
            else
                p.x = p.x + p.vx * dt
                p.z = p.z + p.vz * dt

                -- Apply friction to slow down projectiles
                p.vx = p.vx * 0.995
                p.vz = p.vz * 0.995
                
                -- Check if projectile has stopped moving
                local speed = math.sqrt(p.vx * p.vx + p.vz * p.vz)
                if speed < 0.1 and p.bounces > 0 then
                    -- Projectile has stopped, convert to pickup
                    table.insert(stoppedProjectiles, {x = p.x, z = p.z})
                    p.alive = false
                end

                -- Bounce off world boundaries
                if worldBounds then
                    if p.x < worldBounds.minX then
                        p.x = worldBounds.minX
                        p.vx = -p.vx * 0.8 -- reverse and dampen
                        p.bounces = p.bounces + 1
                    elseif p.x > worldBounds.maxX then
                        p.x = worldBounds.maxX
                        p.vx = -p.vx * 0.8
                        p.bounces = p.bounces + 1
                    end
                    if p.z < worldBounds.minZ then
                        p.z = worldBounds.minZ
                        p.vz = -p.vz * 0.8
                        p.bounces = p.bounces + 1
                    elseif p.z > worldBounds.maxZ then
                        p.z = worldBounds.maxZ
                        p.vz = -p.vz * 0.8
                        p.bounces = p.bounces + 1
                    end
                end

                -- Bounce off walls (if not hitting door opening)
                if walls then
                    local hitWall = false
                    -- Check if near the wall plane
                    if math.abs(p.z - walls.doorZ) < 0.2 then
                        -- Check if hitting wall sections (not door opening)
                        if p.x < walls.doorLeftX or p.x > walls.doorRightX then
                            p.z = walls.doorZ + (p.z > walls.doorZ and 0.2 or -0.2)
                            p.vz = -p.vz * 0.8
                            p.bounces = p.bounces + 1
                            hitWall = true
                            print("Cannonball bounced off wall!")
                        end
                    end
                end

                -- simple lifetime cut-off
                if math.abs(p.x - x) > 100 or math.abs(p.z - z) > 100 then
                    p.alive = false
                end

                -- check collision with door
                if door and door.locked then
                    local ddx = p.x - (door.x or 0)
                    local ddz = p.z - (door.z or 0)
                    local d = math.sqrt(ddx*ddx + ddz*ddz)
                    if d < 1.5 then
                        door.locked = false
                        door.exploding = true
                        door.explosionTime = 0
                        p.alive = false
                        print("BOOM! Door destroyed!")
                    end
                end
            end
        end
        
        return stoppedProjectiles
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
            projMesh:translate(p.x, 1.0, p.z)
            projMesh:scale(0.8)
            dream:draw(projMesh)
        end
    end

    return self
end

return cannon
