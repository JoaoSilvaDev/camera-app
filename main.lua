local update = require("update")

function love.load()
  love.mouse.setVisible(false)
  update.check()
end

function love.update(dt) update.poll() end

function love.draw()
  love.graphics.print("Camera app v1", 10, 10)
  if update.available then
    love.graphics.print("UPDATE AVAILABLE!", 10, 30)
  else
    love.graphics.print("NO UPDATE", 10, 30)
  end
end

function love.keypressed(k)
  if update.available then
    if k == "return" then update.apply()
    elseif k == "escape" then update.dismiss() end
  end
end
