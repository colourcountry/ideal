-- TODO detect installed carts somehow

function love.load()
  require("json/json") -- this uses the old module() way of working
  sys = require("sys/system")

  function save_memory(cartid)
    if not memory[cartid] then
      api.LOG(cartid,": nothing to save")
    end
    local j = json.encode(memory[cartid])

    love.filesystem.createDirectory("memory")
    local path = "memory/"..cartid
    --api.LOG(path,": writing JSON",j)
    love.filesystem.write(path,j)
  end

  function get_cart(cartid)
    local path = "carts/"..cartid
    api.LOG(path,": reading file")
    chunk = love.filesystem.read(path)

    if not chunk then
      api.LOG(path,": file not found")
      return "Not available"
    end

    local mem_path = "memory/"..cartid
    api.LOG(mem_path,": reading memory")
    local j = love.filesystem.read(mem_path)
    if j then
      memory[cartid] = json.decode(j)
    else
      api.LOG(mem_path,": no memory found")
    end

    local code = api.EXEC(chunk,cartid)
    if not code then
      api.LOG(path,": chunk was not callable")
      return "Bad cart"
    end

    new_cart = code()
    if not new_cart then
      api.LOG(path,": chunk didn't return an object")
      return "Bad cart"
    end
    if not new_cart.name then
      api.LOG(path,": returned object didn't have a 'name'")
      new_cart = nil
      return "Bad cart"
    end
    if new_cart.api ~= api.API then
      api.LOG(path..": cart was for "..new_cart.api..", wanted "..api.API)
      new_cart = nil
      return "Incompatible cart"
    end

    carts[cartid] = new_cart
    carts[cartid].loaded = true
    carts[cartid].id = cartid
    api.LOG(path,": loaded successfully")
    return new_cart
  end

  user_carts = {}
  for k,v in ipairs(love.filesystem.getDirectoryItems("carts/user")) do
    api.LOG(k,v)
    if v:sub(-(1+#api.API))=="."..api.API then
      next = v:gmatch("([^.]+)[.]")
      user_carts["user/"..v] = {
        loaded=false,
        name=next(),
        icon=tonumber(next() or "0x10008",16),
        colour=tonumber(next() or 0),
        extra=next()
      }
    end
  end

  local splash_secrets = { tasks={} }
  local files = love.filesystem.getDirectoryItems("atlas")
  for k, file in ipairs(files) do
    local hex = file:match("([0-9a-f]+)[.]png")
    if hex then
  	   splash_secrets.tasks[#splash_secrets.tasks+1] = function() add_quad_page("atlas/"..file, hex) end
     end
  end

  if arg[2] and string.match(arg[2], "carts/") then
    local cartid=string.gsub(arg[2], "(.*carts/)(.*)", "%2")
    carousel_cart = cartid
  else
    carousel_cart = "rom/carousel."..api.API
  end

  switch_cart("rom/splash."..api.API,nil,splash_secrets)
end
