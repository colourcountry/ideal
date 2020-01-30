menu = {
  colour = 0,
  topY = 0,
  scrollY = 0,
  initY = 0,
  boxY = 0,
  topY = 0,
  windowY = 0,
  boxSize = 0,
  separation = 4*system_font_size,
}
menu.__index = menu

dragging = false

function menu:init(sortFn)
  if (not self.width) then
    self.width = n.api.W
  end
  local y = 0
  self.enum = {}
  self.enumY = {}
  self.itemsSplit = {}
  for k in pairs(self.items) do
    table.insert(self.enum,k)
  end
  table.sort(self.enum, sortFn)
  for i,k in pairs(self.enum) do
    self.enumY[i] = y
    self.itemsSplit[k] = n.api.SPLIT(self.items[k], self.width, true)
    y = y + (#self.itemsSplit[k]+1)*system_line_height
  end
  self.totalHeight = y
  self.centreY = n.api.H/2 - system_line_height
  self.windowY = 100
end

function menu:draw()
  self.choice = nil
  for i=1, #self.enum do
    local k = self.enum[i]
    local l = self.itemsSplit[k]
    local y = self.scrollY+self.enumY[i]
    if y>-(self.windowY+system_line_height) and y<self.windowY then
      if ((y>=0 or i==#self.items) and not self.choice) then
        self.choice = k
        self.boxY = y+self.centreY
        self.boxSize = system_line_height*(1+#l)
        n.api.COLOUR()
        n.api.RECT(10,y+self.centreY,n.api.W-20,self.boxSize)
        n.api.PRINTLINES(l, n.api.W/2, y+8+self.centreY, 0, 0)
      else
        n.api.COLOUR(self.colour)
        n.api.PRINTLINES(l, n.api.W/2, y+8+self.centreY, 0, 0)
      end
    end
  end
end

function menu:touch(x,y,isNew)
  if (isNew) then
    if y>self.boxY and y<(self.boxY+self.boxSize) then
      dragging = false
      return self.choice
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
