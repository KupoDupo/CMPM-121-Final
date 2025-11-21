local character = {};
local TILESIZE = 32

-- Creates character
function character.new(name, startX, startY, startZ)
  local self = {};
  
  -- Private Variables
  local x = startX or 0
  local y = startY or 0
  local z = startZ or 0
  local name = name or "unknown"
  local speed = 6
  local isMoving = false
  local targetX = x
  local targetZ = z
  
  -- Mesh Generation
  local vertices = {}
  local function addFace(v1, v2, v3, v4, nx, ny, nz)
    table.insert(vertices, {v1[1], v1[2], v1[3], nx, ny, nz, 0, 0})
    table.insert(vertices, {v2[1], v2[2], v2[3], nx, ny, nz, 1, 0})
    table.insert(vertices, {v3[1], v3[2], v3[3], nx, ny, nz, 1, 1})
    table.insert(vertices, {v1[1], v1[2], v1[3], nx, ny, nz, 0, 0})
    table.insert(vertices, {v3[1], v3[2], v3[3], nx, ny, nz, 1, 1})
    table.insert(vertices, {v4[1], v4[2], v4[3], nx, ny, nz, 0, 1})
  end

  local p1 = {-0.5, -0.5,  0.5}; local p2 = { 0.5, -0.5,  0.5}
  local p3 = { 0.5,  0.5,  0.5}; local p4 = {-0.5,  0.5,  0.5}
  local p5 = {-0.5, -0.5, -0.5}; local p6 = { 0.5, -0.5, -0.5}
  local p7 = { 0.5,  0.5, -0.5}; local p8 = {-0.5,  0.5, -0.5}

  addFace(p1, p2, p3, p4,  0,  0,  1); addFace(p6, p5, p8, p7,  0,  0, -1)
  addFace(p5, p1, p4, p8, -1,  0,  0); addFace(p2, p6, p7, p3,  1,  0,  0)
  addFace(p4, p3, p7, p8,  0,  1,  0); addFace(p5, p6, p2, p1,  0, -1,  0)

  -- Create the 3D Object
  local mesh = dream:newMesh(name .. "_mesh", vertices, nil, "simple")
  local object = dream:newObject(mesh)
  
  -- Set Material
  local mat = dream:newMaterial()
  mat.color = {1.0, 0.2, 0.2, 1.0}
  object.material = mat
  
  -- Methods
  function self:walkTo(newX, newZ)
    targetX = newX
    targetZ = newZ
    isMoving = true
  end
  
  function self:draw()
    --love.graphics.rectangle('fill', x * TILESIZE, y * TILESIZE, TILESIZE, TILESIZE)
    object:resetTransform()
    object:translate(x, y, z)
    dream:draw(object)
  end

  function self:update(dt)
    if not isMoving then return end

    -- Calculate distance to target
    local dx = targetX - x
    local dz = targetZ - z
    local dist = math.sqrt(dx*dx + dz*dz)

    -- If we are very close, stop moving (snap to target)
    if dist < 0.1 then
        x = targetX
        z = targetZ
        isMoving = false
    else
        -- Move towards target
        -- Normalize direction and multiply by speed
        x = x + (dx / dist) * speed * dt
        z = z + (dz / dist) * speed * dt
    end
  end

  function self:getX()
    return x
  end

  function self:getY()
    return y
  end
  
  function self:getZ()
    return z
  end

  function self:getName()
    return name
  end

  return self
end

return character; 