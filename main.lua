-- TODO detect installed carts somehow

filename_fields = {
  ["ic"]="icon",
  ["it"]="icon_tint",
  ["ep"]="episode",
  ["en"]="episode_name",
}

function love.load()
  require("json/json") -- this uses the old module() way of working
  sys = require("sys/system")

  function save_memory(cartid)
    if not memory[cartid] then
      api.LOG(cartid,": nothing to save")
    end
    local j = json.encode(memory[cartid])

    love.filesystem.createDirectory("memory/user") -- FIXME: allow other dirs to create memory
    local path = "memory/"..cartid
    api.LOG(path,": writing memory",j)
    love.filesystem.write(path,j)
  end

  function read_file(path,logid)
    api.LOG(path,": reading file for",logid)
    chunk = love.filesystem.read(path)

    if not chunk then
      api.LOG(path,": file not found")
      return nil,"Not available"
    end

    local code = api.EXEC(chunk,logid)
    if not code then
      api.LOG(path,": chunk was not callable")
      return nil,"Bad cart"
    end

    new_cart = code()

    if not new_cart then
      api.LOG(path,": chunk didn't return an object")
      return nil,"Bad cart"
    end
    if not new_cart.name then
      api.LOG(path,": returned object didn't have a 'name'")
      return nil,"Bad cart"
    end
    if new_cart.api ~= api.API then
      api.LOG(path..": cart was for "..new_cart.api..", wanted "..api.API)
      return nil,"Incompatible cart"
    end

    return new_cart,nil
  end

  function get_cart(cartid)
    local path = "carts/"..cartid

    new_cart, err = read_file(path,cartid)
    if err then return err end

    local mem_path = "memory/"..cartid
    api.LOG(mem_path,": reading memory")
    local j = love.filesystem.read(mem_path)
    if j then
      memory[cartid] = json.decode(j)
    else
      api.LOG(mem_path,": no memory found")
    end

    carts[cartid] = new_cart
    carts[cartid].loaded = true
    carts[cartid].id = cartid
    api.LOG(path,": loaded successfully")
    return new_cart
  end

  user_carts = {}
  for k,v in ipairs(love.filesystem.getDirectoryItems("carts/user")) do
    if v:sub(-(1+#api.API))=="."..api.API then
      local next = v:gmatch("([^.]+)[.]")
      local x = next()
      cart_props = {
        name=x,
        loaded=false
      }
      x = next()
      while x do
        if filename_fields[x:sub(1,2)] then
          cart_props[filename_fields[x:sub(1,2)]] = x:sub(3):gsub("_"," ")
        end
        x = next()
      end
      user_carts["user/"..v] = cart_props
      api.LOG("Found cart: ",cart_props)
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
