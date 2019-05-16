local splore = require("splore").new()
splore:addGameList("https://github.com/hnd2/GameList")
splore:addGameList("assets/mygameList/list.lua")
splore:loadGameLists()

local gameNames = splore:getGameNames()
local selectionIndex = 0
local selectedGameInfo = nil

--------------------------------------------------
function love.draw()
  -- draw thumb
  if selectedGameInfo ~= nil and selectedGameInfo.thumbImage then
    love.graphics.draw(selectedGameInfo.thumbImage)
  end

  -- draw list
  local names = {"[update]", unpack(gameNames)}
  for i, name in ipairs(names) do
    local text = (i == selectionIndex + 1 and ">" or "") .. name
    love.graphics.print(text, 0, (i - 1) * 20)
  end
end

--------------------------------------------------
function love.keypressed(key, scancode, isrepeat)
  if key == "space" or key == "z" then
    if selectedGameInfo == nil then
      splore:loadGameLists(true)
    else
      splore:launchGame(selectedGameInfo.name)
    end
  end
  if key == "r" and selectedGameInfo ~= nil then
      splore:updateGame(selectedGameInfo.name)
  end

  local newIndex = nil
  if key == "up" and selectionIndex >= 1 then
    newIndex = selectionIndex - 1
  elseif key == "down" and selectionIndex < #gameNames then
    newIndex = selectionIndex + 1
  end
  if newIndex ~= nil then
    selectedGameInfo = splore:getGameInfo(gameNames[newIndex])
    selectionIndex = newIndex
  end
end
