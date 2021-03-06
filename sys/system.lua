love.window.setMode(400,700,{fullscreen=false, resizable = true, highdpi = true}) -- Just to make the screen resizable, and this method works with HighDpi

lg = love.graphics
--lg.setDefaultFilter("nearest")

-- Various properties of the system.
units=4 --resolution of sprite atlases, in pixels per IDEAL unit
mode_panic_time = 999 -- if a mode is this old (in seconds) then it will automatically be restarted
trainer=false -- if you press a key - since games aren't supposed to use keys

lg.setLineWidth(units)

sprite_size=16
sprite_radius=sprite_size/2
touch_offset_x = 0
touch_offset_y = -sprite_size -- move touch up the screen a little to match perception when held

atlases = {}
quads = {}
sprites = {
  unicode=require("atlas/cldr"),
  names=require("atlas/names")
}

colours = require("sys/colours")
white = colours[0]

api = require("sys/api")     -- Commands that proxy or use inaccessible Love/Lua functions
sugar = require("sys/sugar") -- Commands that could be done in the cart but are very common

carts={}
memory={}
debug_logs = {}

-- remind myself which globals i define further down

cur_cart = nil
cur_cartid = nil -- this is available during cart load
cur_modes = {} -- register of modes defined in this cart
mode_end_time = nil
debug_scancode = "" -- whatever key was pressed last

frame_rate = 1/30
frame_remain = 0

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

cur_touches = {}
mouse_touch_id = "MOUSE"
twinkle = 0
cur_fg = colours[8]

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

function switch_mode(mode,secrets)
  cur_mode = mode
  api.LOG("Switch to mode",cur_mode)
  if secrets then
    mode_end_time = false -- disable timer for special carts
  else
    mode_end_time = love.timer.getTime()+mode_panic_time
  end
  if cur_mode.START then
    cur_mode:START(secrets)
  end
end

function switch_cart(cartid,modename,secrets)
  cur_cartid = cartid
  cur_modes = {}
  api.LOG("Switch to cart",cur_cartid,modename,secrets)
  cur_cart = get_cart(cur_cartid)
  if cur_cart.loaded then
    local new_mode = cur_modes[modename] or cur_cart.start
    switch_mode(new_mode,secrets)
  else
    api.ERROR(cur_cartid)
  end
end

function love.update()
  update_time = love.timer.getTime()
  debug_logs = {}
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
  for i, id in pairs(touches) do
    local x,y = love.touch.getPosition(id)
    handle_drag(id,x+touch_offset_x,y+touch_offset_y)
  end

  frame_remain = frame_remain + love.timer.getDelta()
  while frame_remain > frame_rate do
    if cur_mode.UPDATE then
      cur_mode:UPDATE()
    end
    frame_remain = frame_remain - frame_rate
    api.T = api.T + 1
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

  if trainer then
    draw_time = love.timer.getTime() - draw_time
    drawTimers()
    local screenW,screenH = lg.getDimensions()
    lg.printf("d e v e l o p m e n t   m o d e",0,screenH/3,screenW,"center")
    lg.printf(debug_scancode,0,screenH/4,screenW,"center")

    y = screenH/2
    for i=1,#debug_logs do
      lg.print(debug_logs[i],0,y)
      y=y+12
    end

    for k,v in pairs(cur_touches) do
      lg.print("Touch "..tostring(k)..": "..math.floor(v.ox)..","..math.floor(v.oy).." -> "..math.floor(v.x)..","..math.floor(v.y),0,y)
      y=y+12
    end
  end
end

keys = {
  right={api.W, api.H/2},
  left={0, api.H/2},
  down={api.W/2, api.H},
  up={api.W/2, 0},
  ['return']={api.W/2,api.H/2},
}

function love.keypressed(key, scancode, isRepeat)
  if (scancode=='escape' or scancode=='acback') then
    if cur_mode.ESCAPE then
      cur_mode:ESCAPE()
    else
      api.EJECT()
    end
    return
  end
  local k = keys[scancode]
  if (k and cur_mode.TOUCH) then
    cur_mode:TOUCH(math.floor(k[1]), math.floor(k[2]), true)
    return
  end
  trainer = true -- unapproved key
  debug_scancode = scancode
  if cur_mode.KEY then
    local r = cur_mode:KEY(scancode)
    if not r then
      api.LOG("Key had no effect:",scancode)
    end
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
