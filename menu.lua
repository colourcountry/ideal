menu = {
  colour = 0,
  topY = 0,
  scrollY = 0,
  initY = 0,
  boxY = 0,
  topY = 0,
  windowY = 0,
  boxSize = 0,
  separation = sys.api.L,
  cols = 3,
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
    local dy = 0
    for col=1,self.cols do
      local i = (row-1)*self.cols+col
      if not self.items[i] then
        break -- last row may not be full
      end
      self.items[i].x = (col-1)*dx
      self.items[i].y = y
      self.items[i].lines = sys.api.SPLIT(self.items[i].name:upper(), dx-self.separation)
      local this_dy = #self.items[i].lines*sys.api.L + self.separation
      if this_dy > dy then
        dy = this_dy
      end
    end
    y = y + dy
  end
  self.totalHeight = y
  self.scrollY = sys.api.H/2 - sys.api.L
  self.windowY = 100
end

function menu:DRAW()
  self.choice = nil
  for i=1, #self.items do
    local item = self.items[i]
    sys.api.COLOUR(self.colour)
    sys.api.PRINTLINES(item.lines, item.x, item.y+self.scrollY, 1, 1)
    sys.api.LOG(item)
  end
  sys.api.ERROR()
end

menu.draw = menu.DRAW

function menu:touch(x,y,isNew)
end

function oldtouch()
  if (isNew) then
    if y>self.boxY and y<(self.boxY+self.boxSize) then
      dragging = false
      sys.api.LOG(self.choice)
      self.choice.action()
      return
    end
    self.initY = y - self.scrollY
    dragging = true
  end
  if (dragging) then
    self.scrollY = math.max(math.min(20,y - self.initY),-self.totalHeight)
  end
  return
end

return menu
