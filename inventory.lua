local Inventory = {}
Inventory.__index = Inventory

function Inventory.new()
    local self = setmetatable({}, Inventory)
    self.items = {}
    self.isOpen = false
    self.draggingItem = nil
    self.dragOffsetX = 0
    self.dragOffsetY = 0
    self.slots = 6  -- Number of inventory slots
    return self
end

function Inventory:addItem(itemName, displayName)
    if not self.items[itemName] then
        -- TODO: Revert to image path when Key images are properly created
        local icon = nil
        -- Keys use placeholder (yellow square drawn in draw function)
        if itemName ~= "Key" and itemName ~= "Key_room3" and itemName ~= "Key_room1" then
            icon = love.graphics.newImage("assets/" .. itemName .. ".png")
        end
        
        self.items[itemName] = {
            name = itemName,
            displayName = displayName or itemName,
            icon = icon
        }
        return true
    end
    return false
end

function Inventory:removeItem(itemName)
    if self.items[itemName] then
        self.items[itemName] = nil
        return true
    end
    return false
end

function Inventory:hasItem(itemName)
    return self.items[itemName] ~= nil
end

function Inventory:toggle()
    self.isOpen = not self.isOpen
    if not self.isOpen then
        self.draggingItem = nil
    end
end

function Inventory:open()
    self.isOpen = true
end

function Inventory:close()
    self.isOpen = false
    self.draggingItem = nil
end

function Inventory:startDrag(itemName, mouseX, mouseY)
    if self.items[itemName] then
        self.draggingItem = itemName
        -- Calculate offset from slot position
        local slotX, slotY = self:getSlotPosition(itemName)
        self.dragOffsetX = mouseX - slotX
        self.dragOffsetY = mouseY - slotY
    end
end

function Inventory:stopDrag()
    self.draggingItem = nil
end

function Inventory:getSlotPosition(itemName)
    local startX = love.graphics.getWidth() / 2 - 150
    local startY = love.graphics.getHeight() / 2 - 50
    local slotSize = 60
    local padding = 10
    
    local index = 0
    for name, _ in pairs(self.items) do
        if name == itemName then
            break
        end
        index = index + 1
    end
    
    local col = index % 3
    local row = math.floor(index / 3)
    
    return startX + col * (slotSize + padding), startY + row * (slotSize + padding)
end

