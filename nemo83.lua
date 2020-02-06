love.window.setMode(800,600,{fullscreen=false, resizable = true, highdpi = true}) -- Just to make the screen resizable, and this method works with HighDpi
--love.graphics.setDefaultFilter("nearest")
screenW,screenH = love.graphics.getDimensions()

system_font=love.graphics.newImageFont("nemo91font.png",
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789- .,@")
system_font_size=24
system_line_height=24

sprite_font=love.graphics.newImageFont("nemo83sprites.png",
    " @BoA")
sprite_font_size=16

n = {
  api = require("api"),
  carts={}
}

white = {1, 1, 1, 1}
colours = {
  {1, 0.5, 0.5, 1},
  {1, 0.8, 0.5, 1},
  {1, 1, 0.5, 1},
  {0.8, 1, 0.5, 1},
  {0.5, 1, 0.5, 1},
  {0.5, 1, 1, 1},
  {0.5, 0.8, 1, 1},
  {0.5, 0.5, 1, 1},
  {0.8, 0.5, 1, 1},
  {1, 0.5, 0.8, 1},
  {0, 0, 0, 1}
}
colours[0] = white

cur_fg = colours[0]
cur_bg = colours[11]
cur_mode = "unset"
twinkle = 0

canvas = love.graphics.newCanvas(n.api.W,n.api.H)
scale = math.min((screenW-20)/n.api.W , (screenH-20)/n.api.H) -- Scale to the nearest integer
translateX = math.floor((screenW - n.api.W * scale)/2)
translateY = math.floor((screenH - n.api.H * scale)/2)

function draw()
  love.graphics.setFont(system_font)
  love.graphics.setColor(cur_fg)
  love.graphics.setCanvas(canvas)
  twinkle = 0
end

function drawTimers()
  local ut = update_time*screenH*60
  love.graphics.setColor({0,0,0,1})
  local dt = draw_time*screenH*60
  love.graphics.rectangle("fill",0,ut,4,dt)
end

function flush()
  love.graphics.setCanvas() -- Set rendering to the screen
	love.graphics.push() -- Push transformation state, The translate and scale will affect everything below until love.graphics.pop()
	love.graphics.translate( translateX, translateY ) -- Move to the appropiate top left corner
	love.graphics.scale(scale,scale) -- Scale
  love.graphics.setColor(white)
	love.graphics.draw(canvas) -- Draw the canvas
	love.graphics.pop() -- pop transformation state
  n.api.T = n.api.T + 1
end

function n.get_cart(cartid)
  return nil -- override this in main
end

function n.switch_cart(cartid)
  n.api.LOG("Switching to",cartid)
  cart = n.get_cart(cartid)
  n.api.RESTART()
end

function love.update()
  update_time = love.timer.getTime()
  if (cart[cur_mode].frame) then
    cart[cur_mode]:frame()
  end
  if (love.mouse.isDown(1, 2, 3)) then
    n.api.TOUCH(love.mouse.getX(), love.mouse.getY(), false)
  end
  touches = love.touch.getTouches()
  for k, v in pairs(touches) do
    local x, y = love.touch.getPosition(v)
    n.api.TOUCH(x, y, false)
  end
  if not cart[cur_mode] then
    n.api.DIE("mode "..cur_mode.." is not defined")
  end
  if (cart[cur_mode].update) then
    cart[cur_mode]:update()
  end
  update_time = love.timer.getTime() - update_time
end

function love.draw()
  draw_time = love.timer.getTime()
  draw()
  if (cart[cur_mode].draw) then
    cart[cur_mode]:draw()
  end
  flush()
  draw_time = love.timer.getTime() - draw_time
  drawTimers()
end

-- Keys emulate touches. There is no NEMO-83 API for actual keys.
keys = {
  right={n.api.W, n.api.H/2},
  left={0, n.api.H/2},
  down={n.api.W/2, n.api.H},
  up={n.api.W/2, 0},
}
keys['return'] = {n.api.W/2,n.api.H/2}

function love.keypressed(key, scancode, isRepeat)
  if (scancode=='escape') then
    if cart.shutdown then
      cart:shutdown()
    end
    n.api.EXIT()
  end
  local k = keys[scancode]
  if (k and cart[cur_mode].touch) then
    cart[cur_mode]:touch(math.floor(k[1]), math.floor(k[2]), true)
  end
end

function love.touchpressed( id, x, y, dx, dy, pressure )
  n.api.TOUCH(x,y,true)
end

function love.mousepressed( x, y, button, istouch, presses )
  if not istouch then
    n.api.TOUCH(x,y,true)
  end
end

n.api.__index = n.api

function n.environment()
  local o = {}
  setmetatable(o, n.api)
  return o
end

return n
