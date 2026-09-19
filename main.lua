local update = require("update")

local W, H = 640, 480
local box = { x = 80, y = 130, w = 480, h = 220 }
local yes = { x = 110, y = 270, w = 200, h = 60 }
local no  = { x = 330, y = 270, w = 200, h = 60 }

local debugText = "no input yet"  -- TEMP debug
local lastPress = nil             -- TEMP debug

local state = "idle"  -- idle | prompt | updating
local framesDrawn = 0

local function hit(r, x, y)
  return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

local function drawButton(r, label, color)
  love.graphics.setColor(color)
  love.graphics.rectangle("fill", r.x, r.y, r.w, r.h, 8, 8)
  love.graphics.setColor(1, 1, 1)
  love.graphics.printf(label, r.x, r.y + r.h / 2 - 8, r.w, "center")
end

local function drawPopup()
  -- dim the app behind the popup
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.rectangle("fill", 0, 0, W, H)

  love.graphics.setColor(0.15, 0.15, 0.18)
  love.graphics.rectangle("fill", box.x, box.y, box.w, box.h, 12, 12)
  love.graphics.setColor(1, 1, 1)

  if state == "updating" then
    love.graphics.printf("Updating...", box.x, box.y + 90, box.w, "center")
    return
  end
  love.graphics.printf("Update available!", box.x, box.y + 24, box.w, "center")
  if update.error then
    love.graphics.setColor(1, 0.5, 0.5)
    love.graphics.printf("Update failed:\n" .. update.error, box.x + 10, box.y + 60, box.w - 20, "center")
  else
    love.graphics.printf("Install it now?", box.x, box.y + 60, box.w, "center")
  end
  drawButton(yes, "Yes", { 0.2, 0.6, 0.3 })
  drawButton(no, "No", { 0.6, 0.25, 0.25 })
end

function love.load()
  love.mouse.setVisible(false)
  update.check()
end

function love.update(dt)
  update.poll()
  if state == "idle" and update.available then state = "prompt" end

  -- run the (blocking) pull only after the "Updating..." frame has been drawn
  if state == "updating" and framesDrawn >= 2 then
    update.apply()               -- quits with code 42 on success
    state = "prompt"             -- still here: it failed, update.error is set
  end
end

function love.draw()
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("Camera app v2", 10, 10)
  if state ~= "idle" then
    drawPopup()
    if state == "updating" then framesDrawn = framesDrawn + 1 end
  end

  -- TEMP debug: what input Love actually receives
  love.graphics.setColor(1, 1, 0)
  love.graphics.print(debugText, 10, H - 24)
  if lastPress then
    love.graphics.circle("line", lastPress.x, lastPress.y, 12)
  end
end

local function press(x, y)
  if state ~= "prompt" then return end
  if hit(yes, x, y) then
    update.error = nil
    framesDrawn = 0
    state = "updating"
  elseif hit(no, x, y) then
    update.dismiss()
    update.error = nil
    state = "idle"
  end
end

-- On the Pi, Love reports touch coordinates in screen pixels (measured at the
-- corners), so they go straight to press(). A touch may also arrive as a mouse
-- press; press() ignores repeats because it checks the state.
function love.mousepressed(x, y, button, istouch)
  debugText = string.format("mouse %d,%d touch=%s", x, y, tostring(istouch))
  lastPress = { x = x, y = y }
  press(x, y)
end

function love.touchpressed(id, x, y)
  debugText = string.format("touch %d,%d", x, y)
  lastPress = { x = x, y = y }
  press(x, y)
end
