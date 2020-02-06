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

function map:draw(text_colour)
  love.graphics.push()
  love.graphics.translate(-self.cx,-self.cy)
  for i=1,self.sx do
    for j=1,self.sy do
      if self[i] and self[i][j] then
        self[i][j]:draw()
        if self[i][j].text and text_colour then
          n.api.COLOUR(text_colour)
          n.api.PRINT(self[i][j].text,self[i][j].x,self[i][j].y,0,0)
        end
      end
    end
  end
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

function map:fromLines(lines,c)
  for j=1,#lines do
    for i=1,#lines[j] do
      self:set(j,i,lines[j][i])
    end
  end
end


function map:clear(mx,my)
  if self[mx] then
    self[mx][my] = nil
  end
end

function map:empty()
  for i=1,self.sx do
    for j=1,self.sy do
      self:clear(i,j)
    end
  end
  self.sx = 0
  self.sy = 0
end

function map:highlight(x,y)
  if x and y then
    local hx, hy = math.floor((x+8+self.cx)/16), math.floor((y+8+self.cy)/16)
    if hx>0 and hy>0 and hx<=self.sx and hy<=self.sy then
      self.hx, self.hy = hx, hy
      return
    end
  end
  self.hx, self.hy = nil, nil
end

function map:zone(x,y,w,h)
  self.zx, self.zy, self.zw, self.zh = x, y, w, h
end

function map:at(x,y)
  local mx = math.floor((x+8+self.cx)/16)
  if self[mx] then
    local my = math.floor((y+8+self.cy)/16)
    return self[mx][my]
  end
end

function map:grab(ent,if_empty,in_zone)
  local mx, my = math.floor((ent.x+8+self.cx)/16), math.floor((ent.y+8+self.cy)/16)
  if mx<=0 or my<=0 or mx>self.sx or my>self.sy then
    return false
  end
  if if_empty and self[mx][my] then
    return false
  end
  if in_zone and (mx<self.zx or my<self.zy or mx>=self.zx+self.zw or my>=self.zy+self.zh) then
    return false
  end
  self[mx][my] = ent
  ent.x, ent.y = mx*16, my*16
  return true
end

function map:free(ent)
  local mx, my = math.floor(ent.x/16), math.floor(ent.y/16)
  if self[mx][my] ~= ent then
    n.api.DIE("INCONSISTENT MAP")
  end
  ent.x = ent.x + self.cx
  ent.y = ent.y + self.cy
end

function map:centre(x,y)
  self.cx = (self.sx*8)-x+8
  self.cy = (self.sy*8)-y+8
end

return map
