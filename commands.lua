local _M = {
  osName = "",
  verbose = false
}

local fh = io.popen("uname", "r")
if fh then
  _M.osName = fh:read()
end

--------------------------------------------------
local function abspath(path)
  return love.filesystem.getSource() .. "/" .. path
end

--------------------------------------------------
function _M.execute(command)
  if string.find(_M.osName, "windows") then
    command = "powershell " .. command
  end
  if _M.verbose then
    print(command)
  end
  return os.execute(command)
end

--------------------------------------------------
function _M.mkdir(dirname)
  local command = "mkdir -p " .. abspath(dirname)
  return _M.execute(command)
end

--------------------------------------------------
function _M.isFileExist(filename)
  local command = "test -f " .. abspath(filename)
  if _M.execute(command) == 0 then
    return true
  end
  return false
end

--------------------------------------------------
function _M.isDirectoryExist(dirname)
  local command = "test -d " .. abspath(dirname)
  if _M.execute(command) == 0 then
    return true
  end
  return false
end


--------------------------------------------------
function _M.gitClone(path, url)
  local command = "cd " .. abspath(path) .. ";" .. "git clone " .. url
  return _M.execute(command)
end

--------------------------------------------------
function _M.gitPull(path)
  local command = "cd " .. abspath(path) .. ";" .. "git pull"
  return _M.execute(command)
end

--------------------------------------------------
function _M.gitCheckout(path, rev)
  local command = "cd " .. abspath(path) .. ";" .. "git checkout " .. rev
  return _M.execute(command)
end

--------------------------------------------------
function _M.love(path)
  local command = "cd " .. abspath(path) .. ";" .. "love . &"
  return _M.execute(command)
end

return _M
