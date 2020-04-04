api = {
  MODEL="IDEAL-C4",
  API="n83",
  URL="IDEAL.COLOURCOUNTRY.NET",
  W=144,
  H=240,
  T=0,
  L=6,
  S=16,
  EXEC=loadstring, -- need this to load stuff in the first place
  STR=tostring,
  FLR=math.floor,
  CEIL=math.ceil,
  MAX=math.max,
  MIN=math.min,
  ABS=math.abs,
  RND=love.math.random,
  SQRT=math.sqrt,
  UPPER=string.upper,
  LOWER=string.lower,
}

cur_x = 0
cur_y = 0

function dumpobj(o)
  if o == nil then
    return "nil"
  end
  if type(o) == 'table' then
    if o.LOG then
     return o:LOG()
    end
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

function api.SIGN(number)
  return (number > 0 and 1) or (number == 0 and 0) or -1
end

function api.ITEMS(x)
  if x.ITEMS then
    return x:ITEMS()
  end
  return pairs(x)
end


function api.TOUCH(x, y)
  if cur_mode.TOUCH then
    cur_mode:TOUCH(x, y)
  end
end

function api.DRAG(ox, oy, x, y)
  if cur_mode.DRAG then
    cur_mode:DRAG(ox, oy, x, y)
  end
end

function api.RELEASE(ox, oy, x, y)
  if cur_mode.RELEASE then
    cur_mode:RELEASE(ox, oy, x, y)
  end
end

function api.BORDER(c)
  local f = {colours[c][1]/2, colours[c][2]/2, colours[c][3]/2, 1}
  love.graphics.setBackgroundColor(f)
end

function api.COLOUR(fg, bg)
  fg = (fg and math.floor(fg)) or -1
  bg = (bg and math.floor(bg)) or -1
  if colours[fg] then
    cur_fg = colours[fg]
  else
    cur_fg = colours[math.floor((api.T/5+twinkle)%11)]
    twinkle = twinkle + 1
  end
  if colours[bg] then
    cur_bg = {colours[bg][1]/4, colours[bg][2]/4, colours[bg][3]/4, 1}
  end
  love.graphics.setColor(cur_fg)
end

texts = {}

function print_string(strg, x, y, anchor_x, anchor_y)
  if (not strg) then
    strg = "-"
  end
  if (not anchor_x) then
    anchor_x = -1
  end
  if (not anchor_y) then
    anchor_y = 1
  end
  if (not texts[strg]) then
    texts[strg] = love.graphics.newText(system_font, strg)
  end
  print_text(texts[strg], x, y, anchor_x, anchor_y)
end

function api.SPR(spr, x, y)
  love.graphics.setColor(cur_fg)
  if quads[spr] then
    love.graphics.draw(atlases[spr], quads[spr],(x-sprite_radius)*units,(y-sprite_radius)*units)
  else
    love.graphics.draw(atlases["1f344"], quads["1f344"],(x-sprite_radius)*units,(y-sprite_radius)*units)
  end
end

function api.TITLE(strg, x, y, anchor_x, anchor_y)
  love.graphics.push()
  love.graphics.scale(2)
  print_string(strg, x/2, y/2, anchor_x, anchor_y)
  love.graphics.pop()
end

function api.PRINT(strg, x, y, anchor_x, anchor_y)
  if not x then x=cur_x end
  if not y then y=cur_y+api.L*2 end
  print_string(strg, x, y, anchor_x, anchor_y)
end

function print_text(text, x, y, anchor_x, anchor_y)
  local width = text:getWidth()/units
  local height = system_font_size
  local ax =     x-(anchor_x+1)*width/2
  local ay =     y-(anchor_y+1)*height/2
  cur_x = ax
  cur_y = ay

  love.graphics.setColor(cur_fg)
  love.graphics.draw(text,ax*units,ay*units)
end

function api.PRINTLINES(strgs, x, y, anchor_x, anchor_y)
  for i=1,#strgs do
    api.PRINT(strgs[i], x, y+(i-1)*system_font_size, anchor_x, anchor_y)
  end
  return #strgs
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

function api.BLOCK(x, y, w, h)
  if not h then
    h=w
  end
  love.graphics.setColor(cur_fg)
  love.graphics.rectangle("fill",x*units,y*units,w*units,h*units)
