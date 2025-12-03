local SavePoint = {}
local SaveManager = require("savemanager")

function SavePoint.new(x, z, slotNumber)
    local self = {}
    
    self.x = x or 0
    self.z = z or 0
    self.slotNumber = slotNumber or 1
    self.isActive = false
    self.activationRadius = 1.5
    self.cooldown = 0
    self.cooldownTime = 1.0  -- Prevent spam saving
    
    -- Visual representation
    self.object = dream:loadObject("assets/cube")
    
    function self:update(dt, player)
        if self.cooldown > 0 then
            self.cooldown = self.cooldown - dt
        end
        
        if not player then
            self.isActive = false
            return
        end
        
        local px, pz = player:getX(), player:getZ()
        local dist = math.sqrt((px - self.x)^2 + (pz - self.z)^2)
        
        self.isActive = dist <= self.activationRadius
    end
    
    function self:draw()
        if not self.object then return end
        
        -- Create glowing material for save point
        local mat = dream:newMaterial()
        if self.isActive then
            -- Bright pulsing cyan when player is near
            local pulse = math.sin(love.timer.getTime() * 3) * 0.3 + 0.7
            mat.color = {0.2 * pulse, 0.8 * pulse, 1.0 * pulse, 1}
            mat.roughness = 0.1
            mat.metallic = 0.8
        else
            -- Dim cyan when inactive
            mat.color = {0.1, 0.4, 0.5, 1}
            mat.roughness = 0.3
            mat.metallic = 0.5
        end
        mat.cullMode = "none"
        
        -- Apply material to object
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
        
        -- Position and draw the save point
        self.object:resetTransform()
        self.object:translate(self.x, 0.3, self.z)
        self.object:rotateY(love.timer.getTime() * 0.5)  -- Slow rotation
        self.object:scale(0.5, 0.5, 0.5)
        dream:draw(self.object)
    end
    
    function self:tryActivate(currentScene, player, inventory)
        if not self.isActive or self.cooldown > 0 then
            return false, "Save point not active"
        end
        
        -- Perform manual save
        local success = SaveManager.manualSave(self.slotNumber, currentScene, player, inventory)
        
        if success then
            self.cooldown = self.cooldownTime
            return true, "Game saved to slot " .. self.slotNumber
        else
            return false, "Failed to save game"
        end
    end
    
    function self:getX() return self.x end
    function self:getZ() return self.z end
    function self:isPlayerNear() return self.isActive end
    
    return self
end

return SavePoint
