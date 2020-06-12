loop = {
  length=0,
  path={}
}
loop.__index = loop

function loop:add(x,limit)
  if not x then return end
  sys.api.LOG("Adding id ",x.id,"to",self)
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

  if limit and self.length>limit then
    return self:rot()
  end
end

function loop:LOG()
  if self.length==0 then
    return "Loop of 0"
  end
  local s = "Loop of "..tostring(self.length)..": "..tostring(self.first).."="..tostring(self.items[self.first].id).."; "
  local i = self.path[self.first]
  local b = 0
  while i ~= self.first do
    b = b + 1
    s = s..tostring(i).."="..tostring(self.items[i].id)..", "
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
  sys.api.LOG("Removing index ",i,"from",self)
  if not self.items[i] then
    sys.api.LOG("Index",i,"was not in the loop!")
    return
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
  -- self.path[i] = nil -- leave the path back into the loop, in case we are iterating
  -- self.rpath[i] = nil
  self.items[i] = nil
  self.length = self.length - 1
end

function loop:ITEMS()
  local i = self.first
  local prev_first = nil
  return function()
    if not self.items then
      return
    end
    if i == self.first then
      if self.first ~= prev_first then
        -- either the first time round, or the first item has been removed
        prev_first = self.first
      else
        -- we have reached this item for a second time
        return
      end
    end
    local o = i
    i = self.path[i]
    --api.LOG("Loop is",self)
    while not self.items[o] do
      api.LOG("Some items removed, finding way back to loop:",i,self.path[i],self.items[i])
      o = i
      i = self.path[i]
    end
    return o, self.items[o]
  end
end

function loop:DRAW()
  for i, obj in self:ITEMS() do
    obj:DRAW()
  end
end

loop.draw = loop.DRAW

function loop:pop()
  if self.length==0 then
    return nil
  end
  local last = self.rpath[self.first]
  local p = self.items[last]
  self:remove(last)
  return p
end

function loop:rot()
  if self.length==0 then
    return nil
  end
  local p = self.items[self.first]
  self:remove(self.first)
  return p
end

function loop:peek()
  if not self.length or self.length<=0 then
    return nil
  end
  return self.items[self.rpath[self.first]]
end

return loop
