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
  tint = nil
}
map.__index = map

S = sys.api.S

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
    sys.api.COLOUR(text_colour)
    sys.api.PRINT(e.text,e.x,e.y,0,0)
  end
end

function map:DRAW()
  if not self.canvas then return end
  local tint = colours[self.tint] or {1,0,0}
  self.canvas:start()
  api.CLS()
  for e in self:ITEMS() do
    if api.IS(e,"tint") then -- FIXME: magic word
      self.canvas:colour(tint)
    else
      self.canvas:colour({1,0,0})
    end
    draw_with_text(e,text_colour)
  end
  if self.hx and self.hy then
    sys.api.COLOUR(1)
    sys.api.CIRCLE(self.hx*S,self.hy*S,8)
  end
  if self.zx and self.zy then
    if not self.zw then
      self.zw = 1
    end
    if not self.zh then
      self.zh = 1
    end
    sys.api.COLOUR(5)
    sys.api.RECT(self.zx*S-8,self.zy*S-8,self.zw*S,self.zh*S)
  end
  self.canvas.stop()
  self.canvas.paste()
end

function map:UPDATE()
  for e in self:ITEMS() do
    if e.goal_t then
      if e.goal_t<=0 then
        if self:get(e.mx,e.my).id == e.id then
          self:unset(e.mx,e.my)
        end
        self:set_entity(e.goal_mx,e.goal_my,e)
        e.goal_t = nil
      else
        e.x = e.x + (e.goal_mx*S-e.x)/e.goal_t
        e.y = e.y + (e.goal_my*S-e.y)/e.goal_t
        e.goal_t = e.goal_t-1
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

function map:set_entity(mx,my,e)
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

function map:set(mx,my,spr,c)
  if spr == " " then
    self.unset(mx,my)
    return
  end
  if mx > self.sx then
    self.sx = mx
    self.canvas = sys.new_canvas(self.sx*api.S,self.sy*api.S)
  end
  if my > self.sy then
    self.sy = my
    self.canvas = sys.new_canvas(self.sx*api.S,self.sy*api.S)
  end
  spr = sys.sprites.names[spr] or spr
  local e = sys.api.ENT(0,0,8,spr,c,self.flagsets[spr])
  return self:set_entity(mx,my,e)
end

function map:move(e,dx,dy,t)
  if not e then
    return
  end
  if not e.mx then
    self:grab(e)
  end
  if self:oob(e.mx+dx,e.my+dy) then
    return --can't move off the map, extend with map:set first
  end
  if not t or t==0 then
    self:set_entity(e.mx+dx,e.my+dy,e)
    return
  end
  e.goal_mx = e.mx+dx
  e.goal_my = e.my+dy
  e.goal_t = t
end

function map:fromLines(lines,c)
  for j=1,#lines do
    for i=1,#lines[j] do
      self:set(j,i,lines[j][i])
    end
  end
end


function map:remove(mx,my)
  if self[mx] then
    self[mx][my] = nil
  end
end

function map:empty()
  for i=1,self.sx do
    for j=1,self.sy do
      self:remove(i,j)
    end
  end
  self.sx = 0
  self.sy = 0
end

function map:coord(x,y)
  return math.floor((x+8+self.cx)/S), math.floor((y+8+self.cy)/S)
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
  return self:set_entity(mx,my,e)
end

function map:free(mx, my)
  local e = self:get(mx,my)
  self:remove(mx,my)
  if e then
    e.x = e.x - self.cx
    e.y = e.y - self.cy
  end
  return e
end

function map:centre(x,y)
  self.cx = (self.sx*8)-x+8
  self.cy = (self.sy*8)-y+8
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

function map:tint(c)
  self.tint = c
end

return map
