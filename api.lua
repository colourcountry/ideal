api = {
  MODEL="IDEAL-5",
  API="n83",
  URL="IDEAL.COLOURCOUNTRY.NET",
  W=144,
  H=240,
  T=0,
  L=10,
  S=16,
  FLR=math.floor,
  CEIL=math.ceil,
  MAX=math.max,
  MIN=math.min,
  ABS=math.abs,
  RND=love.math.random,
  SQRT=math.sqrt,
  UPPER=string.upper,
  LOWER=string.lower,
  MID=string.sub,
  SORT=table.sort
}

cur_x = 0
cur_y = 0

function api.EXEC(chunk,chunkid)
   -- this is kind of horrible but works for the moment
  ok, result = pcall(loadstring, "--"..(chunkid or "anonymous").."\nsetfenv(1,sys.environment())\n"..chunk)
  if (ok) then
    return result
  end
  return "ERROR"
end

function api.STR(o)
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
       s = s .. '['..k..'] = ' .. api.STR(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

function api.CHARAT(s,i)
  return s:sub(i,i)
end

function api.LOG(...)
  s = tostring(api.T)..": "
  for k,v in pairs({...}) do
    s = s..api.STR(v).." "
  end
  print(s)
end

function api.SIGN(number)
  return (number > 0 and 1) or (number == 0 and 0) or -1
end

function api.ITEMS(iterable)
  if iterable.ITEMS then
    return iterable:ITEMS()
  end
  return pairs(iterable)
end

function api.KEY(x, y, ch)
  if cur_mode.KEY then
    cur_mode:KEY(x, y, ch)
  end
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
  lg.setBackgroundColor(f)
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
  lg.setColor(cur_fg)
end

texts = {}

function print_string(strg, x, y, anchor_x, anchor_y)
  if (not strg) then
    strg = "-"
  end
  strg = api.STR(strg):upper()
  if (not texts[strg]) then
    texts[strg] = lg.newText(system_font, strg)
  end
  print_text(texts[strg], x, y, anchor_x or 1, anchor_y or 1)
end

function api.SPR(spr, x, y)
  lg.setColor(white)
  if sys.sprites.names[spr] then
    spr = sys.sprites.names[spr]
  end
  if quads[spr] then
    lg.draw(atlases[spr], quads[spr],(x-sprite_radius)*units,(y-sprite_radius)*units)
  else
    lg.draw(atlases["1f196"], quads["1f196"],(x-sprite_radius)*units,(y-sprite_radius)*units)
  end
end

function api.SPRGROUP(name)
  return sys.sprites.groups[name]
end

function api.TITLE(strg, x, y, anchor_x, anchor_y)
  lg.push()
  lg.scale(2)
  print_string(strg, x/2, y/2, anchor_x, anchor_y)
  lg.pop()
end

function api.PRINT(strg, x, y, anchor_x, anchor_y)
  if not x then x=cur_x end
  if not y then y=cur_y+api.L end
  print_string(strg, x, y, anchor_x, anchor_y)
end

function print_text(text, x, y, anchor_x, anchor_y)
  local width = text:getWidth()/units
  local height = system_font_size
  local ax =     x-(1-anchor_x)*width/2
  local ay =     y-(1-anchor_y)*height/2
  cur_x = ax
  cur_y = ay

  lg.setColor(cur_fg)
  lg.draw(text,ax*units,ay*units)
end

function api.PRINTLINES(strgs, x, y, anchor_x, anchor_y)
  for i,s in api.ITEMS(strgs) do
    if (i==1) then
      api.PRINT(s, x, y, anchor_x, anchor_y)
    else
      api.PRINT(s, nil, nil, 1, 0)
    end
  end
  return #strgs
end

function api.SPLIT(strg, chars, at)
  local l = {}
  while #strg>chars do
    local c, skip = chars, 0
    if (at) then
      local test = strg:sub(1,c):reverse()
      local s, e = test:find(at)
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
  lg.setColor(cur_fg)
  lg.rectangle("fill",x*units,y*units,w*units,h*units)
end

function api.BOX(x, y, w, h)
  if not h then
    h=w
  end
  lg.setColor(cur_fg)
  lg.rectangle("line",x*units,y*units,w*units,h*units)
end

api.RECT = api.BOX

function api.DISC(x, y, r)
  lg.setColor(cur_fg)
  lg.circle("fill",x*units,y*units,r*units)
end

function api.RING(x, y, r)
  lg.setColor(cur_fg)
  lg.circle("line",x*units,y*units,r*units)
end

api.CIRCLE = api.RING

function api.CLS()
  lg.clear(cur_bg)
end

function api.EJECT()
  api.LOG("Eject")
  cur_cart = get_cart("_carousel."..api.API)
  cur_cart.__carts = carts -- carousel has secret access to this
  cur_cart.__switch = switch_cart
  cur_cart.__quit = love.event.quit
  api.RESTART()
end

function api.ERROR(msg)
  cur_cart = get_cart("_error."..api.API)
  cur_cart.__msg = msg
  cur_cart.__debug = cart_arg_found
  cur_cart.__quit = love.event.quit
  api.RESTART()
end

function api.RESET()
  api.LOG("Resetting cart "..cur_cart.name)
  cur_cart = get_cart(cur_cartid)
  api.RESTART()
end

function api.RESTART()
  api.LOG("Restarting cart "..cur_cart.name)
  api.T = 0
  if not cur_cart.START then
    api.ERROR("?START")
    return
  end
  cur_cart:START()
end

function api.GO(mode)
  api.LOG("Reloading cart as ",mode)
  cur_modes = {}
  cur_cart = get_cart(cur_cartid)
  cur_mode = cur_modes[mode.name]
  if not cur_mode then
    api.ERROR("?MODENAME")
    return
  end
  api.LOG("Entering",cur_mode)
  mode_start_time = love.timer.getTime()
  if cur_mode.START then
    cur_mode:START()
  end
end

function api.QUADRANT(x, y)
  if x==y or x==-y then
    local p = love.math.random()
    if p < 0.5 then
      y = y*2
    else
      y = y/2
    end
  end
  if x > y then
    if -x > y then return 0,-1 else return 1,0 end
  end
  if -x > y then return -1,0 end
  if x == 0 and y == 0 then return 0,0 end
  return 0,1
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
  api.RANDOMIZE(d)
end

function api.RANDOMIZE(seed)
  api.LOG("Resetting RNG to "..tostring(seed))
  love.math.setRandomSeed(seed)
  return d
end

function api.SHUFFLE(array)
  for i=1,#array-1 do
    local j = math.random(i,#array)
    array[i], array[j] = array[j], array[i]
  end
end

function api.CHOOSE(array)
  return array[math.random(1,#array)]
end

-------------------------------------------------------------------- Object "methods"
-- To make it a bit more BASICy, these global functions just call named methods of the object

function api.DRAW(drawable)
  if not drawable then return end
  if drawable.DRAW then
    drawable:DRAW()
  else
    api.LOG("ERROR: Can't draw object ",drawable)
    die()
    api.ERROR("?DRAW")
  end
end
-------------------------------------------------------------------- Object types

entid = 1
function api.ENT(x, y, r, spr, c, flags)
  local ent = require("ent")
  local o = {
    x=x,
    y=y,
    r=r,
    id=entid,
    spr=spr,
    c=c,
    flags=flags
  }
  entid = entid+1
  setmetatable(o, ent)
  return o
end

function api.IS(e,k)
  return e and e.flags and e.flags[k]
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
function api.MAP(flags)
  local map = require("map")
  local flagsets = {}
  if flags then
    for k,f in pairs(flags) do
      k = sys.sprites.names[k] or k
      flagsets[k] = {}
      for i,v in pairs(f) do
        flagsets[k][v] = true
      end
    end
  end
  local o = {
    id=mapid,
    flagsets=flagsets
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

function api.MAINMENU(modelist)
  local m = {}
  for i=1,#modelist do
    m[#m+1] = { name=modelist[i].name, icon=modelist[i].icon, action=function() api.GO(modelist[i]) end }
  end
  m[#m+1] = { name="RECORDS", icon="1f3c6", action=api.MEMORY }
  m[#m+1] = { name="EJECT", icon="23cf", action=api.EJECT }
  return api.MENU(m)
end

function api.MODE(name,parent)
  local mode = require("mode")
  o = { name=name, parent=parent }
  if (o.parent) then
    o.parent.__index = o.parent
    setmetatable(o, o.parent)
  else
    setmetatable(o, mode)
  end
  o:init()
  cur_modes[o.name] = o
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

-- Memory functions
-- You can use POST to set as many fields as you like, for high scores and such.
-- but carts do not have access to these.
-- Readable state is handled by SAVE and is subject to validation rules:

function api.MEMORY()
  local cartid = cur_cartid
  cur_cart = get_cart("_memory."..api.API)
  cur_cart.__switch = switch_cart
  cur_cart.__memory = memory[cartid]
  cur_cart.__cart = carts[cartid]
  api.RESTART()
end

function api.FIELD(loc,value,name,icon)
  if not memory[cur_cartid] then memory[cur_cartid] = {} end
  if memory[cur_cartid][loc] then
    api.LOG("Retaining existing value ",memory[cur_cartid][loc].value," for ",name)
    memory[cur_cartid][loc].name=name
    memory[cur_cartid][loc].icon=icon
  else
    memory[cur_cartid][loc] = { value=value, name=name, icon=icon }
  end
  save_memory(cur_cartid)
  return loc
end

function validate_state(v)
  if type(v)=='number' then return v end
  if type(v)=='string' then
    return string.sub(v,1,80)
  end
  if type(v)~='table' then return nil end

  local char_allowance = 0
  for i=1,10 do
    if type(v[i])=='string' then
      char_allowance = char_allowance + 8
    end
  end

  local s = {}
  for i=1,10 do
    if type(v[i])=='string' and #v[i]<char_allowance then
      char_allowance = char_allowance - #v[i]
      s[i] = v[i]
    else
      if type(v[i])=='number' then
        s[i] = v[i]
      end
    end
  end
  api.LOG("Saving strings as ",s)
  return s
end

function api.POST(loc,value)
  if loc=="__state__" then
    safe_value = validate_state(value)
    api.LOG("Requested save state ",value)
    api.LOG("Actually saved state ",safe_value)
    value = safe_value
  end
  if not memory[cur_cartid] then memory[cur_cartid] = {} end
  if not memory[cur_cartid][loc] then memory[cur_cartid][loc] = {} end
  memory[cur_cartid][loc].value = value
  save_memory(cur_cartid)
end

function api.SAVE(state)
  api.POST("__state__",state)
end

function api.LOAD()
  local r = memory[cur_cartid] and memory[cur_cartid]["__state__"] and memory[cur_cartid]["__state__"].value
  api.LOG("Loaded state ",value)
  return r
end

return api
