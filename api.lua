api = {
  MODEL="NEMO-83",
  MODELCONTACT="NEMO83@COLOURCOUNTRY.NET",
  W=144,
  H=240,
  T=0,
  LINES=system_line_height,
  PAIRS=pairs,
  pairs=pairs, -- allow this one lowercase function because it's fundamental to lua
  FLR=math.floor,
  CEIL=math.ceil,
  MAX=math.max,
  MIN=math.min,
  ABS=math.abs,
  RND=math.random,
  SQRT=math.sqrt
}

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

function api.LOG(...)
  s = tostring(api.T)..": "
  for k,v in pairs({...}) do
    s = s..dumpobj(v).." "
  end
  print(s)
end

function api.LOOP()
  local loop = require("loop")
  local o = {
    length=0
  }
  setmetatable(o, loop)
  return o
end

function api.NEWMODE(parent)
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

function api.ENT(x, y, r, spr)
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

function api.MENU(items)
  local menu = require("menu")
  local o = {
    items=items
  }
  setmetatable(o, menu)
  o:init()
  return o
end

function api.TOUCH(x, y, isNew)
  if (cart[cur_mode].touch) then
    cart[cur_mode]:touch(math.floor((x-translateX)/scale),math.floor((y-translateY)/scale), isNew)
  end
end

function api.BORDER(c)
  local f = {colours[c][1]/2, colours[c][2]/2, colours[c][3]/2, 1}
  love.graphics.setBackgroundColor(f)
end

function api.COLOUR(fg, bg)
  if fg and colours[math.floor(fg)] then
    cur_fg = colours[math.floor(fg)]
  else
    cur_fg = colours[math.floor((api.T/5+twinkle)%11)]
    twinkle = twinkle + 1
  end
  if (bg) then
    bg = math.floor(bg)
    cur_bg = {colours[bg][1]/4, colours[bg][2]/4, colours[bg][3]/4, 1}
  end
  love.graphics.setColor(cur_fg)
end

sprts = {}
texts = {}

function api.PRINT(strg, x, y, anchor_x, anchor_y)
  if (not strg) then
    strg = "-NIL-"
  end
  if (not texts[strg]) then
    texts[strg] = love.graphics.newText(system_font, strg)
  end
  print_text(texts[strg], x, y, anchor_x, anchor_y)
end

function api.TITLE(strg, x, y, anchor_x, anchor_y)
  love.graphics.push()
  love.graphics.scale(2)
  api.PRINT(strg, x/2, y/2, anchor_x, anchor_y)
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

function api.PRINTLINES(strgs, x, y, anchor_x, anchor_y)
  for i, v in pairs(strgs) do
    api.PRINT(v, x, y+(i-1)*system_line_height, anchor_x, anchor_y)
  end
end

function api.SPLIT(strg, pixels, atSpace)
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

function api.PANEL(x, y, w, h)
  if not h then
    h=w
  end
  love.graphics.setColor(cur_fg)
  love.graphics.rectangle("fill",x,y,w,h)
end

function api.RECT(x, y, w, h)
  if not h then
    h=w
  end
  love.graphics.setColor(cur_fg)
  love.graphics.rectangle("line",x,y,w,h)
end

function api.DISC(x, y, r)
  love.graphics.setColor(cur_fg)
  love.graphics.circle("fill",x,y,r)
end

function api.CIRCLE(x, y, r)
  love.graphics.setColor(cur_fg)
  love.graphics.circle("line",x,y,r)
end


function api.CLS(bg)
  if bg then
    cur_bg = {colours[bg][1]/4, colours[bg][2]/4, colours[bg][3]/4, 1}
  end
  love.graphics.clear(cur_bg)
end

function api.EXIT()
  cart = n.get_cart("__carousel.n83")
  cart.carts = n.carts -- carousel has secret access to this
  cart.switch_cart = n.switch_cart
  cart.quit = love.event.quit
  api.LOG("Exited to "..cart.name)
  api.RESTART()
end

function api.DIE(msg)
  cart = n.get_cart("__error.n83")
  cart.msg = msg
  cart.quit = love.event.quit
  api.RESTART()
end

function api.RESTART()
  if cart.start then
    cart:start()
  end
  api.T = 0
  api.MODE(cart.start_mode)
end

function api.MODE(name)
  api.LOG("Entering mode "..name)
  cur_mode = name
  if cart[name].start then
    cart[name]:start()
  end
end

function api.QUADRANT(x, y)
  local nwy = api.W*y
  return (((api.H*x > nwy) and 0) or 1) +
         (((api.H*(api.W-x) > nwy) and 0) or 2)
end

function api.POLAR(x,y,ox,oy)
  if (not ox) then
    ox = api.W/2
  end
  if (not oy) then
    oy = api.H/2
  end
  local dx = x-ox
  local dy = y-oy
  return math.sqrt(dx*dx+dy*dy), math.deg(math.atan2(dy,dx))
end

function api.DIRECTION(x,y)
  a = math.sqrt(x*x+y*y)
  return x/a, y/a, a
end

return api