ent = {
    x=0,
    y=0,
    r=0,
    dx=0,
    dy=0,
    spr="@",
    anim=nil,
    c=nil
}
ent.__index = ent

local function is_on_screen(x, y, r)
  if x<r or y<r or x>sys.api.W-r or y>sys.api.H-r then
    return false
  end
  return true
end

function ent:is_on_screen()
  return is_on_screen(self.x, self.y, self.r)
end

function ent:move()
  self.x = self.x + self.dx
  self.y = self.y + self.dy
  return
end

function ent:stop()
  self.dx = 0
  self.dy = 0
end

function ent:collides(other,xoff,yoff)
  local dx, dy, sr = self.x-(xoff or 0)-other.x, self.y-(yoff or 0)-other.y, self.r+other.r
  if math.abs(dx) < sr and math.abs(dy) < sr then
    return { dx=api.SIGN(dx)*sr-dx, dy=api.SIGN(dy)*sr-dy }
  end
end

function ent:ANIMATE(f)
  self.anim = f
end

function ent:DRAW()
  if self.c then
    sys.api.COLOUR(self.c)
  end
  if self.anim then
    sys.api.SPR(self.spr+self.anim(), self.x, self.y)
  else
    sys.api.SPR(self.spr, self.x, self.y)
  end
end

ent.draw = ent.DRAW

return ent
