-- TODO detect installed carts somehow

function love.load()
  -- Load the main console API.

  sys = require("system")

  function sys.get_cart(cartid)
    if not sys.carts[cartid] then
      sys.api.LOG(cartid,": not indexed")
    end

    if sys.carts[cartid].loaded then
      sys.api.LOG(cartid,": already loaded")
      return sys.carts[cartid]
    end

    local path = "carts/"..cartid
    sys.api.LOG(path,": reading file")
    local chunk = love.filesystem.read(path)

    if not chunk then
      sys.api.LOG(path,": not found")
      return "?FILE"
    end

    cur_env = sys.environment()
    -- this is kind of horrible but works for the moment
    local code = loadstring("setfenv(1,cur_env)\n"..chunk)
    if not code then
      sys.api.LOG(path,": chunk was not callable")
      return "?CALL"
    end

    new_cart = code()
    if not new_cart then
      sys.api.LOG(path,": chunk didn't return an object")
      return "?OBJ"
    end
    if not new_cart.name then
      sys.api.LOG(path,": returned object didn't have a 'name'")
      new_cart = nil
      return "?ANON"
    end
    if new_cart.name ~= sys.carts[cartid].name then
      sys.api.LOG(path,": cart was named ",new_cart.name,", wanted ",sys.carts[cartid].name)
      new_cart = nil
      return "?NAME"
    end
    if new_cart.api ~= sys.api.API then
      sys.api.LOG(path..": cart was for API ",sys.carts[cartid].api,", wanted ",sys.api.API)
      new_cart = nil
      return "?API"
    end

    sys.carts[cartid] = new_cart
    sys.carts[cartid].loaded = true
    sys.api.LOG(path,": loaded successfully")
    return sys.carts[cartid]
  end

  for k,v in pairs(love.filesystem.getDirectoryItems("carts")) do
    sys.api.LOG(k,v)
    if v:sub(-4)=="."..sys.api.API then
      next = v:gmatch("([^.]+)[.]")
      sys.carts[v] = {
        loaded=false,
        name=next(),
        icon=next(),
        extra=next()
      }
      sys.api.LOG("indexed ",v,": ",sys.carts[v])
    end
  end

  for k,v in pairs(arg) do
    local cart_arg = string.gsub(v, "(.*/)(.*)", "%2")
    if sys.carts[cart_arg] then
      cart_arg_found = cart_arg
    else
      sys.api.LOG("Couldn't find requested cart ",cart_arg)
    end
  end

  if cart_arg_found then
    sys.switch_cart(cart_arg_found)
  else
    sys.api.EXIT() -- load carousel
  end
end
