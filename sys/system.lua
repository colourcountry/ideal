love.window.setMode(400,700,{fullscreen=false, resizable = true, highdpi = true}) -- Just to make the screen resizable, and this method works with HighDpi

lg = love.graphics
--lg.setDefaultFilter("nearest")

-- Various properties of the system.
units=4 --resolution of sprite atlases, in pixels per IDEAL unit
mode_panic_time = 999 -- if a mode is this old (in seconds) then it will automatically be restarted

lg.setLineWidth(units)

sprite_size=16
sprite_radius=sprite_size/2

atlases = {}
quads = {}
sprites = {
  unicode=require("atlas/cldr"),
  names=require("atlas/names")
}

api = require("sys/api")     -- Commands that proxy or use inaccessible Love/Lua functions
sugar = require("sys/sugar") -- Commands that could be done in the cart but are very common

carts={}
memory={}

-- remind myself which globals i define further down

cur_cart = nil
cur_cartid = nil -- this is available during cart load
cur_modes = {} -- register of modes defined in this cart
mode_end_time = nil

function add_quad_page(filename, hex)
  local tile_size = sprite_size * units
  local img = lg.newImage(filename)
  print("Loading quad-page "..hex.." from "..filename)
  for i=0,15 do
    for j=0,15 do
      local id=hex..string.format("%x%x",j,i)
      quads[tonumber(id,16)] = lg.newQuad(i*tile_size,j*tile_size,tile_size,tile_size,img:getDimensions())
      atlases[tonumber(id,16)] = img
    end
  end
end

local files = love.filesystem.getDirectoryItems("atlas/")
for k, file in ipairs(files) do
  local hex = file:match("([0-9a-f]+)[.]png")
  if hex then
	   add_quad_page("atlas/"..file, hex)
   end
end

colours = require("sys/colours")
white = colours[0]

cur_fg = colours[8]
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

function matrix_for_colour(c)
  return {
            {c[1], c[2], c[3], 0},
            {c[3], c[1], c[2], 0},
            {c[2], c[3], c[1], 0},
            {0, 0, 0, 1},
  }
end

cur_shader = lg.newShader(shader_code)
identity_matrix = matrix_for_colour({1,0,0})
lg.setShader(cur_shader)

function new_canvas(w, h)
  if w==0 or h==0 then return end
  local c = lg.newCanvas(w*units,h*units)
  return {
    w=w,
    h=h,
    start=function()
      lg.push("all")
      lg.setCanvas(c)
    end,
    stop=function()
      lg.pop()
    end,
    paste=function(_,x,y)
      lg.draw(c,(x or 0)*units,(y or 0)*units)
    end
  }
end

canvas = new_canvas(api.W,api.H)

function love.resize()
  screenW,screenH = lg.getDimensions()
  print("Using screen dimensions ",screenW,"x",screenH)
  scale = math.min((screenW-20)/(canvas.w*units) , (screenH-20)/(canvas.h*units))
  translateX = (screenW-scale*canvas.w*units)/2
  translateY = (screenH-scale*canvas.h*units)/2
end
love.resize()

function drawTimers()
  lg.setColor({1,0.5,0,1})
  local ut = update_time*screenH*60
  lg.rectangle("fill",0,0,4,ut)
  lg.setColor({0.6,0,0,1})
  local dt = draw_time*screenH*60
  lg.rectangle("fill",0,ut,4,dt)
end

function switch_cart(cartid,mode,secrets)
  cur_cartid = cartid
  cur_modes = {}
  api.LOG("Switching to",cur_cartid)
  cur_cart = get_cart(cur_cartid)
  if cur_cart.loaded then
    if mode and cur_modes[mode] then
      mode_end_time = false -- disable timer for special carts
      cur_mode = cur_modes[mode]
      if cur_mode.START then
        cur_mode:START(secrets)
      end
    else
      mode_end_time = love.timer.getTime()+mode_panic_time
      api.RESTART() -- restart safely
    end
  else
    api.ERROR(cur_cart)
  end
end

function love.update()
  update_time = love.timer.getTime()
  if mode_end_time and mode_end_time<update_time then
    api.LOG(update_time,": over ",mode_panic_time," seconds elapsed since mode began, panic!")
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
  cur_shader:send("transform",identity_matrix)
  cur_shader:send("bias",{0, 0, 0, 0})

  canvas:start()
  if cur_mode.DRAW then
    cur_mode:DRAW()
  end
  canvas:stop()

	lg.push("all") -- Push transformation state, The translate and scale will affect everything below until lg.pop()
	lg.translate( translateX, translateY ) -- Move to the appropriate top left corner
	lg.scale(scale,scale) -- Scale
  cur_shader:send("transform",identity_matrix) -- Identity transform
  cur_shader:send("bias",{0, 0, 0, 0})
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
    if cur_cart and cur_cart.SHUTDOWN then
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

function environment()
  local o = {}
  setmetatable(o, {__index=function(_,k)
    return api[k] or sugar[k]
  end
  })
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
