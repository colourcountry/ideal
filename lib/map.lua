map = {
  cx = 0,
  cy = 0,
  sx = 0,
  sy = 0,
  hx = nil,
  hy = nil,
  zx = nil,
  zy = nil,
  zw = nil,
  zh = nil,
  canvas = nil,
}
map.__index = map

S = api.S

function map:ITEMS()
  local all_items = {}
  for j=1,self.sy do
    for i=1,self.sx do
      if self[i] and self[i][j] then
        all_items[#all_items+1]=self[i][j]
      end
    end
  end
  i=0
  return function()
    if i<#all_items then
      i=i+1
      return all_items[i]
    end
  end
end

function draw_with_text(e, text_colour)
  e:DRAW()
  if e.text and text_colour then
    api.COLOUR(text_colour)
    api.PRINT(e.text,e.x,e.y,0,0)
  end
end

function map:DRAW()
  if not self.canvas then return end
  self.canvas:start()
  api.CLS()
  for e in self:ITEMS() do
    e:DRAW()
  end
  --[[ FIXME do I still want this
  if self.hx and self.hy then
    api.COLOUR(1)
    api.CIRCLE(self.hx*S,self.hy*S,8)
  end
  if self.zx and self.zy then
    if not self.zw then
      self.zw = 1
    end
    if not self.zh then
      self.zh = 1
    end
    api.COLOUR(5)
    api.RECT(self.zx*S-8,self.zy*S-8,self.zw*S,self.zh*S)
  end
  ]]
  self.canvas:stop()
  api.COLOUR(0)
  self.canvas:paste(-self.cx,-self.cy)
end

function map:POS(x,y)
  if x then self.cx = x end
  if y then self.cy = y end
  return self
end

function map:UPDATE()
  for e in self:ITEMS() do
    if e.moving then
      if e.moving<=0 then
        if self:get(e.mx,e.my).id == e.id then
          self:unset(e.mx,e.my)
        end
        self:put_entity(e,e.goal_mx,e.goal_my)
        e.moving = nil
      else
        e:POS(e.goal_mx*S, e.goal_my*S, e.moving)
        e.moving = e.moving-1
      end
    end
  end
end

function map:oob(x,y)
  if x<1 or x>self.sx or y<1 or y>self.sy then
    return true
  end
  return false
end

function map:get(mx,my)
  if self[mx] then
    return self[mx][my]
  end
end

function map:unset(mx,my)
  if self[mx] then
    self[mx][my] = nil
  end
end

function map:put_entity(e,mx,my)
  e.mx = mx
  e.my = my
  e.x = mx*S
  e.y = my*S
  e.map = self
  if not self[mx] then
    self[mx] = {}
  end
  self[mx][my] = e
  return self[mx][my]
end

function map:put(spr,mx,my,c)
  if spr == " " then
    self.unset(mx,my)
    return
  end
  if mx > self.sx then
    self.sx = mx
    self.canvas = new_canvas((self.sx+1)*S,(self.sy+1)*S)
  end
  if my > self.sy then
    self.sy = my
    self.canvas = new_canvas((self.sx+1)*S,(self.sy+1)*S)
  end
  local e = api.ENT(spr,0,0,c,S/2):set(self.flagsets[spr])
  return self:put_entity(e,mx,my)
end

function map:move(e,dx,dy,t)
  if not e then
    return
  end
  if not e.mx then
    self:grab(e)
  end
  if self:oob(
  e.mx+dx,e.my+dy) then
    return -- can't move off the map, extend with map:put first
  end
  if not t or t==0 then
    self:put_entity(e,e.mx+dx,e.my+dy)
    return
  end
  e.goal_mx = e.mx+dx
  e.goal_my = e.my+dy
  e.moving = t -- = number of frames left to move
end

function map:fromLines(lines,c)
  for j=1,#lines do
    for i=1,#lines[j] do
      self:put(lines[j][i],j,i)
    end
  end
end

function map:empty()
  for i=1,self.sx do
    for j=1,self.sy do
      self:unset(i,j)
    end
  end
  self.sx = 0
  self.sy = 0
end

function map:coord(x,y)
  return x+self.cx, y+self.cy
end

function map:cell(x,y)
  return math.floor((x+self.cx)/S+0.5), math.floor((y+self.cy)/S+0.5)
end

function map:whereis(e) -- return the real world coordinate of this entity without freeing it
  -- FIXME this is not IDEAL as a "class method", should probably be a builtin
  if e.map then
    api.LOG("mapmap",e)
    return e.x-e.map.cx, e.y-e.map.cy
  end
  return e.x, e.y
end

function map:under(e) -- given an entity, what map entity is at the same place
  local mx,my = self:cell(self:whereis(e))
  api.LOG("under",e,mx,my)
  return self:get(mx,my), mx, my
end

function map:highlight(mx,my)
  if mx and my then
    if mx>0 and my>0 and mx<=self.sx and my<=self.sy then
      self.hx, self.hy = mx, my
      return
    end
  end
  self.hx, self.hy = nil, nil
end

function map:zone(mx,my,mw,mh)
  self.zx, self.zy, self.zw, self.zh = mx, my, mw, mh
end

function map:grab(e,if_empty,in_zone)
  local mx, my = self:coord(e.x,e.y)
  if if_empty and self:get(mx,my) then
    return nil
  end
  if in_zone and (mx<self.zx or my<self.zy or mx>=self.zx+self.zw or my>=self.zy+self.zh) then
    return nil
  end
  return self:put_entity(e,mx,my)
end

function map:free(e)
  -- FIXME this is a bit weird because it doesn't actually need to belong to this map anymore
  e.map:unset(e.x/S,e.y/S)
  if e then
    e.x = e.x - e.map.cx
    e.y = e.y - e.map.cy
    e.map = nil
  end
  --api.LOG("Freed",e,"from",mx,my)
  return e
end

function map:anchor(x,y,ax,ay)
  ax = ax or 0
  ay = ay or 0
  local hs = S/2
  local msx = (self.sx+2)*hs
  local msy = (self.sy+2)*hs
  self.cx = msx*(1-ax)-x-hs
  self.cy = msy*(1-ay)-y-hs
  --api.LOG("Centred map on ",x,",",y," origin now ",self.cx,",",self.cy)
end

function map:_check_collision(e,mx,my)
  if self:oob(mx,my) then return end
  local o = self:get(mx,my)
  if not o or o==e then return end
  return o:collides(e)
end

function map:collisions(e, r) -- FIXME make iterable rather than just returning 1
  r = r or 1
  local mx, my = self:cell(self:whereis(e))
  for mix=mx-r, mx+r do
    for miy=my-r,my+r do
      local r = self:_check_collision(e,mix,miy)
      if r then return r end
    end
  end
end

return map
