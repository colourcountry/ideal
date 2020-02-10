map = {
  cx = 8,
  cy = 8,
  sx = 0,
  sy = 0,
  hx = nil,
  hy = nil,
  zx = nil,
  zy = nil,
  zw = nil,
  zh = nil
}
map.__index = map

function map:each(f,...)
  for i=1,self.sx do
    for j=1,self.sy do
      if self[i] and self[i][j] then
        f(self[i][j],i,j,...)
      end
    end
  end
end

function draw_with_text(e, mx, my, text_colour)
  e:draw()
  if e.text and text_colour then
    n.api.COLOUR(text_colour)
    n.api.PRINT(e.text,e.x,e.y,0,0)
  end
end

function map:draw(text_colour)
  love.graphics.push()
  love.graphics.translate(-self.cx*units,-self.cy*units)
  self:each(draw_with_text, text_colour)
  if self.hx and self.hy then
    n.api.COLOUR(1)
    n.api.CIRCLE(self.hx*16,self.hy*16,8)
  end
  if self.zx and self.zy then
    if not self.zw then
      self.zw = 1
    end
    if not self.zh then
      self.zh = 1
    end
    n.api.COLOUR(5)
    n.api.RECT(self.zx*16-8,self.zy*16-8,self.zw*16,self.zh*16)
  end
  love.graphics.pop()
end

function map:get(mx,my)
  if self[mx] then
    return self[mx][my]
  end
end

function map:set(mx,my,spr,c)
  if spr ~= " " then
    if not self[mx] then
      self[mx] = {}
    end
    if mx > self.sx then
      self.sx = mx
    end
    if my > self.sy then
      self.sy = my
    end
    self[mx][my] = n.api.ENT(mx*16,my*16,16,spr,c)
  end
  return self[mx][my]
end

function map:swap(mx,my,mx2,my2)
  local e, e2 = self:get(mx,my), self:get(mx2,my2)
  self[mx][my] = e2
  if e2 then
    e2.x, e2.y = mx*16, my*16
  end
  self[mx2][my2] = e
  if e then
    e.x, e.y = mx2*16, my2*16
  end
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
  return math.floor((x+8+self.cx)/16), math.floor((y+8+self.cy)/16)
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
  if mx<=0 or my<=0 or mx>self.sx or my>self.sy then
    return nil
  end
  if if_empty and self:get(mx,my) then
    return nil
  end
  if in_zone and (mx<self.zx or my<self.zy or mx>=self.zx+self.zw or my>=self.zy+self.zh) then
    return nil
  end
  self[mx][my] = e
  e.x, e.y = mx*16, my*16
  return mx,my
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

return map
