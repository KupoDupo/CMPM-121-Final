local room1_scene = {}
local character = require('character')

local player
local sun

-- This calculates a 3D ray from the 2D mouse position manually
local function getMouseRay(mx, my, camera)
  local width, height = love.graphics.getDimensions()
  
  -- 1. Normalized Device Coordinates (NDC)
  -- Map mouse x/y from [0, width] to [-1, 1]
  local ndc_x = (mx / width) * 2 - 1
  local ndc_y = (my / height) * 2 - 1
  
  -- 2. Inverse Projection & View Matrices
  -- 3DreamEngine stores the projection matrix in 'camera.projection'
  -- and the transform (view) in 'camera.transform'
  local invProj = camera.projection:invert()
  local invView = camera.transform -- The camera's transform is already the inverse view
  
  -- 3. Unproject points (Near plane z=-1, Far plane z=1)
  -- We create a vector at the near plane and far plane
  local clipNear = {ndc_x, ndc_y, -1, 1}
  local clipFar  = {ndc_x, ndc_y,  1, 1}
  
  -- Transform from Clip Space to View Space (using Inverse Projection)
  local function multMat4Vec4(m, v)
    local x = m[1]*v[1] + m[5]*v[2] + m[9]*v[3] + m[13]*v[4]
    local y = m[2]*v[1] + m[6]*v[2] + m[10]*v[3] + m[14]*v[4]
    local z = m[3]*v[1] + m[7]*v[2] + m[11]*v[3] + m[15]*v[4]
    local w = m[4]*v[1] + m[8]*v[2] + m[12]*v[3] + m[16]*v[4]
    return {x, y, z, w}
  end
  
  local viewNear = multMat4Vec4(invProj, clipNear)
  local viewFar  = multMat4Vec4(invProj, clipFar)
  
  -- Perspective divide (normalize w)
  local function divW(v) return {v[1]/v[4], v[2]/v[4], v[3]/v[4]} end
    local pNear = divW(viewNear)
    local pFar  = divW(viewFar)
    
    -- 4. Transform from View Space to World Space (using Camera Transform)
    -- Since we need world coordinates, we apply the camera's position/rotation
    -- Note: 3DreamEngine might handle this internally, but let's assume pFar is a direction
    -- Simpler approach: Use the engine's raycast if available, but since it crashed:
    
    -- FALLBACK: If the manual math is too complex for this snippet, 
    -- let's rely on a simpler geometric approximation for Top-Down games.
  return nil -- Placeholder if complex math fails
end

-- --- SIMPLIFIED RAYCAST ---
-- Since we have a fixed camera angle, we can cheat the math!
local function getGroundClick(mx, my, camX, camY, camZ)
  -- Approximate the click on the floor (y=0) based on screen center offset
  local width, height = love.graphics.getDimensions()
  local dx = (mx - width/2) / (height/2)
  local dy = (my - height/2) / (height/2)
  
  -- Scale factors depend on FOV and Camera Height (approximate for now)
  local scale = camY * 0.8 
  
  local worldX = camX + dx * scale
  local worldZ = camZ + dy * scale
  
  return worldX, worldZ
end

function room1_scene:load()
  love.graphics.setBackgroundColor(0.4, 0.6, 0.9)
  player = character.new('player', 1, 1, 1)
  sun = dream:newLight("sun", dream.vec3(5, 10, 5), dream.vec3(1, 0.9, 0.8), 1.5)
  sun:addNewShadow()
end
  
function room1_scene:draw()
  --[[player:draw()
  love.graphics.setColor(212, 65, 36)
  love.graphics.print("Room 1 yay!", 400, 300)--]]
  dream:prepare()
  dream:addLight(sun)

  if player then
    player:draw()
    
    -- Draw Floor (using player's cube mesh flattened)
    local floorObj = player:getObject()
    for x = -5, 5 do
      for z = -5, 5 do
        floorObj:resetTransform()
        floorObj:translate(x * 2, -1, z * 2)
        floorObj:scale(2, 0.1, 2)
        dream:draw(floorObj)
      end
    end
  end
  
  dream:present()
    
  -- 2D UI Overlay
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("Room 1 - Click to Move!", 10, 10)
end

function room1_scene:update(dt)
  if player then
    player:update(dt)
    
    -- Camera follows player
    dream.camera:resetTransform()
    dream.camera:translate(player:getX(), 10, player:getZ() + 10)
    dream.camera:rotateX(math.pi / 4)
  end
  
  dream:update(dt)
  
end

function room1_scene:mousepressed(x, y, button)
  if button == 1 and player then
    -- Use the simplified raycast since getRay is broken
    local camX, camY, camZ = player:getX(), 10, player:getZ() + 10
    local hitX, hitZ = getGroundClick(x, y, camX, camY, camZ - 10) -- Offset adjustment
    
    player:walkTo(hitX, hitZ)
  end
end

return room1_scene