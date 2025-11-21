--[[local currentScene

function love.load()
  currentScene = require("scenes.menu") -- Load the initial scene
  currentScene.load()
end

function love.update(dt)
  if currentScene and currentScene.update then
      currentScene.update(dt)
  end
end

function love.draw()
  if currentScene and currentScene.draw then
      currentScene.draw()
  end
end

function changeScene(newSceneName)
  self.setScene("menu")
  currentScene.load()
end--]]

-- main.lua (Recommended Automatic Loading Setup)
local SceneryInit = require("scenery")

-- "menu" is the scene key (a string)
local scenery = SceneryInit("menu") 

scenery:hook(love)