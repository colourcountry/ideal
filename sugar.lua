local sugar = {}

function sugar.SIGN(number)
  return (number > 0 and 1) or (number == 0 and 0) or -1
end

function sugar.TWINKLE()
  api.COLOUR(api.T/5)
end

function api.PRINTLINES(strgs, x, y, anchor_x, anchor_y)
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
    local j = RND(i,#array)
    array[i], array[j] = array[j], array[i]
  end
end

function sugar.CHOOSE(array)
    return array[RND(1,#array)]
end

function sugar.SAVE(state)
  api.POST(0,state)
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
