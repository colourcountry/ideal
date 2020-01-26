_love = love
love.window.setMode(800,600,{fullscreen=true, resizable = true, highdpi = true}) -- Just to make the screen resizable, and this method works with HighDpi
love.graphics.setDefaultFilter("nearest")
screenW,screenH = love.graphics.getDimensions()

system_font=love.graphics.newImageFont("nemo83font.png",
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789- .,@")
system_font_size=6

sprite_font=love.graphics.newImageFont("nemo83sprites.png",
    " @BoA")
sprite_font_size=16

n = {
  name="NEMO-83",
  width=144,
  height=240,
  t=0
}

canvas = love.graphics.newCanvas(n.width,n.height)
scale = math.floor(math.min(screenW/n.width , screenH/n.height)) -- Scale to the nearest integer
translateX = math.floor((screenW - n.width * scale)/2)
translateY = math.floor((screenH - n.height * scale)/2)

loop = {
  length=0,
}
loop.__index = loop

function loop:add(x)
  if not self.length or self.length==0 then
    self.path={[1]=1}
    self.rpath={[1]=1}
    self.first=1
    self[1]=x
    self.length=1
    self.top=2
    return
  end
  self[self.top] = x
  local last = self.rpath[self.first]
  self.path[last] = self.top
  self.rpath[self.top] = last
  self.path[self.top] = self.first
  self.rpath[self.first] = self.top
  self.length = self.length + 1
  self.top = self.top + 1
end

function loop:print()
  if self.length==0 then
    print("0.")
    return
  end
  local s = tostring(self.length)..": "..tostring(self.first)..";"
  local i = self.path[self.first]
  local b = 0
  while i ~= self.first do
    b = b + 1
    s = s..tostring(i)..","
    i = self.path[i]
    if not i then
      s = s.." nil?"
      break
    end
    if b > self.length then
      s = " len?"
      break
    end
  end
  print(s)
end

function loop:remove(i)
  if not self.path[i] then
    return -- shrug
  end
  if self.length == 1 then
    self.length = 0
    return
  end
  self.rpath[self.path[i]] = self.rpath[i]
  self.path[self.rpath[i]] = self.path[i]
  if self.first == i then
    self.first = self.path[i]
  end
  self.path[i] = nil
  self.rpath[i] = nil
  self.length = self.length - 1
end

function loop:each(f)
  if self.length == 0 then
    return
  end
  local i = self.first
  if self[i] then
    f(self[i], function()
      self:remove(i)
    end)
  end
  i = self.path[i]
  while i and i ~= self.first do
    if self[i] then
      f(self[i], function() self:remove(i) end)
    end
    i = self.path[i]
  end
end

function n.loop()
  local o = {
    length=0
  }
  setmetatable(o, loop)
  return o
end


ent = {
    x=0,
    y=0,
    r=16,
    dx=0,
    dy=0,
    spr="@",
}
ent.__index = ent

function ent:is_on_screen()
  if self.x<0 or self.y<0 or self.x>n.width or self.y>n.height then
    return false
  end
  return true
end

function ent:move()
  self.x = self.x + self.dx
  self.y = self.y + self.dy
end

function ent:collides(other)
  local dx, dy = self.x-other.x, self.y-other.y
  return math.sqrt(dx*dx+dy*dy)<(self.r+other.r)
end

function ent:draw()
  if (not sprts[self.spr]) then
    sprts[self.spr] = _love.graphics.newText(sprite_font, self.spr)
  end
  print_text(sprts[self.spr], self.x, self.y, 0, 0)
end

function n.ent(x, y, r, spr)
  local o = {
    x=x,
    y=y,
    r=r,
    spr=spr
  }
  setmetatable(o, ent)
  return o
end

function n.touch(x, y, isNew)
  if (cart[mode].touch) then
    cart[mode].touch(math.floor((x-translateX)/scale),math.floor((y-translateY)/scale), isNew)
  end
end

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

local cur_fg = colours[0]
local cur_bg = colours[11]

function n.border(c)
  local f = {colours[c][1]/2, colours[c][2]/2, colours[c][3]/2, 1}
  _love.graphics.setBackgroundColor(f)
end

n.border(10)

function n.colour(fg, bg)
  if fg and colours[math.floor(fg)] then
    cur_fg = colours[math.floor(fg)]
  else
    cur_fg = colours[math.floor((n.t/10)%11)]
  end
  if (bg) then
    bg = math.floor(bg)
    cur_bg = {colours[bg][1]/4, colours[bg][2]/4, colours[bg][3]/4, 1}
  end
  _love.graphics.setColor(cur_fg)
end

sprts = {}
texts = {}

function n.print(strg, x, y, anchor_x, anchor_y)
  if (not strg) then
    strg = "-NIL-"
  end
  if (not texts[strg]) then
    texts[strg] = _love.graphics.newText(system_font, strg)
  end
  print_text(texts[strg], x, y, anchor_x, anchor_y)
end

function print_text(text, x, y, anchor_x, anchor_y)
  local width = text:getWidth()
  local height = system_font_size
  local ax =     x-(anchor_x+1)*width/2
  local ay =     y-(anchor_y+1)*height/2

  _love.graphics.setColor(cur_fg)
  _love.graphics.draw(text,ax,ay)
end

function n.printLines(strgs, x, y, anchor_x, anchor_y)
  for i, v in pairs(strgs) do
    n.print(v, x, y+i*8-8, anchor_x, anchor_y)
  end
end

function n.breakText(strg, pixels, atSpace)
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

function n.rect(x, y, w, h)
  _love.graphics.setColor(cur_bg)
  _love.graphics.rectangle("fill",x,y,w,h)
  if (cur_fg ~= cur_bg) then
    _love.graphics.setColor(cur_fg)
    _love.graphics.rectangle("line",x,y,w,h)
  end
end

function n.cls()
  _love.graphics.clear(cur_bg)
end

function n.draw()
  _love.graphics.setFont(system_font)
  _love.graphics.setColor(cur_fg)
  _love.graphics.setCanvas(canvas)
  _love.graphics.clear(cur_bg)
end

function drawTimers()
  local ut = update_time*screenH*60
  _love.graphics.setColor({0,0,0,1})
  local dt = draw_time*screenH*60
  _love.graphics.rectangle("fill",0,ut,4,dt)
end

function n.flush()
  _love.graphics.setCanvas() -- Set rendering to the screen
	_love.graphics.push() -- Push transformation state, The translate and scale will affect everything below until love.graphics.pop()
	_love.graphics.translate( translateX, translateY ) -- Move to the appropiate top left corner
	_love.graphics.scale(scale,scale) -- Scale
  _love.graphics.setColor(white)
	_love.graphics.draw(canvas) -- Draw the canvas
	_love.graphics.pop() -- pop transformation state
  n.t = n.t + 1
end















function n.exit()
  cart = require("carousel")
  mode = cart.start_mode
end

function n.switch_cart(cartid)
  cart = require("carts."..carts[cartid].req)
  n.restart()
end

function n.restart()
  if cart.start then
    cart.start()
  end
  n.switch_mode(cart.start_mode)
end

function n.switch_mode(name)
  mode = name
  if cart[mode].start then
    cart[mode].start()
  end
end

function n.quadrant(x, y)
  local nwy = n.width*y
  return (((n.height*x > nwy) and 0) or 1) +
         (((n.height*(n.width-x) > nwy) and 0) or 2)
end

function n.polar(x,y)
  local dx = x-(n.width/2)
  local dy = y-(n.height/2)
  return math.floor(math.sqrt(dx*dx+dy*dy)), math.floor(180-math.deg(math.atan2(dx,dy)))
end

function love.update()
  update_time = love.timer.getTime()
  local _love = love
  love = nil
  if (_love.mouse.isDown(1, 2, 3)) then
    n.touch(_love.mouse.getX(), _love.mouse.getY(), false)
  end
  touches = _love.touch.getTouches()
  for k, v in pairs(touches) do
    local x, y = _love.touch.getPosition(v)
    n.touch(x, y, false)
  end
  if (cart[mode].update) then
    cart[mode].update()
  end
  love = _love
  update_time = love.timer.getTime() - update_time
end

function love.draw()
  draw_time = love.timer.getTime()
  n.draw()
  local _love = love
  love = nil
  if (cart[mode].draw) then
    cart[mode].draw()
  end
  love = _love
  n.flush()
  draw_time = love.timer.getTime() - draw_time
  drawTimers()
end

-- Keys emulate touches. There is no NEMO-83 API for actual keys.
keys = {
  right={n.width, n.height/2},
  left={0, n.height/2},
  down={n.width/2, n.height},
  up={n.width/2, 0},
}
keys['return'] = {n.width/2,n.height/2}

function love.keypressed(key, scancode, isRepeat)
  if (scancode=='escape') then
    n.exit()
  end
  local k = keys[scancode]
  if (k and cart[mode].touch) then
    cart[mode].touch(math.floor(k[1]), math.floor(k[2]), true)
  end
end

function love.touchpressed( id, x, y, dx, dy, pressure )
  n.touch(x,y,true)
end

function love.mousepressed( x, y, button, istouch, presses )
  n.touch(x,y,true)
end

return n
