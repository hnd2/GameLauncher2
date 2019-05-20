local commands = require("commands")
commands.verbose = true

local _M = {}


--------------------------------------------------
local function isModuleExist(moduleName)
  local status, _ = pcall(require, moduleName)
  return status
end


--------------------------------------------------
-- SploreInitOptions
-- @tfield[opt=nil] string gameListsPath Game lists path.
-- @tfield[opt=nil] string gamesPath Games path.
local SploreInitOptions = {
  gameListsPath = "splore/gameLists",
  gamesPath = "splore/games"
}

--------------------------------------------------
-- GameInfo
-- @table GameInfo
-- @tfield string name Game name.
-- @tfield string git Git URL.
-- @tfield[opt=nil] string rev Git revision.
-- @tfield[opt=nil] string thumbPath Game thumbnail path.
-- @tfield string gamePath Game file path.
-- @tfield Image thumb Game thumbnail image.
local GameInfo = {
  name = "",
  git = "",
  rev = nil,
  thumbPath = nil,
  gamePath = "",
  thumbImage = nil
}

--------------------------------------------------
function _M.new(options)
  -- merge options
  if options == nil then
    options = {}
  end
  for key, value in pairs(SploreInitOptions) do
    if options[key] == nil then
      options[key] = value
    end
  end

  local object = {
    gameListsPath = options.gameListsPath,
    gamesPath = options.gamesPath,
    gameLists = {},
    gameInfos = {}
  }

  -- mkdir
  commands.mkdir(object.gameListsPath)
  commands.mkdir(object.gamesPath)

  return setmetatable(object, {__index = _M})
end

local function getItemKey(list, item)
  for key, value in pairs(list) do
    if value == item then
      return key
    end
  end
  return nil
end

--------------------------------------------------
function _M:getGameNames()
  local names = {}
  for key, _ in pairs(self.gameInfos) do
    table.insert(names, key)
  end
  return names
end

--------------------------------------------------
function _M:getGameInfo(gameName)
  return self.gameInfos[gameName]
end

--------------------------------------------------
function _M:addGameList(str)
  if getItemKey(self.gameLists) == nil then
    table.insert(self.gameLists, str)
  end
end

--------------------------------------------------
function _M:removeGameList(str)
  local index = getItemIndex(self.gameLists)
  if index ~= nil then
    table.remove(self.gameLists, index)
  end
end

--------------------------------------------------
function _M:loadGameLists(pull)
  for _, list in ipairs(self.gameLists) do
    self:loadGameList(list, pull)
  end
end

--------------------------------------------------
function _M:loadGameList(str, pull)
  local isLocalFile = true
  local index = str:find("https://")
  if index ~= nil and index == 1 then
    isLocalFile = false
  end

  local moduleName = nil
  local gameListPath = nil

  if isLocalFile then
    -- load local list
    gameListPath = commands.getParentPath(str)
    moduleName = commands.splitString(str, ".lua")[1]
    moduleName = moduleName:gsub("/", ".")
  else
    -- load git list
    gameListPath = commands.splitString(str, "/")
    gameListPath = self.gameListsPath .. "/" .. gameListPath[#gameListPath]

    print("exist: ", commands.isDirectoryExist(gameListPath) == True)
    if not commands.isDirectoryExist(gameListPath) then
      -- clone
      if commands.gitClone(self.gameListsPath, str) ~= 0 then
        print("Failed to clone repository: " .. str)
        return
      end
    elseif pull then
      -- pull
      if commands.gitPull(gameListPath) ~= 0 then
        print("Failed to pull repository: " .. str)
        return
      end
    end
    moduleName = gameListPath .. ".list"
    moduleName = moduleName:gsub("/", ".")
  end

  local gameInfos = nil
  if isModuleExist(moduleName) then
    gameInfos = require(moduleName)
  end
  if gameInfos == nil then
    return
  end

  -- set game info
  for _, gameInfo in ipairs(gameInfos) do
    if gameInfo.git ~= nil then
      local gamePath = commands.splitString(gameInfo.git, "/")
      gamePath = self.gamesPath .. "/" .. gamePath[#gamePath]
      gameInfo.gamePath = gamePath

      if gameInfo.thumbPath ~= nil then
        local thumbPath = gameListPath .. "/" .. gameInfo.thumbPath
        if love.filesystem.getInfo(thumbPath, "file") then
          gameInfo.thumbImage = love.graphics.newImage(thumbPath)
        end
      end
      self.gameInfos[gameInfo.name] = gameInfo
    end
  end
end

--------------------------------------------------
function _M:updateGame(gameName)
  local gameInfo = self.gameInfos[gameName]
  if gameName == nil then
    print(gameName .. "not found")
    return
  end

  if not commands.isDirectoryExist(gameInfo.gamePath) then
    -- clone
    local parentPath = commands.getParentPath(gameInfo.gamePath)
    if commands.gitClone(parentPath, gameInfo.git) ~= 0 then
      print("Failed to clone repository: " .. gameName)
      return
    end
  else
    -- pull
    if commands.gitPull(gameInfo.gamePath) ~= 0 then
      print("Failed to pull repository: " .. gameName)
      return
    end
  end

  -- run install script
  local scriptFilePath = gameInfo.gamePath .. "/install.sh"
  if commands.isFileExist(scriptFilePath) then
    commands.runScriptFile(scriptFilePath)
  end
end

--------------------------------------------------
function _M:launchGame(gameName)
  local gameInfo = self.gameInfos[gameName]
  if gameName == nil then
    print(gameName .. "not found")
    return
  end

  if not commands.isDirectoryExist(gameInfo.gamePath) then
    self:updateGame(gameName)
    print("udpated")
  end
  if commands.love(gameInfo.gamePath) == 0 then
    love.event.quit()
  end
end

return _M
