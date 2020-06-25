ent = {
    x=0,
    y=0,
    r=0,
    dx=0,
    dy=0,
    ddx=0,
    ddy=0,
    spr="@",
    anim=nil,
    c=nil,
}

function ent:LOG()
  return "<<"..tostring(self.id)..":"..string.format("%x", self.spr).." x"..tostring(self.x).."y"..tostring(self.y)..">>"
end

function ent:set(f)
  if not f then return self end
  for k,v in pairs(f) do
    self.flags[k]=v
  end
  return self
end

function ent:IS(spr)
  return (spr==self.spr)
end

local function oob(x, y, r)
  if x<r or y<r or x>api.W-r or y>api.H-r then
    return true
  end
  return false
end

function ent:oob()
  return oob(self.x, self.y, self.r)
end

function ent:UPDATE()
  self.x = self.x + self.dx
  self.y = self.y + self.dy
  self.dx = self.dx + self.ddx
  self.dy = self.dy + self.ddy
  return self
end

function ent:repel(cfn)
  if (self.dx==0 and self.dy==0) then return end
  local ox, oy = self.x, self.y
  self.x = self.x + self.dx
  local c = cfn(self)
  if c then
    self.x = self.x-c.dx -- only relevant during y-axis collision calculation
    self.dx = self.dx-c.dx
  end
  self.y = self.y + self.dy
  c = cfn(self)
  if c then
    self.dy = self.dy-c.dy
  end
  self.x = ox
  self.y = oy
end

function ent:POS(x,y,frames)
  if frames and frames>1 then
    if x then self.x = self.x + (x-self.x)/frames end
    if y then self.y = self.y + (y-self.y)/frames end
    return self
  end
  if x then self.x = x end
  if y then self.y = y end
  return self
end

function ent:VEL(dx,dy)
  if dx then self.dx = dx end
  if dy then self.dy = dy end
  return self
end

function ent:DAMP(d)
  self.dx = self.dx * (1-d)
  self.dy = self.dy * (1-d)
end

function ent:ACC(ddx, ddy)
  if ddx then self.ddx = ddx end
  if ddy then self.ddy = ddy end
  return self
end

function ent:stop()
  self.dx = 0
  self.dy = 0
  return self
end

function ent:collides(other)
  local dx, dy, sr = self.x-other.x, self.y-other.y, self.r+other.r
  if math.abs(dx) < sr and math.abs(dy) < sr then
    return { e=self, o=other, dx=sugar.SIGN(dx)*sr-dx, dy=sugar.SIGN(dy)*sr-dy }
  end
end

function ent:near(x,y,grace)
  local r = (grace and self.r+grace) or self.r
  if math.abs(self.x-x) < self.r and math.abs(self.y-y) < self.r+grace then
    return true
  end
  return false
end

function ent:ANIMATE(f)
  self.anim = f
  return self
end

function ent:DRAW()
  if self.c then
    api.COLOUR(self.c)
  end
  if self.anim then
    api.SPR(self.spr+math.floor(self.anim()), self.x, self.y)
  else
    api.SPR(self.spr, self.x, self.y)
  end
end

ent.draw = ent.DRAW

return ent
