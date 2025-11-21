local character = {}

function character.new(name, startX, startY, startZ)
    local self = {}

    -- Position variables
    local x = startX or 0
    local y = startY or 0
    local z = startZ or 0
    
    local targetX = x
    local targetZ = z
    local speed = 4
    local isMoving = false

    -- [[ TAVERN METHOD: Load the .obj file directly ]]
    -- This replaces all that complex vertex table code!
    -- It looks for "player.obj" in the same folder as main.lua
    local object = dream:loadObject("player")
    
    -- Create a material for it
    local mat = dream:newMaterial()
    mat.color = {1.0, 0.2, 0.2, 1.0} -- Red
    mat.roughness = 0.5              -- Not too shiny
    object.material = mat

    -- --- MOVEMENT LOGIC ---

    function self:walkTo(newX, newZ)
        targetX = newX
        targetZ = newZ
        isMoving = true
    end

    function self:update(dt)
        if not isMoving then return end

        local dx = targetX - x
        local dz = targetZ - z
        local dist = math.sqrt(dx*dx + dz*dz)

        if dist < 0.1 then
            x = targetX
            z = targetZ
            isMoving = false
        else
            x = x + (dx / dist) * speed * dt
            z = z + (dz / dist) * speed * dt
        end
    end

    function self:draw()
        -- Move the object to the character's X,Y,Z before drawing
        object:resetTransform()
        object:translate(x, y, z)
        dream:draw(object)
    end

    -- Getters
    function self:getX() return x end
    function self:getY() return y end
    function self:getZ() return z end
    function self:getObject() return object end

    return self
end

return character