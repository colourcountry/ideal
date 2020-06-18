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
        e.x = e.x + (e.goal_mx*S-e.x)/e.moving
        e.y = e.y + (e.goal_my*S-e.y)/e.moving
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
  return math.floor((x+8+self.cx)/S), math.floor((y+8+self.cy)/S)
end

function map:whereis(e) -- return the real world coordinate of this entity without freeing it
  return e.x-self.cx, e.y-self.cy
end

function map:under(e) -- given a free entity, what map entity is at the same place
  local mx,my = self:coord(e.x,e.y)
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
  self:unset(e.x/S,e.y/S)
  if e then
    e.x = e.x - self.cx
    e.y = e.y - self.cy
  end
  --api.LOG("Freed",e,"from",mx,my)
  return e
end

function map:centre(x,y)
  local hs = S/2
  self.cx = (self.sx+2)*hs-x-hs
  self.cy = (self.sy+2)*hs-y-hs
  --api.LOG("Centred map on ",x,",",y," origin now ",self.cx,",",self.cy)
end

function map:collides(e)
  return self:each(function(m)
    local c = m:collides(e,self.cx,self.cy)
    if c then
      return { ent=m, dx=c.dx, dy=c.dy }
    end
  end)
end

function map:move_and_repel(e)
  if (e.dx==0 and e.dy==0) then return end
  e.x = e.x + e.dx
  local c = self:collides(e)
  if c then
    e.x = e.x - c.dx
  end
  e.y = e.y + e.dy
  c = self:collides(e)
  if c then
    e.y = e.y - c.dy
  end
end

return map
