local SceneryInit = require("scenery")
-- "menu" is the scene key (a string)
local scenery = SceneryInit("menu") 
scenery:hook(love)

local bump = require 'bump-3dpd'

dream = require("3DreamEngine")

function love.load()
  dream:init()
    dream:setSky(0.4, 0.6, 0.9)

    -- Create a sun
    local sun = dream:newLight("sun", {10, 20, 10}, {1, 0.9, 0.8}, 1.5)
    sun:setShadow(true) -- Enable shadows if your GPU supports it
    dream:addLight(sun)

    -- --- STEP 1: DEFINE A CUBE IN CODE ---
    -- 3DreamEngine meshes use a specific vertex format.
    -- We will define the 6 faces of a cube manually.
    -- Format: {x, y, z,   nx, ny, nz,   u, v}
    
    local vertices = {}
    local function addFace(v1, v2, v3, v4, nx, ny, nz)
        -- Triangle 1
        table.insert(vertices, {v1[1], v1[2], v1[3], nx, ny, nz, 0, 0})
        table.insert(vertices, {v2[1], v2[2], v2[3], nx, ny, nz, 1, 0})
        table.insert(vertices, {v3[1], v3[2], v3[3], nx, ny, nz, 1, 1})
        -- Triangle 2
        table.insert(vertices, {v1[1], v1[2], v1[3], nx, ny, nz, 0, 0})
        table.insert(vertices, {v3[1], v3[2], v3[3], nx, ny, nz, 1, 1})
        table.insert(vertices, {v4[1], v4[2], v4[3], nx, ny, nz, 0, 1})
    end

    -- Cube corners
    local p1 = {-0.5, -0.5,  0.5} -- Front Bottom Left
    local p2 = { 0.5, -0.5,  0.5} -- Front Bottom Right
    local p3 = { 0.5,  0.5,  0.5} -- Front Top Right
    local p4 = {-0.5,  0.5,  0.5} -- Front Top Left
    local p5 = {-0.5, -0.5, -0.5} -- Back Bottom Left
    local p6 = { 0.5, -0.5, -0.5} -- Back Bottom Right
    local p7 = { 0.5,  0.5, -0.5} -- Back Top Right
    local p8 = {-0.5,  0.5, -0.5} -- Back Top Left

    -- Add faces (Front, Back, Left, Right, Top, Bottom)
    addFace(p1, p2, p3, p4,  0,  0,  1) -- Front
    addFace(p6, p5, p8, p7,  0,  0, -1) -- Back
    addFace(p5, p1, p4, p8, -1,  0,  0) -- Left
    addFace(p2, p6, p7, p3,  1,  0,  0) -- Right
    addFace(p4, p3, p7, p8,  0,  1,  0) -- Top
    addFace(p5, p6, p2, p1,  0, -1,  0) -- Bottom

    -- --- STEP 2: CREATE THE MESH AND OBJECT ---
    -- Create a mesh from the vertices
    -- "simple" is the standard material format for 3DreamEngine
    local cubeMesh = dream:newMesh("player_cube", vertices, nil, "simple")
    
    -- Create an Object using that mesh
    player.object = dream:newObject(cubeMesh)
    
    -- Add a material (Red Color)
    local mat = dream:newMaterial()
    mat.color = {1.0, 0.2, 0.2, 1.0} -- Red
    mat.roughness = 0.5
    player.object.material = mat
end

function love.update(dt)
    -- Simple Movement
    local dx, dz = 0, 0
    if love.keyboard.isDown("w") then dz = -1 end
    if love.keyboard.isDown("s") then dz =  1 end
    if love.keyboard.isDown("a") then dx = -1 end
    if love.keyboard.isDown("d") then dx =  1 end

    -- Normalize diagonal speed
    if dx ~= 0 or dz ~= 0 then
        local length = math.sqrt(dx*dx + dz*dz)
        dx, dz = dx/length, dz/length
        player.x = player.x + dx * player.speed * dt
        player.z = player.z + dz * player.speed * dt
    end

    -- Update Camera to follow player
    dream.camera:reset()
    dream.camera:translate(player.x, player.y + 4, player.z + 6)
    dream.camera:lookAt(player.x, player.y, player.z)

    -- Update Engine
    dream:update(dt)
end

function love.draw()
    dream:prepare()

    -- Draw the player
    if player.object then
        player.object:resetTransform()
        player.object:translate(player.x, player.y, player.z)
        dream:draw(player.object)
    end
    
    -- Draw a "Floor" grid (Visual helper)
    -- (Usually you'd have a floor object, but this helps visualize movement)
    for x = -10, 10, 2 do
        for z = -10, 10, 2 do
            -- We can reuse the player object mesh for the floor tiles temporarily!
            player.object:resetTransform()
            player.object:translate(x * 2, -1, z * 2)
            player.object:scale(2, 0.1, 2) -- Flatten it
            dream:draw(player.object)
        end
    end

    dream:present()
end

function love.resize(w, h)
    dream:resize(w, h)
end
