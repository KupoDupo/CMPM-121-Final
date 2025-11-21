local character = {};
local TILESIZE = 32
-- Creates character
function character.new(name, startX, startY)
    local self = {};

    local x = startX
    local y = startY
    local name = name

    function self:draw()
        love.graphics.rectangle('fill', x * TILESIZE, y * TILESIZE, TILESIZE, TILESIZE);
    end

    function self:update(dt)
        -- DO STUFF
    end

    function self:getX()
        return x;
    end

    function self:getY()
        return y;
    end

    function self:getName()
        return name;
    end

    return self;
end

return character; 