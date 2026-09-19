local M = { available = false, error = nil }
local dir = love.filesystem.getSource()
local channel = "update-result"

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
