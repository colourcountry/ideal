local sugar = {}

function sugar.SIGN(number)
  return (number > 0 and 1) or (number == 0 and 0) or -1
end

function sugar.TWINKLE()
  api.COLOUR(api.T/3)
end
help[sugar.TWINKLE]=[[Set the current colour to a rainbow cycling effect.
]]

local segs = {
  ["0"]=0x1fbf0, ["1"]=0x1fbf1, ["2"]=0x1fbf2, ["3"]=0x1fbf3,
  ["4"]=0x1fbf4, ["5"]=0x1fbf5, ["6"]=0x1fbf6, ["7"]=0x1fbf7,
  ["8"]=0x1fbf8, ["9"]=0x1fbf9,
  ["@"]=0xff010, ["a"]=0xff011, ["b"]=0xff012, ["c"]=0xff013,
  ["d"]=0xff014, ["e"]=0xff015, ["f"]=0xff016, ["g"]=0xff017,
  ["h"]=0xff018, ["i"]=0xff019, ["j"]=0xff01a, ["k"]=0xff01b,
  ["l"]=0xff01c, ["m"]=0xff01d, ["n"]=0xff01e, ["o"]=0xff01f,
  ["p"]=0xff020, ["q"]=0xff021, ["r"]=0xff022, ["s"]=0xff023,
  ["t"]=0xff024, ["u"]=0xff025, ["v"]=0xff026, ["w"]=0xff027,
  ["x"]=0xff028, ["y"]=0xff029, ["z"]=0xff02a
}
function sugar.SEGMENTDISPLAY(strg,x,y) -- FIXME anchor_x etc
  strg = api.STR(strg)
  for i=1,#strg do
    local spr = segs[api.CHARAT(strg,i)] or 32
    api.SPR(spr,x,y)
    x = x + api.S
  end
end

function sugar.PRINTLINES(strgs, x, y, anchor_x, anchor_y)
  for i,s in api.ITEMS(strgs) do
    if (i==1) then
      api.PRINT(s, x, y, anchor_x, anchor_y) --FIXME: assumes first line is longest
    else
      api.PRINT(s, nil, nil, 1, 0)
    end
  end
  return #strgs
end

sugar.CIRCLE = api.RING
sugar.RECT = api.BOX

function sugar.BOXTITLE(strg, y, fg, bg)
  local margin = api.S/2
  y = y+margin
  local lines = api.SPLIT(strg,(api.W-margin*2)/api.S," ")
  local h = (#lines+1)*api.S
  if bg then
    api.COLOUR(bg)
    api.BLOCK(api.S/2,y,api.W-api.S,h)
  end
  api.COLOUR(fg or 13)
  api.BOX(api.S/2,y,api.W-api.S,h)
  for i,s in api.ITEMS(lines) do
    if (i==1) then
      api.TITLE(s, api.W/2, y+api.S, 0, 0)
    else
      api.TITLE(s, api.W/2, nil, 0, 0)
    end
  end
  return y+margin
end

function sugar.QUADRANT(x, y)
  if x==y or x==-y then
    local p = api.RND()
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

function sugar.DIRECTION(x,y,s)
  a = api.SQRT(x*x+y*y)
  if (s) then
    return x*s/a, y*s/a, a
  else
    return x/a, y/a, a
  end
end

function sugar.SHUFFLE(array)
  for i=1,#array-1 do
    local j = api.RND(i,#array)
    array[i], array[j] = array[j], array[i]
  end
end

function sugar.CHOOSE(array)
    return array[api.RND(1,#array)]
end

-------------------------------------------------------------------- Object "methods"
-- To make it a bit more BASICy, these global functions just call named methods of the object

function sugar.DRAW(o)
  if not o then return end
  if o.DRAW then
    o:DRAW()
  else
    api.LOG("ERROR: Can't draw object ",o)
    api.ERROR("Can't draw this")
  end
end

function sugar.UPDATE(o)
  if not o then return end
  if o.UPDATE then
    o:UPDATE()
  else
    api.LOG("ERROR: Can't update object ",o)
    api.ERROR("Can't update this")
  end
end

function sugar.ANIMATE(o,f)
  if not o then return end
  if o.ANIMATE then
    o:ANIMATE(f)
  else
    api.LOG("ERROR: Can't draw object ",o)
    api.ERROR("Can't draw this")
  end
end

--------------------------------------------------------------- Style and design

function sugar.MAINMENU(modelist)
  local m = {}
  for i=1,#modelist do
    m[#m+1] = { name=modelist[i].name, icon=modelist[i].icon, action=function() api.GO(modelist[i]) end }
  end
  m[#m+1] = { name="Info", icon=spr_info, action=api.MEMORY }
  m[#m+1] = { name="Eject", icon=spr_eject, action=api.EJECT }
  return api.MENU(m)
end

return sugar
