love.window.setMode(400,700,{fullscreen=false, resizable = true, highdpi = true}) -- Just to make the screen resizable, and this method works with HighDpi

lg = love.graphics
--lg.setDefaultFilter("nearest")

-- Various properties of the system.
units=4 --convert in-world units (144x240) to pre-scaling screen coords
mode_panic_time = 600 -- if a mode is this old (in seconds) then it will automatically be restarted

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

-- remind myself which globals i define further down

cur_cart = nil
cur_cartid = nil -- this is available during cart load
cur_modes = {} -- register of modes defined in this cart
mode_start_time = nil

function add_quad_page(hex)
  local tile_size = sprite_size * units
  local img = lg.newImage("atlas/"..hex..".png")
  for i=0,15 do
    for j=0,15 do
      local id=hex..string.format("%x%x",j,i)
      quads[tonumber(id,16)] = lg.newQuad(i*tile_size,j*tile_size,tile_size,tile_size,img:getDimensions())
      atlases[tonumber(id,16)] = img
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
  {0.8, 1, 0, 1},
  {0, 1, 0, 1},
  {0, 1, 0.8, 1},
  {0, 0.8, 1, 1},
  {0, 0.3, 1, 1},
  {0.5, 0, 1, 1},
  {1, 0, 0.5, 1},
  {1, 0.3, 0, 1},
  {1, 0.6, 0, 1},
  {1, 0.9, 0, 1},
  {0, 0, 0, 1}
}
colours[0] = white

cur_fg = colours[0]
cur_bg = colours[11] -- TODO: remove
cur_mode = "unset"
cur_touches = {}
mouse_touch_id = "MOUSE"
twinkle = 0

shader_code = [[
        extern mat4 transform;
        extern vec4 bias;

        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
        {
                vec4 fragment_color = Texel(texture, texture_coords);
                return fragment_color * transform + bias;
        }
]]

function matrix_for_colour(r,g,b)
  return {
            {r, g, b, 0},
            {b, r, g, 0},
            {g, b, r, 0},
            {0, 0, 0, 1},
  }
end

function new_canvas(w, h)
  if w==0 or h==0 then return end
  local c = lg.newCanvas(w*units,h*units)
  local s = lg.newShader(shader_code)
  s:send("transform",matrix_for_colour(1,0,0))
  s:send("bias",{0, 0, 0, 0})
  return {
    w=w,
    h=h,
    start=function()
      lg.push("all")
      lg.setShader(s)
      lg.setCanvas(c)
    end,
    stop=function()
      lg.pop()
    end,
    paste=function()
      lg.draw(c,0,0)
    end,
    colour=function(r,g,b)
      s:send("transform",matrix_for_colour(r,g,b))
    end
  }
end

canvas = new_canvas(api.W,api.H)

function love.resize()
  print("Resizing!")
  screenW,screenH = lg.getDimensions()
  print("Using screen dimensions ",screenW,"x",screenH)
  scale = math.min((screenW-20)/(canvas.w*units) , (screenH-20)/(canvas.h*units))
  translateX = (screenW-scale*canvas.w*units)/2
  translateY = (screenH-scale*canvas.h*units)/2
end
love.resize()

function drawTimers()
  local ut = update_time*screenH*60
  lg.setColor({0,0,0,1})
  local dt = draw_time*screenH*60
  lg.rectangle("fill",0,ut,4,dt)
end

function switch_cart(cartid)
  cur_cartid = cartid
  cur_modes = {}
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
  if mode_start_time and mode_start_time+mode_panic_time<update_time then
    api.LOG(update_time,": ",mode_panic_time," seconds elapsed since mode began, panic!")
    api.RESET()
  end
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
  twinkle = 0
  --lg.setColor(100,0,100)
  --lg.circle("fill", screenW, screenH, api.T%screenH)
  --lg.setColor(100,100,0)
  --lg.circle("fill", 0, 0, api.T%screenH)
  lg.setColor(255,255,255)
  canvas:start()
  if cur_mode.DRAW then
    cur_mode:DRAW()
  end
  canvas:stop()
	lg.push("all") -- Push transformation state, The translate and scale will affect everything below until lg.pop()
	lg.translate( translateX, translateY ) -- Move to the appropriate top left corner
	lg.scale(scale,scale) -- Scale
  canvas:paste()
	lg.pop() -- pop transformation state
  api.T = api.T + 1
  draw_time = love.timer.getTime() - draw_time
  drawTimers()
end

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
    api.RELEASE(mox,moy,mx,my)
  else
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
  environment=environment,
  new_canvas=new_canvas
}