function Inventory:draw(mouseX, mouseY)
    if not self.isOpen then
        -- Draw inventory button
        love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
        love.graphics.rectangle("fill", love.graphics.getWidth() - 110, 10, 100, 30, 5, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Inventory (I)", love.graphics.getWidth() - 105, 17)
        
        -- Draw item count
        local itemCount = 0
        for _ in pairs(self.items) do
            itemCount = itemCount + 1
        end
        if itemCount > 0 then
            love.graphics.setColor(1, 0.8, 0)
            love.graphics.circle("fill", love.graphics.getWidth() - 15, 15, 8)
            love.graphics.setColor(0, 0, 0)
            love.graphics.print(tostring(itemCount), love.graphics.getWidth() - 18, 10)
        end
        return
    end
    
    -- Draw inventory panel
    local panelW = 350
    local panelH = 200
    local panelX = love.graphics.getWidth() / 2 - panelW / 2
    local panelY = love.graphics.getHeight() / 2 - panelH / 2
    
    -- Panel background
    love.graphics.setColor(0.1, 0.1, 0.15, 0.95)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 10, 10)
    
    -- Panel border
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 10, 10)
    
    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("INVENTORY", panelX + 10, panelY + 10)
    love.graphics.print("(Drag items onto objects to use)", panelX + 10, panelY + 30)
    love.graphics.print("Press I to close", panelX + 10, panelY + panelH - 25)
    
    -- Draw inventory slots
    local slotSize = 60
    local padding = 10
    local startX = panelX + 45
    local startY = panelY + 60
    
    local index = 0
    for itemName, itemData in pairs(self.items) do
        if itemName ~= self.draggingItem then
            local col = index % 3
            local row = math.floor(index / 3)
            local x = startX + col * (slotSize + padding)
            local y = startY + row * (slotSize + padding)
            
            -- Slot background
            love.graphics.setColor(0.2, 0.2, 0.25)
            love.graphics.rectangle("fill", x, y, slotSize, slotSize, 5, 5)
            
            -- Slot border
            love.graphics.setColor(0.4, 0.4, 0.5)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", x, y, slotSize, slotSize, 5, 5)
            
            -- Item icon (simplified - just draw colored square)
            if itemData.icon then
                love.graphics.setColor(1, 1, 1)
                local icon = itemData.icon
                local iconW, iconH = icon:getWidth(), icon:getHeight()
                local scale = (slotSize - 20) / math.max(iconW, iconH)
                love.graphics.draw(icon, x + 10, y + 10, 0, scale, scale)
            else
                -- Placeholder for items without icons (e.g., Key)
                love.graphics.setColor(0.9, 0.8, 0.1)  -- Yellow for Key
                love.graphics.rectangle("fill", x + 10, y + 10, slotSize - 20, slotSize - 20, 3, 3)
            end
            
            -- Item name
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(itemData.displayName, x, y + slotSize - 15, slotSize, "center")
        end
        index = index + 1
    end
    
    -- Draw dragging item
    if self.draggingItem and self.items[self.draggingItem] then
        local x = mouseX - self.dragOffsetX
        local y = mouseY - self.dragOffsetY
        
        -- Semi-transparent while dragging
        love.graphics.setColor(0.2, 0.2, 0.25, 0.8)
        love.graphics.rectangle("fill", x, y, slotSize, slotSize, 5, 5)
        
        if self.items[self.draggingItem].icon then
            love.graphics.setColor(1, 1, 1, 0.9)
            local icon = self.items[self.draggingItem].icon
            local iconW, iconH = icon:getWidth(), icon:getHeight()
            local scale = (slotSize - 20) / math.max(iconW, iconH)
            love.graphics.draw(icon, x + 10, y + 10, 0, scale, scale)
        else
            -- Placeholder for items without icons (e.g., Key)
            love.graphics.setColor(0.9, 0.8, 0.1, 0.8)  -- Yellow for Key
            love.graphics.rectangle("fill", x + 10, y + 10, slotSize - 20, slotSize - 20)
        end
        
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf(self.items[self.draggingItem].displayName, x, y + slotSize - 15, slotSize, "center")
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(1)
end

function Inventory:mousepressed(x, y, button)
    if button == 1 then
        if not self.isOpen then
            -- Check if clicking inventory button
            if x >= love.graphics.getWidth() - 110 and x <= love.graphics.getWidth() - 10 and
               y >= 10 and y <= 40 then
                self:open()
                return true
            end
        else
            -- Check if clicking on an item to drag
            local slotSize = 60
            local padding = 10
            local startX = love.graphics.getWidth() / 2 - 150
            local startY = love.graphics.getHeight() / 2 - 50
            
            local index = 0
            for itemName, _ in pairs(self.items) do
                local col = index % 3
                local row = math.floor(index / 3)
                local slotX = startX + col * (slotSize + padding)
                local slotY = startY + row * (slotSize + padding)
                
                if x >= slotX and x <= slotX + slotSize and
                   y >= slotY and y <= slotY + slotSize then
                    self:startDrag(itemName, x, y)
                    return true
                end
                index = index + 1
            end
        end
    end
    return false
end

function Inventory:mousereleased(x, y, button)
    if button == 1 and self.draggingItem then
        local item = self.draggingItem
        self:stopDrag()
        return item  -- Return the item that was dropped
    end
    return nil
end

function Inventory:keypressed(key)
    if key == "i" then
        self:toggle()
        return true
    end
    return false
end

function Inventory:clear()
    self.items = {}
    self.draggingItem = nil
    self.isOpen = false
end

return Inventory
