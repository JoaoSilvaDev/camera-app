local dir, channel = ...
local ch = love.thread.getChannel(channel)

-- run a shell command in the app dir; returns its output and exit code
local function sh(cmd)
  local h = io.popen("cd '" .. dir .. "' && " .. cmd .. "; echo \"EXIT:$?\"")
  local out = h:read("*a")
  h:close()
  local code = tonumber(out:match("EXIT:(%d+)%s*$"))
  local body = out:gsub("EXIT:%d+%s*$", "")
  return body, code
end

local _, fetchCode = sh("timeout 10 git fetch --quiet origin main 2>/dev/null")
if fetchCode ~= 0 then
  ch:push({ ok = false })  -- couldn't reach the remote (offline, no Wi-Fi, ...)
  return
end

local out = sh("git rev-list HEAD..origin/main --count 2>/dev/null")
ch:push({ ok = true, behind = tonumber(out) or 0 })
