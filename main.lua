-- TODO detect installed carts somehow
carts = {}
files = love.filesystem.getDirectoryItems("carts")
for k, v in pairs(files) do
  local req = v:gsub("%.lua","")
  carts[k] = require("carts."..req)
  carts[k].req = req
  print(v..": "..carts[k].name)
end

function love.load()
  -- Load the main console API.
  cart = {}
  mode = ''
  n = require("nemo83")

  -- Load carts, which should not have access to LOVE.
  local _love = love
  love = nil

  n.exit() -- load carousel
  love = _love
end
