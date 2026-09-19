local M = { available = false, error = nil }
local dir = love.filesystem.getSource()
local channel = "update-result"

-- short id of the commit currently checked out ("unknown" if not a git repo)
function M.version()
  local h = io.popen("cd '" .. dir .. "' && git rev-parse --short HEAD 2>/dev/null")
  local out = h:read("*a"):gsub("%s+", "")
  h:close()
  return out ~= "" and out or "unknown"
end

function M.check()
  M.thread = love.thread.newThread("update_thread.lua")
  M.thread:start(dir, channel)
end

function M.poll()  -- call every frame from love.update
  local n = love.thread.getChannel(channel):pop()
  if n and n > 0 then M.available = true end
end

function M.dismiss() M.available = false end

function M.apply()
  local h = io.popen("cd '" .. dir .. "' && git pull --ff-only 2>&1")
  local out = h:read("*a")
  local ok = h:close()
  if ok then
    love.event.quit(42)  -- systemd restarts on exit code 42
  else
    M.error = out  -- show it in the dialog
  end
end

return M
