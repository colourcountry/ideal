love.window.setMode(800,600,{fullscreen=false, resizable = true, highdpi = true}) -- Just to make the screen resizable, and this method works with HighDpi
love.graphics.setDefaultFilter("nearest")
screenW,screenH = love.graphics.getDimensions()

system_font=love.graphics.newImageFont("nemo83font.png",
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789- .,@")
system_font_size=6
system_line_height=9

sprite_font=love.graphics.newImageFont("nemo83sprites.png",
    " @BoA")
sprite_font_size=16

n = {
  api = {
    modelName="NEMO-83",
    modelContact="NEMO83@COLOURCOUNTRY.NET",
    width=144,
    height=240,
    t=0,
    pairs=pairs,
    floor=math.floor,
    ceil=math.ceil,
    max=math.max,
    min=math.min,
    random=math.random,
    sqrt=math.sqrt
  },
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
cur_mode = 0

canvas = love.graphics.newCanvas(n.api.width,n.api.height)
scale = math.floor(math.min(screenW/n.api.width , screenH/n.api.height)) -- Scale to the nearest integer
translateX = math.floor((screenW - n.api.width * scale)/2)
translateY = math.floor((screenH - n.api.height * scale)/2)

function dumpobj(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dumpobj(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function n.api.log(...)
  s = tostring(n.api.t)..": "
  for k,v in pairs({...}) do
    s = s..dumpobj(v).." "
  end
  print(s)
end

function n.api.loop()
  local loop = require("loop")
  local o = {
    length=0
  }
  setmetatable(o, loop)
  return o
end

function n.api.mode(parent)
  local mode = require("mode")
  local o = {
  }
  if (parent) then
    parent.__index = parent
    setmetatable(o, parent)
  else
    setmetatable(o, mode)
  end
  o:init()
  return o
end

function n.api.ent(x, y, r, spr)
  local ent = require("ent")
  local o = {
    x=x,
    y=y,
    r=r,
    spr=spr
  }
  setmetatable(o, ent)
  return o
end

function n.api.menu(items)
  local menu = require("menu")
  local o = {
    items=items
  }
  setmetatable(o, menu)
  o:init()
  return o
end

function n.api.touch(x, y, isNew)
  if (cart[mode].touch) then
    cart[mode]:touch(math.floor((x-translateX)/scale),math.floor((y-translateY)/scale), isNew)
  end
end

function n.api.border(c)
  local f = {colours[c][1]/2, colours[c][2]/2, colours[c][3]/2, 1}
  love.graphics.setBackgroundColor(f)
end

function n.api.colour(fg, bg)
  if fg and colours[math.floor(fg)] then
    cur_fg = colours[math.floor(fg)]
  else
    cur_fg = colours[math.floor((n.api.t/5+cur_mode)%11)]
    cur_mode = cur_mode + 1
  end
  if (bg) then
    bg = math.floor(bg)
    cur_bg = {colours[bg][1]/4, colours[bg][2]/4, colours[bg][3]/4, 1}
  end
  love.graphics.setColor(cur_fg)
end

sprts = {}
texts = {}

function n.api.print(strg, x, y, anchor_x, anchor_y)
  if (not strg) then
    strg = "-NIL-"
  end
  if (not texts[strg]) then
    texts[strg] = love.graphics.newText(system_font, strg)
  end
  print_text(texts[strg], x, y, anchor_x, anchor_y)
end

function n.api.printTitle(strg, x, y, anchor_x, anchor_y)
  love.graphics.push()
  love.graphics.scale(2)
  n.api.print(strg, x/2, y/2, anchor_x, anchor_y)
  love.graphics.pop()
end

function print_text(text, x, y, anchor_x, anchor_y)
  local width = text:getWidth()
  local height = system_font_size
  local ax =     x-(anchor_x+1)*width/2
  local ay =     y-(anchor_y+1)*height/2

  love.graphics.setColor(cur_fg)
  love.graphics.draw(text,ax,ay)
end

function n.api.printLines(strgs, x, y, anchor_x, anchor_y)
  for i, v in pairs(strgs) do
    n.api.print(v, x, y+(i-1)*system_line_height, anchor_x, anchor_y)
  end
end

function n.api.breakText(strg, pixels, atSpace)
  local chars = pixels/6
  local l = {}
  while #strg>chars do
    local c, skip = chars, 0
    if (atSpace) then
      local test = strg:sub(1,c):reverse()
      local s, e = test:find(" ")
      if (s) then
        skip = 1
        c = c-s+1
      end
    end
    l[#l+1] =  strg:sub(1, c-skip)
    strg = strg:sub(c+1,-1)
  end
  l[#l+1] = strg
  return l
end

function n.api.block(x, y, w, h)
  love.graphics.setColor(cur_fg)
  love.graphics.rectangle("fill",x,y,w,h)
end

function n.api.rect(x, y, w, h)
  love.graphics.setColor(cur_fg)
  love.graphics.rectangle("line",x,y,w,h)
end

function n.api.cls(bg)
  if bg then
    cur_bg = {colours[bg][1]/4, colours[bg][2]/4, colours[bg][3]/4, 1}
  end
  love.graphics.clear(cur_bg)
end

function draw()
  love.graphics.setFont(system_font)
  love.graphics.setColor(cur_fg)
  love.graphics.setCanvas(canvas)
  love.graphics.clear(cur_bg)
  cur_mode = 0
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
  n.api.t = n.api.t + 1
end

function n.api.exit()
  cart = n.getCart("__carousel.n83")
  cart.carts = n.carts -- carousel has secret access to this
  cart.switchCart = n.switchCart
  cart.quit = love.event.quit
  n.api.restart()
end

function n.api.die(msg)
  cart = n.getCart("__error.n83")
  cart.msg = msg
  cart.quit = love.event.quit
  n.api.restart()
end

function n.getCart(cartid)
  return nil -- override this in main
end

function n.switchCart(cartid)
  n.api.log("Switching to",cartid)
  cart = n.getCart(cartid)
  n.api.restart()
end

function n.api.restart()
  if cart.start then
    cart:start()
  end
  n.api.t = 0
  n.api.switch_mode(cart.start_mode)
end

function n.api.switch_mode(name)
  mode = name
  n.api.log("Entering mode "..name)
  if cart[mode].start then
    cart[mode]:start()
  end
end

function n.api.quadrant(x, y)
  local nwy = n.api.width*y
  return (((n.api.height*x > nwy) and 0) or 1) +
         (((n.api.height*(n.api.width-x) > nwy) and 0) or 2)
end

function n.api.polar(x,y,ox,oy)
  if (not ox) then
    ox = n.api.width/2
  end
  if (not oy) then
    oy = n.api.height/2
  end
  local dx = x-ox
  local dy = y-oy
  return math.floor(math.sqrt(dx*dx+dy*dy)), math.floor(math.deg(math.atan2(dy,dx)))
end


function love.update()
  update_time = love.timer.getTime()
  if (love.mouse.isDown(1, 2, 3)) then
    n.api.touch(love.mouse.getX(), love.mouse.getY(), false)
  end
  touches = love.touch.getTouches()
  for k, v in pairs(touches) do
    local x, y = love.touch.getPosition(v)
    n.api.touch(x, y, false)
  end
  if (cart[mode].update) then
    cart[mode]:update()
  end
  update_time = love.timer.getTime() - update_time
end

function love.draw()
  draw_time = love.timer.getTime()
  draw()
  if (cart[mode].draw) then
    cart[mode]:draw()
  end
  flush()
  draw_time = love.timer.getTime() - draw_time
  drawTimers()
end

-- Keys emulate touches. There is no NEMO-83 API for actual keys.
keys = {
  right={n.api.width, n.api.height/2},
  left={0, n.api.height/2},
  down={n.api.width/2, n.api.height},
  up={n.api.width/2, 0},
}
keys['return'] = {n.api.width/2,n.api.height/2}

function love.keypressed(key, scancode, isRepeat)
  if (scancode=='escape') then
    if cart.shutdown then
      cart:shutdown()
    end
    n.api.exit()
  end
  local k = keys[scancode]
  if (k and cart[mode].touch) then
    cart[mode]:touch(math.floor(k[1]), math.floor(k[2]), true)
  end
end

function love.touchpressed( id, x, y, dx, dy, pressure )
  n.api.touch(x,y,true)
end

function love.mousepressed( x, y, button, istouch, presses )
  n.api.touch(x,y,true)
end

n.api.__index = n.api

function n.environment()
  local o = {}
  setmetatable(o, n.api)
  return o
end

return n
