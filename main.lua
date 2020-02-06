-- TODO detect installed carts somehow

function love.load()
  -- Load the main console API.

  n = require("nemo83")

  function n.get_cart(cartid)
    if (not n.carts[cartid]) then
      local path = "carts/"..cartid..".n83"
      print("Reading "..path)
      local chunk = love.filesystem.read(path)
      if (chunk) then
        cur_env = n.environment()
        -- this is kind of horrible but works for the moment
        n.carts[cartid] = loadstring("setfenv(1,cur_env)\n"..chunk)()
        n.api.LOG("Loaded "..path)
      else
        n.api.LOG("Couldn't find ",path)
      end
    end
    return n.carts[cartid]
  end

  for k,v in pairs(love.filesystem.getDirectoryItems("carts")) do
    if v:sub(-4)==".n83" then
      v = v:sub(1,-5)
      n.api.LOG("loading "..v)
      n.get_cart(v)
    end
  end

  for k,v in pairs(arg) do
    cart_arg = string.gsub(v, "(.*/)(.*)", "%2")
    if n.carts[cart_arg] then
      cart_found = cart_arg
    end
  end

  if cart_found then
    n.switch_cart(cart_found)
  else
    n.api.EXIT() -- load carousel
  end
end
