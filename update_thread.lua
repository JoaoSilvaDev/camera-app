local dir, channel = ...
local ch = love.thread.getChannel(channel)

local function sh(cmd)
  local h = io.popen("cd '" .. dir .. "' && " .. cmd .. " 2>/dev/null")
  local out = h:read("*a")
  h:close()
  return out
end

sh("timeout 10 git fetch --quiet origin main")
local n = tonumber(sh("git rev-list HEAD..origin/main --count")) or 0
ch:push(n)
