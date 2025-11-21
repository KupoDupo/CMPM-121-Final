local character = {};
local TILESIZE = 32

local physics = require("3DreamEngine/extensions/physics/init")

-- Creates character
function character.new(name, startX, startY, startZ)
    local self = {};

    local x = startX
    local y = startY
    local z = startZ
    local name = name
    
    self.object = dream:newCapsule(1, 2, 3)
    shape = self.object
    
    shape:resetTransform()
    shape:translate(x * TILESIZE, y * TILESIZE, z)
    shape:scale(1)

    function self:draw()
      --love.graphics.rectangle('fill', x * TILESIZE, y * TILESIZE, TILESIZE, TILESIZE);
      dream:prepare()
      dream:draw(shape)
      dream:present()
    end

    function self:update(dt)
        -- DO STUFF
    end

    function self:getX()
        return x
    end

    function self:getY()
        return y
    end
    
    function self.getZ()
      return z
    end

    function self:getName()
        return name;
    end

    return self;
end

return character; 