end

function api.BOX(x, y, w, h)
  if not h then
    h=w
  end
  love.graphics.setColor(cur_fg)
  love.graphics.rectangle("line",x*units,y*units,w*units,h*units)
end

api.RECT = api.BOX

function api.DISC(x, y, r)
  love.graphics.setColor(cur_fg)
  love.graphics.circle("fill",x*units,y*units,r*units)
end

function api.RING(x, y, r)
  love.graphics.setColor(cur_fg)
  love.graphics.circle("line",x*units,y*units,r*units)
end

api.CIRCLE = api.RING

function api.CLS()
  love.graphics.clear(cur_bg)
end

function api.EJECT()
  cart = sys.get_cart("_carousel."..api.API)
  cart.__carts = sys.carts -- carousel has secret access to this
  cart.__switch = sys.switch_cart
  cart.__quit = love.event.quit
  api.LOG("Exited to "..cart.name)
  api.RESTART()
end

function api.ERROR(msg)
  cart = sys.get_cart("_error."..api.API)
  cart.__msg = msg
  cart.__debug = cart_arg_found
  cart.__quit = love.event.quit
  api.RESTART()
end

function api.RESTART()
  api.LOG("Restarting cart "..cart.name)
  api.T = 0
  if not cart.START then
    api.ERROR("?START")
    return
  end
  cart:START()
end

function api.GO(mode)
  cur_mode = mode
  api.LOG("Entering",mode)
  if mode.START then
    mode:START()
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

function api.DIRECTION(x,y,s)
  a = math.sqrt(x*x+y*y)
  if (s) then
    return x*s/a, y*s/a, a
  else
    return x/a, y/a, a
  end
end

function api.DAILY()
  local d = tonumber(os.date("%Y%m%d"))
  api.LOG("Resetting RNG to "..tostring(d))
  love.math.setRandomSeed(d)
  return d
end

function api.SHUFFLE(array)
  for i=1,#array-1 do
    local j = math.random(i,#array)
    array[i], array[j] = array[j], array[i]
  end
end


-------------------------------------------------------------------- Object "methods"
-- To make it a bit more BASICy, these global functions just call named methods of the object

function api.DRAW(o)
  if o.DRAW then
    o:DRAW()
  else
    api.LOG("ERROR: Can't draw object ",o)
    api.ERROR("?DRAW")
  end
end
-------------------------------------------------------------------- Object types

entid = 1
function api.ENT(x, y, r, spr, c)
  local ent = require("ent")
  local o = {
    x=x,
    y=y,
    r=r,
    id=entid,
    spr=spr,
    c=c
  }
  entid = entid+1
  setmetatable(o, ent)
  return o
end

function api.LOOP()
  local loop = require("loop")
  local o = {
    length=0
  }
  setmetatable(o, loop)
  return o
end

mapid = 1
function api.MAP(cx, cy)
  local map = require("map")
  local o = {
    cx=cx,
    cy=cy,
    id=mapid
  }
  mapid = mapid+1
  setmetatable(o, map)
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

function api.MODE(o)
  local mode = require("mode")
  if not o then
    o = {}
  end
  if (o.parent) then
    o.parent.__index = o.parent
    setmetatable(o, o.parent)
  else
    setmetatable(o, mode)
  end
  o:init()
  return o
end

function api.INFOMODE(name,instructions)
  local o = api.MODE()
  o.draw = function(self)
    api.CLS(11)
    api.COLOUR(-1)
    api.TITLE(name, api.W/2, 0, 0, -1)
    api.COLOUR(0)
    local y = api.L*4
    for i=1,#instructions do
      api.COLOUR(instructions[i][2])
      if instructions[i][1]=="" then
        y = y + api.L*api.PRINTLINES(api.SPLIT(instructions[i][3],api.W-20,true),10,y)
      else
        api.SPR(instructions[i][1],18,y+2)
        api.COLOUR(0)
        y = y + api.L*api.PRINTLINES(api.SPLIT(instructions[i][3],api.W-50,true),40,y)
      end
      y = y + api.L
    end
    api.BORDER(11)
  end
  return o
end

return api
