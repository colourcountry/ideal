menu = {
  text_colour = 13,
  highlight_colour = 14,
  topY = 0,
  scrollY = 0,
  initY = 0,
  boxY = 0,
  topY = 0,
  windowY = 0,
  boxSize = 0,
  separation = sys.api.L,
  cols = 2,
  sensitivity = 5,
  prevY = 0,
  inertia = 0,
}
menu.__index = menu

dragging = false

function menu:init()
  if (not self.width) then
    self.width = sys.api.W
  end

  local validItems = {}
  for i=1,#self.items do
    if not self.items[i].name then
      sys.api.LOG("ERROR: menu item requires a 'name': ",self.items[i])
    else
      if not self.items[i].action then
        sys.api.LOG("ERROR: menu item requires an 'action': ",self.items[i])
      else
        validItems[#validItems+1]=self.items[i]
      end
    end
  end
  self.items = validItems

  local y = 0
  local dx = (self.width + self.separation)/self.cols

  for row=1,math.ceil(#self.items/self.cols) do
    local dy = dx/2
    for col=1,self.cols do
      local i = (row-1)*self.cols+col
      if not self.items[i] then
        break -- last row may not be full
      end
      self.items[i].x = (col-1)*dx
      self.items[i].y = y
      self.items[i].lines = sys.api.SPLIT(self.items[i].name, (dx-self.separation)/sys.api.L," ")
      api.LOG(self.items[i].lines,self.items[i].name,dx-self.separation)
      local this_dy = #self.items[i].lines*sys.api.L + self.separation
      if self.items[i].icon then
        this_dy = this_dy + sys.api.S*2
      end
      if this_dy > dy then
        dy = this_dy
      end
    end
    y = y + dy
    for col=1,self.cols do
      local i = (row-1)*self.cols+col
      if not self.items[i] then
        break -- last row may not be full
      end
      self.items[i].w = dx-self.separation
      self.items[i].h = dy-self.separation
    end
  end
  self.totalHeight = y
  self.offset = sys.api.H/2 - sys.api.L
  self.dragOffset = 0
  self.selected = 0
  self.windowY = 100
end

function menu:DRAW()
  self.choice = nil
  for i=1, #self.items do
    local item = self.items[i]
    if self.selected==i then
      sys.api.COLOUR(self.highlight_colour)
      sys.api.BLOCK(item.x,item.y+self.offset+self.dragOffset,item.w,item.h)
    end
    sys.api.COLOUR(self.text_colour)
    local x = item.x
    local y = item.y+self.offset+self.dragOffset
    if item.icon then
      sys.api.PRINTLINES(item.lines, x+item.w/2, y+sys.api.S*2, 0, 0)
      sys.api.COLOUR(item.colour or 0)
      sys.api.SPR(item.icon,x+item.w/2,y+sys.api.S)
    else
      sys.api.PRINTLINES(item.lines, x+item.w/2, y+item.h/2, 0, 0)
    end
  end
end

menu.draw = menu.DRAW

function menu:handle_touch(x,y)
  if y < self.offset+self.dragOffset then
    return
  end
  for i=1, #self.items do
    if y < self.items[i].y+self.items[i].h+self.offset+self.dragOffset and x < self.items[i].x+self.items[i].w then
      self.selected = i
      break
    end
  end
end

function menu:handle_drag(ox,oy,x,y)
  self.dragOffset = y-oy
end

function menu:handle_release(ox,oy,x,y)
  local dx,dy,d = sugar.DIRECTION(x-ox,y-oy)
  if self.selected>0 and d<self.sensitivity then
    self.items[self.selected].action()
  end
  self.offset = self.offset + y-oy
  self.dragOffset = 0
  self.selected = 0
end

return menu
