local menu_scene = {} -- This is the scene table Scenery will use

-- Create table for buttons and function to create the buttons
local buttons = {}
local function newButton(x, y, width, height, text, callback)
    return {
        x = x,
        y = y,
        width = width,
        height = height,
        text = text,
        callback = callback,
        isHovered = false,
        isPressed = false
    }
end

function menu_scene:load()
    -- Clear buttons table just in case the scene loads multiple times
    buttons = {} 
    
    -- Create the "Play" button. 
    table.insert(buttons, newButton(100, 100, 150, 40, "Play", function()
        scenery.setScene("room1") 
        print("Play button clicked!") 
    end))

    -- Create the "Quit" button
    table.insert(buttons, newButton(100, 160, 150, 40, "Quit", function()
        love.event.quit()
    end))

  titleFont = love.graphics.newFont(40)
end

function menu_scene:draw()
    love.graphics.clear(0.1, 0.1, 0.2)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(titleFont)
    love.graphics.printf("Escape the Haunted House!", 0, 300, love.graphics.getWidth(), "center")
    
    love.graphics.setNewFont(14)
    for _, btn in pairs(buttons) do
        if btn.isPressed then
            love.graphics.setColor(0.4, 0.4, 0.4) -- Pressed Color
        elseif btn.isHovered then
            love.graphics.setColor(0.6, 0.6, 0.6) -- Hover Color
        else
            love.graphics.setColor(0.8, 0.8, 0.8) -- Default Color
        end
            
        love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(btn.text, btn.x + 5, btn.y + 5)
    end
end

function menu_scene:update(dt)
    -- Update button state
    local mouseX, mouseY = love.mouse.getPosition()
    for _, btn in pairs(buttons) do
        -- Check for hover
        btn.isHovered = (mouseX >= btn.x and mouseX <= btn.x + btn.width and
                         mouseY >= btn.y and mouseY <= btn.y + btn.height)
    end
end

-- Updates the isPressed / isHovered variables for the button when pressed 
function menu_scene:mousepressed(x, y, button)
    if button == 1 then -- Left mouse button
        for _, btn in pairs(buttons) do
            if btn.isHovered then
                btn.isPressed = true
            end
        end
    end
end

-- Updates the isPressed / isHovered variables for the button when released
function menu_scene:mousereleased(x, y, button)
    if button == 1 then
        for _, btn in pairs(buttons) do
            if btn.isPressed and btn.isHovered and btn.callback then
                btn.callback() -- Execute the button's function
            end
            btn.isPressed = false
        end
    end
end

-- The scene file MUST return the table containing the callback methods
return menu_scene