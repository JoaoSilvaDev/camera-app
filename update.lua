-- status: idle | checking | uptodate | available | offline
local M = { available = false, error = nil, status = "idle" }
local dir = love.filesystem.getSource()
local channel = "update-result"

-- run a shell command in the app dir; returns its output and exit code
local function sh(cmd)
  local h = io.popen("cd '" .. dir .. "' && " .. cmd .. "; echo \"EXIT:$?\"")
  local out = h:read("*a")
  h:close()
  local code = tonumber(out:match("EXIT:(%d+)%s*$"))
  local body = out:gsub("EXIT:%d+%s*$", "")
  return body, code
end

-- short id of the commit currently checked out ("unknown" if not a git repo)
function M.version()
  local out = sh("git rev-parse --short HEAD 2>/dev/null"):gsub("%s+", "")
  return out ~= "" and out or "unknown"
end

function M.check()
  if M.thread and M.thread:isRunning() then return end
  M.status = "checking"
  M.thread = love.thread.newThread("update_thread.lua")
  M.thread:start(dir, channel)
end

function M.poll()  -- call every frame from love.update
  local res = love.thread.getChannel(channel):pop()
  if not res then return end
  if not res.ok then
    M.status = "offline"
  elseif res.behind > 0 then
    M.status = "available"
    M.available = true
  else
    M.status = "uptodate"
  end
end

function M.dismiss() M.available = false end

function M.apply()
  local out, code = sh("git pull --ff-only 2>&1")
  if code == 0 then
    love.event.quit(42)  -- systemd restarts on exit code 42
  else
    M.error = out  -- show it in the dialog
  end
end

return M
