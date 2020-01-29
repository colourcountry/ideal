-- TODO detect installed carts somehow


function love.load()
  -- Load the main console API.

  n = require("nemo83")

  function n.getCart(cartid)
    if (not n.carts[cartid]) then
      local path = "carts/"..cartid
      print(love.filesystem.getRealDirectory(path))
      print(path)
      local realpath = love.filesystem.getRealDirectory(path).."/"..path
      local f, msg = loadfile(realpath,"t",n.environment())
      if (f) then
        n.carts[cartid] = f()
        n.api.log("Loaded "..path.." from "..realpath)
      else
        n.api.log("Couldn't find ",path," at "..realpath)
        n.api.log("Message:",msg)
      end
    end
    return n.carts[cartid]
  end

  for k,v in pairs(love.filesystem.getDirectoryItems("carts")) do
    n.api.log("loading "..v)
    n.getCart(v)
  end

  n.api.exit() -- load carousel
end
