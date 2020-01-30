-- TODO detect installed carts somehow


function love.load()
  -- Load the main console API.

  n = require("nemo83")

  function n.get_cart(cartid)
    if (not n.carts[cartid]) then
      local path = "carts/"..cartid
      print(love.filesystem.getRealDirectory(path))
      print(path)
      local realpath = love.filesystem.getRealDirectory(path).."/"..path
      local f, msg = loadfile(realpath,"t",n.environment())
      if (f) then
        n.carts[cartid] = f()
        n.api.LOG("Loaded "..path.." from "..realpath)
      else
        n.api.LOG("Couldn't find ",path," at "..realpath)
        n.api.LOG("Message:",msg)
      end
    end
    return n.carts[cartid]
  end

  for k,v in pairs(love.filesystem.getDirectoryItems("carts")) do
    n.api.LOG("loading "..v)
    n.get_cart(v)
  end

  n.api.EXIT() -- load carousel
end
