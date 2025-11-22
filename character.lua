local character = {}

function character.new(name, startX, startY, startZ)
    local self = {}

    local x = startX or 0
    local y = startY or 0
    local z = startZ or 0
    local targetX, targetZ = x, z
    local speed = 4
    local isMoving = false

  -- This looks for "player.dae" in your project folder.
    local object = dream:loadObject("assets/player")
    
    -- Apply Red Shiny Material
    local mat = dream:newMaterial()
    mat.color = {1.0, 0.0, 0.0, 1.0} -- Bright Red
    mat.roughness = 0.2              -- Shiny (Low roughness)
    mat.metallic = 0.0               -- Plastic-like
    
    mat.cullMode = "none" 

    -- 3. Recursive Paint Function
    -- Applies our double-sided material to every part of the model
    local function paintRecursive(obj, material)
        -- Paint meshes at this level
        if obj.meshes then
            for _, mesh in pairs(obj.meshes) do
                mesh.material = material
            end
        end
        
        -- Dig deeper into children
        if obj.objects then
            for _, child in pairs(obj.objects) do
                paintRecursive(child, material)
            end
        end
    end

    paintRecursive(object, mat)

    -- --- LOGIC ---
    function self:walkTo(tx, tz)
        targetX, targetZ = tx, tz
        isMoving = true
    end

    function self:update(dt)
        if not isMoving then return end
        local dx = targetX - x
        local dz = targetZ - z
        local dist = math.sqrt(dx*dx + dz*dz)
        if dist < 0.1 then
            x, z = targetX, targetZ
            isMoving = false
        else
            x = x + (dx / dist) * speed * dt
            z = z + (dz / dist) * speed * dt
        end
    end

    function self:draw()
        object:resetTransform()
        object:translate(x, y, z)
        
        -- Apply that 10x scale every frame
        object:scale(0.5) 
        
        dream:draw(object)
    end

    function self:getX() return x end
    function self:getY() return y end
    function self:getZ() return z end
    function self:getObject() return object end

    return self
end

return character