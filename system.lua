love.window.setMode(800,600,{fullscreen=false, resizable = true, highdpi = true}) -- Just to make the screen resizable, and this method works with HighDpi
--love.graphics.setDefaultFilter("nearest")
screenW,screenH = love.graphics.getDimensions()
units=4 --convert in-world units (144x240) to pre-scaling screen coords

love.graphics.setLineWidth(units)

system_font=love.graphics.newImageFont("nemo91font.png",
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789- .,@")
system_font_size=6

sprite_size=16
sprite_radius=sprite_size/2

atlases = {}
quads = {}

function add_quad_page(hex)
  local tile_size = sprite_size * units
  local img = love.graphics.newImage("atlas/"..hex..".png")
  for i=0,15 do
    for j=0,15 do
      local id=hex..string.format("%x%x",j,i)
      quads[id] = love.graphics.newQuad(i*tile_size,j*tile_size,tile_size,tile_size,img:getDimensions())
      atlases[id] = img
    end
  end
end

add_quad_page("1f3")
add_quad_page("1f4")
add_quad_page("1f5")
add_quad_page("1f6")
add_quad_page("1f9")
add_quad_page("1fa")
add_quad_page("26")

sys = {
  api = require("api"),
  carts={}
}

white = {1, 1, 1, 1}
colours = {
  {0.8, 1, 0.5, 1},
  {0.5, 1, 0.5, 1},
  {0.5, 1, 0.9, 1},
  {0.5, 0.8, 1, 1},
  {0.5, 0.5, 1, 1},
  {0.8, 0.5, 1, 1},
  {1, 0.5, 0.8, 1},
  {1, 0.3, 0.5, 1},
  {1, 0.6, 0.5, 1},
  {1, 0.9, 0.5, 1},
  {0, 0, 0, 1}
}
colours[0] = white

cur_fg = colours[0]
cur_bg = colours[11]
cur_mode = "unset"
twinkle = 0

unitW = sys.api.W*units
unitH = sys.api.H*units
canvas = love.graphics.newCanvas(unitW,unitH)
scale = math.min((screenW-20)/sys.api.W , (screenH-20)/unitH) -- Scale to the nearest integer
translateX = math.floor((screenW - unitW * scale)/2)
translateY = math.floor((screenH - unitH * scale)/2)

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
  sys.api.T = sys.api.T + 1
end

function sys.get_cart(cartid)
  return nil -- override this in main
end

function sys.switch_cart(cartid)
  sys.api.LOG("Switching to",cartid)
  cart = sys.get_cart(cartid)
  if cart.loaded then
    sys.api.RESTART()
  else
    sys.api.ERROR(cart)
  end
end

function love.update()
  update_time = love.timer.getTime()
  if (cur_mode.frame) then
    cur_mode:frame()
  end
  if (love.mouse.isDown(1, 2, 3)) then
    handle_touch(love.mouse.getX(), love.mouse.getY(), false)
  end
  touches = love.touch.getTouches()
  for k, v in pairs(touches) do
    local x, y = love.touch.getPosition(v)
    handle_touch(x,y,false)
  end
  if cur_mode.UPDATE then
    cur_mode:UPDATE()
  end
  update_time = love.timer.getTime() - update_time
end

function love.draw()
  draw_time = love.timer.getTime()
  draw()
  if cur_mode.DRAW then
    cur_mode:DRAW()
  end
  flush()
  draw_time = love.timer.getTime() - draw_time
  drawTimers()
end

-- Keys emulate touches. There is no NEMO-83 API for actual keys.
keys = {
  right={sys.api.W, sys.api.H/2},
  left={0, sys.api.H/2},
  down={sys.api.W/2, sys.api.H},
  up={sys.api.W/2, 0},
}
keys['return'] = {sys.api.W/2,sys.api.H/2}

function love.keypressed(key, scancode, isRepeat)
  if (scancode=='escape') then
    if cart.SHUTDOWN then
      cart:SHUTDOWN()
    end
    sys.api.EXIT()
  end
  local k = keys[scancode]
  if (k and cur_mode.TOUCH) then
    cur_mode.TOUCH(math.floor(k[1]), math.floor(k[2]), true)
  end
  if cur_mode.KEY then
    cur_mode:KEY(scancode)
  end
end

function love.touchpressed( id, x, y, dx, dy, pressure )
  handle_touch(x,y,true)
end

function love.touchreleased( id, x, y, dx, dy, pressure)
  handle_touch(x,y,false,true)
end

function handle_touch(x,y,isNew,isRelease)
  local mx = (x-translateX)/scale/units
  local my = (y-translateY)/scale/units
  sys.api.TOUCH(mx,my,isNew,isRelease)
end

function love.mousepressed( x, y, button, istouch, presses )
  if not istouch then
    handle_touch(x,y,true)
  end
end

function love.mousereleased( x, y, button, istouch, presses )
  if not istouch then
    handle_touch(x,y,false,true)
  end
end

sys.api.__index = sys.api

function sys.environment()
  local o = {}
  setmetatable(o, sys.api)
  return o
end

return sys
