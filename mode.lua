mode = {
  name = "(untitled mode)"
}
mode.__index = mode

function mode:LOG()
  local r = " providing "
  for k,v in pairs(self) do
    r = r..k.." "
  end
  return "mode "..self.name..r
end

function mode:init()
end

return mode
