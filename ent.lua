ent = {
    x=0,
    y=0,
    r=0,
    dx=0,
    dy=0,
    spr="@",
}
ent.__index = ent

local function is_on_screen(x, y, r)
  if x<r or y<r or x>n.api.width-r or y>n.api.height-r then
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
  if (not sprts[self.spr]) then
    sprts[self.spr] = love.graphics.newText(sprite_font, self.spr)
  end
  print_text(sprts[self.spr], self.x, self.y, 0, 0)
end

return ent
