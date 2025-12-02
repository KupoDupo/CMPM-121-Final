local character = {}

function character.new(name, startX, startY, startZ)
    local self = {}

    local x = startX or 0
    local y = startY or 0
    local z = startZ or 0
    local targetX, targetZ = x, z
    local rotation = 0 -- Track character rotation angle
    local speed = 6
    local isMoving = false
    local stopThreshold = 0.08 -- when closer than this, snap to target
    local decelDistance = 0.8  -- start slowing down within this distance
    local shadow = dream:loadObject("assets/cube") -- shadow 

  -- This looks for "player.dae" in your project folder.
    local object = dream:loadObject("assets/human_model")
    
    -- Apply Red Shiny Material
    local mat = dream:newMaterial()
    mat.color = {1.0, 0.0, 0.0, 1.0} -- Bright Red
    mat.roughness = 0.2              -- Shiny (Low roughness)
    mat.metallic = 0.0               -- Plastic-like
    
    mat.cullMode = "none" 
    
    -- Apply Shadow
    local shadowMat = dream:newMaterial()
    shadowMat.color = {0, 0, 0, 0.10} 
    shadowMat.roughness = 1.0 
    shadowMat.metallic = 0.0
    shadowMat.cullMode = "none"

    -- apply to shadow
    local function paintShadow(obj, material)
        if obj.meshes then
            for _, mesh in pairs(obj.meshes) do
                mesh.material = material
            end
        end
        if obj.objects then
            for _, child in pairs(obj.objects) do
                paintShadow(child, material)
            end
        end
    end

    paintShadow(shadow, shadowMat)

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

    ----- LOGIC ----
    function self:walkTo(tx, tz)
        targetX, targetZ = tx, tz
        isMoving = true
    end

    function self:update(dt)
        if not isMoving then return end
        local dx = targetX - x
        local dz = targetZ - z
        local dist = math.sqrt(dx*dx + dz*dz)
        if dist <= stopThreshold or dist == 0 then
            -- close enough: snap exactly to target
            x, z = targetX, targetZ
            isMoving = false
            return
        end

        -- Calculate rotation to face movement direction
        rotation = -math.atan2(dx, dz)

        -- slow down when approaching the target for more accurate stops
        local moveSpeed = speed
        if dist < decelDistance then
            local t = dist / decelDistance
            -- ease-out like reduction (quadratic)
            moveSpeed = speed * (t * t)
            -- ensure a minimum movement so we don't stall
            moveSpeed = math.max(moveSpeed, 1.2)
        end

        -- move by computed step but don't overshoot
        local step = moveSpeed * dt
        if step >= dist then
            x, z = targetX, targetZ
            isMoving = false
        else
            x = x + (dx / dist) * step
            z = z + (dz / dist) * step
        end
    end

    function self:draw()
      -- Draw Shadow
      shadow:resetTransform()
      shadow:translate(x, y - 0.9, z)   -- slightly under the player's feet
      shadow:rotateY(math.rad(45))
      shadow:scale(1.3, 0.03, 1.3)
      dream:draw(shadow)
        
      -- Draw Player
      object:resetTransform()
      object:translate(x, y, z)
      object:rotateY(rotation) -- Apply rotation to face movement direction
      object:scale(0.5) -- Apply that 10x scale every frame
        
        dream:draw(object)
    end

    function self:getX() return x end
    function self:getY() return y end
    function self:getZ() return z end
    function self:getObject() return object end

    return self
end

return character