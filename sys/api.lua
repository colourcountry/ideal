local api = {
  MODEL="IDEAL-5",
  API="n83",
  URL="IDEAL.COLOURCOUNTRY.NET",
  W=144,
  H=240,
  T=0,
  L=8,
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
  SORT=table.sort,
}

help = {
  [api.MODEL]={api.MODEL},
  [api.H]=[[The screen height, in graphics units.
```
PRINT("Left",H/2,0)
```
]],
  [api.W]=[[The screen width, in graphics units.
```
PRINT("Top",W/2,0,0)
```
]],
}

cur_x = 0
cur_y = 0
timer_end_time = false

function api.HELP(obj)
  local h=help[obj] or "No help for this."
  api.LOG(h)
  return h
end

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
       if type(k) == 'string' then k = '"'..k..'"' end
       s = s .. '['..api.STR(k)..'] = ' .. api.STR(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end
help[api.STR]=[[Convert an object to a string.
```
@ STR(5)
"5"
```
]]

function api.CHARAT(s,i)
  return s:sub(i,i) -- this is actually available to carts via string's metatable but i don't want to go there
end

function api.LOG(...)
  local s = (api.T>0 and tostring(api.T)..": ") or ""
  for k,v in pairs({...}) do
    s = s..api.STR(v).." "
  end
  print(s)
end

function api.ITEMS(iterable)
  if iterable.ITEMS and iterable~=api then
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
  c = (c and math.floor(c%16)) or -1
  local f = {colours[c][1]/2, colours[c][2]/2, colours[c][3]/2, 1}
  lg.setBackgroundColor(f)
end

function api.COLOUR(fg)
  cur_fg = colours[(fg and math.floor(fg%16)) or 0]
  cur_shader:send("transform",matrix_for_colour(cur_fg))
end

texts = {}

function get_codepoint(utf8)
  if #utf8>1 then return "?" end --FIXME
  return utf8:byte(1)
end

function print_string(strg, x, y, anchor_x, anchor_y, scale)
  if (not strg) then
    strg = "nil"
  end
  strg = api.STR(strg)

  key = strg.." - "..api.STR(cur_fg)
  if texts[key] then
    print_text(texts[key], x, y, anchor_x or 1, anchor_y or 1, scale)
    return
  end

  local codepoints = {}
  for utf8 in strg:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    codepoints[#codepoints+1] = get_codepoint(utf8)
  end
  local c = new_canvas(api.S*#codepoints,api.S)
  c:start()
  cur_shader:send("transform",identity_matrix)
  for i,cp in ipairs(codepoints) do
    api.SPR(cp,i*api.S-api.S/2,api.S/2)
  end
  c:stop()

  texts[key]=c
  cur_shader:send("transform",matrix_for_colour(cur_fg))
  print_text(c, x, y, anchor_x or 1, anchor_y or 1, scale)
end

function api.SPR(spr, x, y)
  if quads[spr] then
    lg.draw(atlases[spr], quads[spr],(x-sprite_radius)*units,(y-sprite_radius)*units)
  else
    lg.draw(atlases[0x1f196], quads[0x1f196],(x-sprite_radius)*units,(y-sprite_radius)*units)
  end
end

function api.SPRGROUP(name)
  return {}
  --return sys.sprites.groups[name]  --FIXME: add groups
end

function api.SPRCODE(name)
  local r = sprites.names[name] or sprites.unicode[name]
  if not r then
    api.LOG("WARNING: no sprite code for name",name)
    return 0x2754
  end
  return r
end

function api.TITLE(strg, x, y, anchor_x, anchor_y)
  print_string(strg, x, y, anchor_x, anchor_y)
end

function api.PRINT(strg, x, y, anchor_x, anchor_y)
  if not x then x=cur_x anchor_x=1 end
  if not y then y=cur_y+api.L anchor_y=1 end
  print_string(strg, x, y, anchor_x, anchor_y, 0.5)
end

function print_text(text, x, y, anchor_x, anchor_y, scale)
  if scale then
    lg.push()
    lg.scale(scale)
    cur_x =     x/scale-(1-anchor_x)*text.w/2
    cur_y =     y/scale-(1-anchor_y)*text.h/2
  else
    cur_x =     x-(1-anchor_x)*text.w/2
    cur_y =     y-(1-anchor_y)*text.h/2
  end

  text:paste(cur_x,cur_y)

  if scale then
    lg.pop()
    cur_x = cur_x*scale
    cur_y = cur_y*scale
  end
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
  lg.push("all")
  lg.setShader()
  lg.setColor(cur_fg)
  lg.rectangle("fill",x*units,y*units,w*units,h*units)
  lg.pop()
end

function api.BOX(x, y, w, h)
  if not h then
    h=w
  end
  lg.push("all")
  lg.setShader()
  lg.setColor(cur_fg)
  lg.rectangle("line",x*units,y*units,w*units,h*units)
  lg.pop()
end

function api.DISC(x, y, r)
  lg.push("all")
  lg.setShader()
  lg.setColor(cur_fg)
  lg.circle("fill",x*units,y*units,r*units)
  lg.pop()
end

function api.RING(x, y, r)
  lg.push("all")
  lg.setShader()
  lg.setColor(cur_fg)
  lg.circle("line",x*units,y*units,r*units)
  lg.pop()
end

function api.CLS()
  lg.clear({0,0,0,1})
end

function api.EJECT()
  api.LOG("Eject")
  switch_cart("_carousel."..api.API, "Main", {
    carts = carts,
    switch_cart = switch_cart,
    quit = love.event.quit
  })
end

function api.ERROR(msg,...)
  if msg then
    api.LOG("CART ERROR: ",msg,"! ",...)
    error(msg)
  else
    love.event.quit()
    return
  end
  switch_cart("_error."..api.API, "Main", {
    msg=msg,
    quit=love.event.quit
  })
end

function api.RESET()
  api.LOG("Resetting cart "..cur_cartid)
  cur_cart = switch_cart(cur_cartid)
end

function api.RESTART()
  api.LOG("Restarting cart "..cur_cartid)
  api.T = 0
  if not cur_cart.START then
    api.LOG("No START function!")
    api.ERROR("Bad cart")
    return
  end
  cur_cart:START()
end

function api.GO(mode)
  local id = (cur_cart and cur_cart.id) or cur_cartid
  api.LOG("Reloading cart ",id," as ",mode)
  cur_modes = {}
  cur_cart = get_cart(id)
  cur_mode = cur_modes[mode.name]
  if not cur_mode then
    api.ERROR("?MODENAME")
    return
  end
  api.LOG("Entering",cur_mode)
  mode_end_time = love.timer.getTime()+mode_panic_time
  if cur_mode.START then
    cur_mode:START()
  end
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

function api.DAILY()
  local d = tonumber(os.date("%Y%m%d"))
  api.RANDOMIZE(d)
end

function api.RANDOMIZE(seed)
  api.LOG("Resetting RNG to "..tostring(seed))
  love.math.setRandomSeed(seed)
  return d
end


-------------------------------------------------------------------- Object types

entid = 1
function api.ENT(x, y, r, spr, c, flags)
  local ent = require("lib/ent")

  if not flags then flags={} end
  -- add the original sprite and its name to flags,
  -- so we can tell what it was even if its sprite is changed
  flags[spr] = true

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
  setmetatable(o, {__index=ent})
  return o
end

function api.IS(e,k)
  if not e or not e.flags then return false end
  if e.flags[k] then return true end
  return sys.sprites.names[k] and e.flags[sys.sprites.names[k]]
end

function api.LOOP()
  local loop = require("lib/loop")
  local o = {
    length=0
  }
  setmetatable(o, {
    __index=loop,
  })
  return o
end

mapid = 1
function api.MAP(flags)
  local map = require("lib/map")
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
  local menu = require("lib/menu")
  local o = {
    items=items
  }
  setmetatable(o, menu)
  o:init()
  return o
end

spr_info = api.SPRCODE("CIRCLED INFORMATION SOURCE")
spr_eject = api.SPRCODE("EJECT SYMBOL")

function api.MODE(name,parent)
  local mode = require("lib/mode")
  o = { name=name, parent=parent }
  if (o.parent) then
    setmetatable(o, {__index=o.parent})
  else
    setmetatable(o, {__index=mode})
  end
  cur_modes[o.name] = o
  api.LOG("New mode",o.name)
  return o
end

-- Memory functions
-- You can use POST to set as many fields as you like, for high scores and such.
-- but ordinary carts do not have access to these.
-- Readable state is handled by SAVE and is subject to validation rules:

function api.MEMORY()
  local cartid = cur_cartid
  switch_cart("_memory."..api.API, "Main", {
    switch_cart = switch_cart,
    draw_field = draw_field,
    memory = memory,
    cart = carts[cartid]
  })
end

function draw_field(item,y,include_desc)
  local margin = api.L
  local text_indent = api.S+api.L
  local text_width = api.W-text_indent-margin*2
  local oy = y
  api.COLOUR(0)
  if item.icon then
    api.SPR(item.icon,margin+api.S/2,y)
  end
  api.COLOUR(13)
  api.PRINT(item.name,margin+text_indent,y,1,-1)
  if item.desc and item.desc~="" and include_desc and not item.value then
    local lines = api.SPLIT(api.STR(item.desc),text_width/api.L," ")
    api.COLOUR(8)
    api.PRINTLINES(lines,margin+text_indent,y+api.L,1,-1)
    y = y + api.L*#lines
  end
  if item.value then
    local lines = api.SPLIT(api.STR(item.value),text_width/api.L," ")
    api.COLOUR(3)
    api.PRINTLINES(lines,margin+text_indent,y+api.L,1,-1)
    y = y + api.L*#lines
  end
  api.COLOUR(0)
  return y - oy + api.L
end

function api.DRAWFIELD(loc,y)
  if not memory[cur_cartid] then return y end
  if not memory[cur_cartid][loc] then return y end
  return draw_field(memory[cur_cartid][loc],y)
end

function api.FIELD(loc,icon,name,desc,rule,init_value)
  if not memory[cur_cartid] then memory[cur_cartid] = {} end
  if not memory[cur_cartid].fields then memory[cur_cartid].fields = {} end

  local field = memory[cur_cartid].fields[loc]
  if field then
    api.LOG("Retaining existing value ",field.value," for ",name)
    field.name=name
    field.desc=desc
    field.icon=icon
  else
    memory[cur_cartid].fields[loc] = { rule=rule, value=init_value, name=name, desc=desc, icon=icon }
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
  api.LOG("Saving state as ",s)
  return s
end

postrules = { -- FIXME: nicer way to specify the rule?
  function(old,new) return new end,
  function(old,new) return (old and old+new) or new end,
  function(old,new) return (old and math.max(old,new)) or new end,
  function(old,new) return (old and math.min(old,new)) or new end,
}

function api.POST(loc,value)
  api.LOG("POST",loc,value)
  if loc==0 then
    safe_value = validate_state(value)
    if not memory[cur_cartid] then memory[cur_cartid] = {} end
    memory[cur_cartid].state = safe_value
    --api.LOG("...memory now",memory[cur_cartid])
    save_memory(cur_cartid)
    return
  end
  if not memory[cur_cartid] then api.ERROR("POST to undefined cart "..cur_cartid) return end
  local field = memory[cur_cartid].fields and memory[cur_cartid].fields[loc]
  if not field then
    --api.LOG("...memory was",memory[cur_cartid])
    api.ERROR("POST to undefined field "..loc)
    return
  end
  local rule = postrules[field.rule or 1]
  field.value = rule(field.value,value)
  --api.LOG("...memory now",memory[cur_cartid])
  save_memory(cur_cartid)
end

function api.LOAD()
  local r = memory[cur_cartid] and memory[cur_cartid].state
  --api.LOG("Loaded state ",r)
  return r or {}
end

function api.SAVE(...)
  if not memory[cur_cartid] then memory[cur_cartid] = {} end
  local s = {...}
  if #s==0 then
    memory[cur_cartid].state = nil -- json library doesn't like empty arrays
  else
    memory[cur_cartid].state = s
  end
  save_memory(cur_cartid)
end

function api.TIMER(s)
  local now = love.timer.getTime()
  if s then
    timer_end_time = now+s
  else
    timer_end_time = false
  end
  if timer_end_time then
    return math.ceil(timer_end_time-now)
  else
    return math.ceil(mode_end_time-now)
  end
end

api.KEYWORDS = api

return api
