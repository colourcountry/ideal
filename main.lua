-- TODO detect installed carts somehow

function love.load()
  -- Load the main console API.
  json = require("json")
  sys = require("system")

  function save_memory(cartid)
    if not sys.memory[cartid] then
      sys.api.LOG(cartid,": nothing to save")
    end
    local j = json.encode(sys.memory[cartid])

    love.filesystem.createDirectory("memory")
    local path = "memory/"..cartid
    --sys.api.LOG(path,": writing JSON",j)
    love.filesystem.write(path,j)
  end

  function get_cart(cartid)
    local path = "carts/"..cartid
    sys.api.LOG(path,": reading file")
    chunk = love.filesystem.read(path)

    if not chunk then
      sys.api.LOG(path,": file not found")
      return "Not available"
    end

    local mem_path = "memory/"..cartid
    sys.api.LOG(mem_path,": reading memory")
    local j = love.filesystem.read(mem_path)
    if j then
      sys.memory[cartid] = json.decode(j)
    else
      sys.api.LOG(mem_path,": no memory found")
    end

    local code = sys.api.EXEC(chunk,cartid)
    if not code then
      sys.api.LOG(path,": chunk was not callable")
      return "Bad cart"
    end

    new_cart = code()
    if not new_cart then
      sys.api.LOG(path,": chunk didn't return an object")
      return "Bad cart"
    end
    if not new_cart.name then
      sys.api.LOG(path,": returned object didn't have a 'name'")
      new_cart = nil
      return "Bad cart"
    end
    if new_cart.api ~= sys.api.API then
      sys.api.LOG(path..": cart was for"..new_cart.api..", wanted "..sys.api.API)
      new_cart = nil
      return "Incompatible cart"
    end

    sys.carts[cartid] = new_cart
    sys.carts[cartid].loaded = true
    sys.carts[cartid].id = cartid
    sys.api.LOG(path,": loaded successfully")
    return new_cart
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
    end
  end

  if arg[2] and string.match(arg[2], "carts/") then
    sys.switch_cart(string.gsub(arg[2], "(.*carts/)(.*)", "%2"))
  else
    sys.switch_cart("_splash.n83")
  end
end
