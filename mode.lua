mode = {
  name = "(untitled)"
}
mode.__index = mode

function mode:LOG()
  local r = " providing "
  for k,v in pairs(self) do
    r = r..k.." "
  end
  if self.name then
    return "mode "..self.name..r
  end
  return "anonymous mode"..r
end

function mode:init()
end

return mode
