loop = {
  length=0,
}
loop.__index = loop

function loop:add(x)
  if not x then return end
  if self.length<0 then
    sys.api.LOG("Length??",self)
  end
  if not self.length or self.length<=0 then
    self.path={[1]=1}
    self.rpath={[1]=1}
    self.first=1
    self.items={[1]=x}
    self.length=1
    self.top=2
    return
  end
  self.items[self.top] = x
  local last = self.rpath[self.first]
  self.path[last] = self.top
  self.rpath[self.top] = last
  self.path[self.top] = self.first
  self.rpath[self.first] = self.top
  self.length = self.length + 1
  self.top = self.top + 1
end

function loop:LOG()
  local s = tostring(self.length)..": "..tostring(self.first)..";"
  local i = self.path[self.first]
  local b = 0
  while i ~= self.first do
    b = b + 1
    s = s..tostring(i)..","
    i = self.path[i]
    if not i then
      s = s.." nil?"
      break
    end
    if b > self.length then
      s = " len?"
      break
    end
  end
  return s
end

function loop:remove(i)
  sys.api.LOG("Removing",i,"from",self)
  if not self.path[i] then
    return -- shrug
  end
  if self.length <= 1 then
    self.length = 0
    return
  end
  self.rpath[self.path[i]] = self.rpath[i]
  self.path[self.rpath[i]] = self.path[i]
  if self.first == i then
    self.first = self.path[i]
  end
  self.path[i] = nil
  self.rpath[i] = nil
  self.items[i] = nil
  self.length = self.length - 1
end

function loop:ITEMS()
  local i = self.first
  local b = 1
  return function()
    if b > self.length then
      return
    end
    local o = i
    i = self.path[i]
    b = b+1
    if self.items[o] then
      return o, self.items[o]
    end
  end
end

function loop:DRAW()
  sys.api.LOG("Drawing",self)
  for i, obj in self:ITEMS() do
    DRAW(obj)
  end
end

loop.draw = loop.DRAW

function loop:pop()
  if self.length==0 then
    return nil
  end
  local p = self.items[self.first]
  self:remove(self.first)
  return p
end

return loop
