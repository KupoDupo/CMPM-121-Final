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
    
    -- Use cannon-ball for a round shadow
    local shadow = dream:loadObject("assets/cannon-ball") 

    -- Load player model
    local object = dream:loadObject("assets/player")
    
    -- Load player texture with proper wrapping for negative UVs
    local img_status, playerTexture = pcall(love.graphics.newImage, "assets/player.png")
    if img_status and playerTexture then
        playerTexture:setWrap("repeat", "repeat")
    else
        playerTexture = nil
    end
    
    local mat = dream:newMaterial()
    mat.color = {1, 1, 1, 1}
    mat.roughness = 0.6
    mat.metallic = 0.1
    mat.cullMode = "none"
    if playerTexture then mat.albedoTexture = playerTexture end
    
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
    
    paintRecursive(object, mat)
    
    -- Apply Shadow with high translucency
    local shadowMat = dream:newMaterial()
    shadowMat.color = {0, 0, 0, 0.15} 
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
      -- Draw Shadow (round and flat)
      shadow:resetTransform()
      shadow:translate(x, y, z)
      shadow:scale(1.5, 0.05, 1.5)  -- larger and very flat to look like a round shadow
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