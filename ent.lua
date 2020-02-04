ent = {
    x=0,
    y=0,
    r=0,
    dx=0,
    dy=0,
    spr="@",
    c=nil
}
ent.__index = ent

local function is_on_screen(x, y, r)
  if x<r or y<r or x>n.api.W-r or y>n.api.H-r then
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

function ent:collides(other)
  local dx, dy = self.x-other.x, self.y-other.y
  return math.sqrt(dx*dx+dy*dy)<(self.r+other.r)
end

function ent:draw()
  if self.c then
    n.api.COLOUR(self.c)
  end
  n.api.SPR(self.spr, self.x, self.y)
end

return ent
