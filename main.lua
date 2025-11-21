local SceneryInit = require("scenery")
-- "menu" is the scene key (a string)
local scenery = SceneryInit("menu") 
scenery:hook(love)

local bump = require 'bump-3dpd'

local character = {};
-- Creates character
function character.new(name)
    local self = {};

    local x, y;
    local name = name;

    function self:draw()
        love.graphics.rectangel('fill', x * TILESIZE, y * TILESIZE, TILESIZE, TILESIZE);
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