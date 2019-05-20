local OsType = {
  Windows = "windows",
  MacOs = "macOs",
  Linux = "linux",
  Unknown = "unknown",
}

local _M = {
  osName = "",
  osType = OsType.Unknown,
  verbose = false
}

local fh = io.popen("uname", "r")
if fh then
  _M.osName = fh:read()
  if string.find(_M.osName, "windows") then
    _M.osType = OsType.Windows
  elseif string.find(_M.osName, "mac") then
    _M.osType = OsType.MacOs
  elseif string.find(_M.osName, "linux") then
    _M.osType = OsType.Linux
  end
end

--------------------------------------------------
function _M.splitString(str, div)
  local o = {}
  while true do
    local pos1, pos2 = str:find(div)
    if not pos1 then
      o[#o + 1] = str
      break
    end
    o[#o + 1], str = str:sub(1, pos1 - 1), str:sub(pos2 + 1)
  end
  return o
end

--------------------------------------------------
function _M.abspath(path)
  return love.filesystem.getSource() .. "/" .. path
end

--------------------------------------------------
function _M.getParentPath(path)
  local segments = _M.splitString(path, "/")
  local result = nil
  for i, segment in ipairs(segments) do
    if i == 1 then
      result = segment
    elseif i ~= #segments then
      result = result .. "/" .. segment
    end
  end
  return result
end

--------------------------------------------------
function _M.execute(command)
  if _M.osType == OsType.Windows then
    command = "powershell " .. command
  end
  if _M.verbose then
    print(command)
  end
  return os.execute(command)
end

--------------------------------------------------
function _M.popen(command)
  if _M.osType == OsType.Windows then
    command = "powershell " .. command
  end
  if _M.verbose then
    print(command)
  end
  local handle = io.popen(command, "r")
  local result = handle:read("*a")
  handle:close()

  return result
end

--------------------------------------------------
function _M.runScriptFile(scriptFilePath)
  local parentDirPath = _M.getParentPath(scriptFilePath)
  local command = "cd " .. parentDirPath .. ";"
  if _M.osType == OsType.Windows then
    command = "powershell bash " .. scriptFilePath
  else
    command = command .. scriptFilePath
  end
  if _M.verbose then
    print(command)
  end
  return _M.execute(command)
end

--------------------------------------------------
function _M.mkdir(dirname)
  local command =  _M.abspath(dirname)
  if _M.osType == OsType.Windows then
    command = "New-Item -ItemType Directory -Force -Path " .. command
  else
    command = "mkdir -p " .. command
  end
  return _M.execute(command)
end

--------------------------------------------------
function _M.isFileExist(filename)
  local command =  _M.abspath(filename)
  if _M.osType == OsType.Windows then
    command = "Test-Path " .. command
    if string.find(_M.popen(command), "True") then
      return true
    end
  else
    command = "test -f " .. command
    if _M.execute(command) == 0 then
      return true
    end
  end
  return false
end

--------------------------------------------------
function _M.isDirectoryExist(dirname)
  local command =  _M.abspath(dirname)
  if _M.osType == OsType.Windows then
    command = "Test-Path -Path " .. command
    if string.find(_M.popen(command), "True") then
      return true
    end
  else
    command = "test -d " .. command
    if _M.execute(command) == 0 then
      return true
    end
  end
  return false
end


--------------------------------------------------
function _M.gitClone(path, url)
  local command = "cd " .. _M.abspath(path) .. ";" .. "git clone " .. url
  return _M.execute(command)
end

--------------------------------------------------
function _M.gitPull(path)
  local command = "cd " .. _M.abspath(path) .. ";" .. "git pull"
  return _M.execute(command)
end

--------------------------------------------------
function _M.gitCheckout(path, rev)
  local command = "cd " .. _M.abspath(path) .. ";" .. "git checkout " .. rev
  return _M.execute(command)
end

--------------------------------------------------
function _M.love(path)
  local command = "cd " .. _M.abspath(path) .. ";" .. "love . &"
  return _M.execute(command)
end

return _M
