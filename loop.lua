loop = {
  length=0,
}
loop.__index = loop

function loop:add(x)
  if not x then return end
  if not self.length or self.length==0 then
    self.path={[1]=1}
    self.rpath={[1]=1}
    self.first=1
    self[1]=x
    self.length=1
    self.top=2
    return
  end
  self[self.top] = x
  local last = self.rpath[self.first]
  self.path[last] = self.top
  self.rpath[self.top] = last
  self.path[self.top] = self.first
  self.rpath[self.first] = self.top
  self.length = self.length + 1
  self.top = self.top + 1
end

function loop:print()
  if self.length==0 then
    print("0.")
    return
  end
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
  print(s)
end

function loop:remove(i)
  if not self.path[i] then
    return -- shrug
  end
  if self.length == 1 then
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
  self[i] = nil
  self.length = self.length - 1
end

function loop:each(f)
  if self.length == 0 then
    return
  end
  local i = self.first
  if self[i] then
    f(self[i], function()
      self:remove(i)
    end)
  end
  i = self.path[i]
  while i and i ~= self.first do
    if self[i] then
      f(self[i], function() self:remove(i) end)
    end
    i = self.path[i]
  end
end

function loop:pop()
  if self.length==0 then
    return nil
  end
  local p = self[self.first]
  self:remove(self.first)
  return p
end

return loop
