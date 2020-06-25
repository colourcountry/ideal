-- FIXME this is getting a bit messy, there's probably a better algorithm

loop = {
  length=0,
  path={}
}

function loop:add(x,limit)
  if not x then
    ERROR("Missing parameter","Not enough parameters to loop:add")
    return
  end
  if self.length<0 then
    ERROR("Bad loop","Loop of negative length:",self)
  end
  if not self.length or self.length==0 then
    self.path={[1]=1}
    self.rpath={[1]=1}
    self.first=1
    self.items={[1]=x}
    self.ritems={[x]=1}
    self.length=1
    self.top=2
    --api.LOG("Added first item, now",self)
    return
  end
  self.items[self.top] = x
  self.ritems[x]=self.top
  local last = self.rpath[self.first]
  self.path[last] = self.top
  self.rpath[self.top] = last
  self.path[self.top] = self.first
  self.rpath[self.first] = self.top
  self.length = self.length + 1
  self.top = self.top + 1

  --api.LOG("Added item, now",self)

  if limit and self.length>limit then
    return self:rot()
  end
  return self
end

function loop:LOG()
  local s = "Loop of "..tostring(self.length)..": "..tostring(self.first).."="..tostring(self.items and self.items[self.first] and self.items[self.first].id).."; "
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

function loop:IN(x)
  if not x then
    api.ERROR("Missing parameter","Not enough parameters to loop:IN")
  end
  return (self.ritems and self.ritems[x] and true) or false
end

function loop:remove(x)
  if not x then
    api.ERROR("Missing parameter","Not enough parameters to loop:remove")
  end
  local i = self.ritems and self.ritems[x]
  if not i then
    api.LOG("WARNING:",x,"was not in",self)
    return
  end
  self.items[i] = nil
  self.ritems[x] = nil
  if self.length <= 1 then
    self.length = 0
    return
  end
  self.rpath[self.path[i]] = self.rpath[i]
  self.path[self.rpath[i]] = self.path[i]
  if self.first == i then
    self.first = self.path[i]
  end
  -- self.path[i] = nil -- leave a path back into the loop, in case we are relying on it
  -- self.rpath[i] = nil
  self.length = self.length - 1
end

function loop:ITEMS()
  local i = self.first
  local prev_first = nil
  return function()
    if self.length==0 then
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
    while not self.items[o] do
      -- there should be a path back to what remains of the loop
      o = i
      i = self.path[i]
    end
    return self.items[o]
  end
end

function loop:DRAW()
  for obj in self:ITEMS() do
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
