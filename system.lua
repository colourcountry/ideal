love.window.setMode(400,700,{fullscreen=false, resizable = true, highdpi = true}) -- Just to make the screen resizable, and this method works with HighDpi

lg = love.graphics
--lg.setDefaultFilter("nearest")

-- Various properties of the system.
screenW,screenH = lg.getDimensions()
units=4 --convert in-world units (144x240) to pre-scaling screen coords

lg.setLineWidth(units)

system_font=lg.newImageFont("nemo91font.png",
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789- .,@")
system_font_size=6

sprite_size=16
sprite_radius=sprite_size/2

atlases = {}
quads = {}
sprites = require("sprites")

api = require("api")
carts={}

memory={}

cur_cart = nil
cur_cartid =  nil -- this is available during cart load

function add_quad_page(hex)
  local tile_size = sprite_size * units
  local img = lg.newImage("atlas/"..hex..".png")
  for i=0,15 do
    for j=0,15 do
      local id=hex..string.format("%x%x",j,i)
      quads[id] = lg.newQuad(i*tile_size,j*tile_size,tile_size,tile_size,img:getDimensions())
      atlases[id] = img
    end
  end
end

quad_pages = { "00", -- Basic font
               "1f1", "1f2", "1f3", "1f4", "1f5", "1f6",
               "1f7", "1f9", "1fa", "20", "21", "22", "23", "24",
               "26", "27", "29", "2b", -- emoji and symbols from Google
               "25", -- Border box characters
               "f00" -- (PUA) Wall tiles
             }
for i=1,#quad_pages do
  add_quad_page(quad_pages[i])
end

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
cur_touches = {}
mouse_touch_id = "MOUSE"
twinkle = 0

canvasW = api.W*units
canvasH = api.H*units
canvas = lg.newCanvas(canvasW,canvasH)
scale = math.min((screenW-20)/canvasW , (screenH-20)/canvasH) -- Scale to the nearest integer
translateX = (screenW-canvasW*scale)/2
translateY = (screenH-canvasH*scale)/2

function drawTimers()
  local ut = update_time*screenH*60
  lg.setColor({0,0,0,1})
  local dt = draw_time*screenH*60
  lg.rectangle("fill",0,ut,4,dt)
end

function switch_cart(cartid)
  cur_cartid = cartid
  api.LOG("Switching to",cur_cartid)
  cur_cart = get_cart(cur_cartid)
  if cur_cart.loaded then
    api.RESTART()
  else
    api.ERROR(cur_cart)
  end
end

function love.update()
  update_time = love.timer.getTime()
  if (cur_mode.frame) then
    cur_mode:frame()
  end
  if (love.mouse.isDown(1, 2, 3)) then
    handle_drag(mouse_touch_id,love.mouse.getX(),love.mouse.getY())
  end
  touches = love.touch.getTouches()
  for id, v in pairs(touches) do
    local x,y = love.touch.getPosition(v)
    handle_drag(id,x,y)
  end
  if cur_mode.UPDATE then
    cur_mode:UPDATE()
  end
  update_time = love.timer.getTime() - update_time
end

function love.draw()
  draw_time = love.timer.getTime()
  lg.setFont(system_font)
  lg.setColor(cur_fg)
  lg.setCanvas(canvas)
  twinkle = 0
  if cur_mode.DRAW then
    cur_mode:DRAW()
  end
  lg.setCanvas() -- Set rendering to the screen
	lg.push() -- Push transformation state, The translate and scale will affect everything below until lg.pop()
	lg.translate( translateX, translateY ) -- Move to the appropiate top left corner
	lg.scale(scale,scale) -- Scale
  lg.setColor(white)
	lg.draw(canvas,0,0) -- Draw the canvas
	lg.pop() -- pop transformation state
  api.T = api.T + 1
  draw_time = love.timer.getTime() - draw_time
  drawTimers()
end

-- Keys emulate touches. There is no NEMO-83 API for actual keys.
keys = {
  right={api.W, api.H/2},
  left={0, api.H/2},
  down={api.W/2, api.H},
  up={api.W/2, 0},
}
keys['return'] = {api.W/2,api.H/2}

function love.keypressed(key, scancode, isRepeat)
  if (scancode=='escape') then
    if cur_cart.SHUTDOWN then
      cur_cart:SHUTDOWN()
    end
    api.EJECT()
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
  handle_touch(id,x,y)
end

function love.touchreleased( id, x, y, dx, dy, pressure)
  handle_release(id,x,y)
end

function handle_touch(id,x,y)
  cur_touches[id] = {
    x=x, y=y,
    ox=x, oy=y
  }
  local mx = (cur_touches[id].x-translateX)/scale/units
  local my = (cur_touches[id].y-translateY)/scale/units
  api.LOG("New touch",id,"currently",cur_touches)
  api.TOUCH(mx,my)
end

function handle_drag(id,x,y)
  if cur_touches[id] then
    cur_touches[id].x = x
    cur_touches[id].y = y
  else
    cur_touches[id] = {
      x=x, y=y,
      ox=x, oy=y
    }
  end
  local mx = (x-translateX)/scale/units
  local my = (y-translateY)/scale/units
  local mox = (cur_touches[id].ox-translateX)/scale/units
  local moy = (cur_touches[id].oy-translateY)/scale/units
  api.DRAG(mox,moy,mx,my)
end

function handle_release(id,x,y)
  local mx = (x-translateX)/scale/units
  local my = (y-translateY)/scale/units
  if cur_touches[id] then
    local mox = (cur_touches[id].ox-translateX)/scale/units
    local moy = (cur_touches[id].oy-translateY)/scale/units
    api.LOG("Releasing touch id",id)
    api.RELEASE(mox,moy,mx,my)
  else
    api.LOG("Releasing unknown touch id",id)
    api.RELEASE(mx,my,mx,my)
  end
  cur_touches[id] = nil
end

function love.mousepressed( x, y, button, istouch, presses )
  if not istouch then
    handle_touch(mouse_touch_id,x,y)
  end
end

function love.mousereleased( x, y, button, istouch, presses )
  if not istouch then
    handle_release(mouse_touch_id,x,y)
  end
end

api.__index = api

function environment()
  local o = {}
  local apikeys = {}
  for k, v in pairs(api) do
    apikeys[#apikeys] = k
  end
  api.LOG("Set up new environment with metatable",apikeys)
  setmetatable(o, api)
  return o
end

-- this is all that is exposed to main
return {
  carts=carts,
  api=api,
  sprites=sprites,
  memory=memory,
  switch_cart=switch_cart,
  environment=environment(),
}
