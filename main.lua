
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

function love.load()
  
  -- Create the initial buttons
  table.insert(buttons, newButton(100, 100, 150, 40, "Play",  function()
    print("Play button clicked!")
  end))

  table.insert(buttons, newButton(100, 160, 150, 40, "Quit", function()
    love.event.quit()
  end))
end

function love.draw()
  love.graphics.print("Escape the Haunted House!!!", 400, 300)
  
  for _, btn in pairs(buttons) do
    if btn.isPressed then
      love.graphics.setColor(0.5, 0.5, 0.5) -- Pressed Color
    elseif btn.isHovered then
      love.graphics.setColor(0.7, 0.7, 0.7) -- Hover Color
    else
      love.graphics.setColor(0.9, 0.9, 0.9) -- Default Color
    end
      
    love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(btn.text, btn.x + 5, btn.y + 5)
  end
end

function love.update(dt)
  
  -- Update button state
  local mouseX, mouseY = love.mouse.getPosition()
  for _, btn in pairs(buttons) do
      -- Check for hover
      btn.isHovered = (mouseX >= btn.x and mouseX <= btn.x + btn.width and
                       mouseY >= btn.y and mouseY <= btn.y + btn.height)
  end
end

-- Updates the isPressed / isHovered variables for the button when pressed 
function love.mousepressed(x, y, button)
    if button == 1 then -- Left mouse button
        for _, btn in pairs(buttons) do
            if btn.isHovered then
                btn.isPressed = true
            end
        end
    end
end

-- Updates the isPressed / isHovered variables for the button when released
function love.mousereleased(x, y, button)
    if button == 1 then
        for _, btn in pairs(buttons) do
            if btn.isPressed and btn.isHovered and btn.callback then
                btn.callback() -- Execute the button's function
            end
            btn.isPressed = false
        end
    end
end