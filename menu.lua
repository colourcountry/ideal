menu = {
  colour = 0,
  topY = 0,
  scrollY = 0,
  initY = 0,
  boxY = 0,
  topY = 0,
  windowY = 0,
  boxSize = 0,
  separation = 4*sys.api.L,
}
menu.__index = menu

dragging = false

function menu:init()
  if (not self.width) then
    self.width = sys.api.W
  end
  local y = 0
  self.itemsY = {}
  self.namesSplit = {}
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
  for i=1,#self.items do
    self.itemsY[i] = y
    self.namesSplit[i] = sys.api.SPLIT(self.items[i].name:upper(), self.width, true)
    y = y + (#self.namesSplit[i]+1)*sys.api.L
  end
  self.totalHeight = y
  self.centreY = sys.api.H/2 - sys.api.L
  self.windowY = 100
end

function menu:DRAW()
  self.choice = nil
  for i=1, #self.items do
    local y = self.scrollY+self.itemsY[i]
    if y>-(self.windowY+sys.api.L) and y<self.windowY then
      if ((y>=0 or i==#self.items) and not self.choice) then
        self.choice = self.items[i]
        self.boxY = y+self.centreY
        self.boxSize = sys.api.L*(1+#self.namesSplit[i])
        sys.api.COLOUR()
        sys.api.RECT(10,y+self.centreY,sys.api.W-20,self.boxSize)
        sys.api.PRINTLINES(self.namesSplit[i], sys.api.W/2, y+8+self.centreY, 0, 0)
      else
        sys.api.COLOUR(self.colour)
        sys.api.PRINTLINES(self.namesSplit[i], sys.api.W/2, y+8+self.centreY, 0, 0)
      end
    end
  end
end

menu.draw = menu.DRAW

function menu:touch(x,y,isNew)
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
