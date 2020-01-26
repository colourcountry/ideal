cart = {
  splash={},
  main={},
  name="Carousel",
  start_mode="splash",
  hidden=true
}

msg = "SELECT CARTRIDGE"
choice = 1
scrollY = 80
initY = 0
boxY = 0
boxSize = 0

function cart.splash.draw()
  local letter = math.floor(n.t/4)
  if (letter>48) then
    n.switch_mode("main")
  end
  for i=1, letter+1 do
    n.colour(i%11)
    n.print(n.name,n.width/2,((-n.t)%(n.height*1.2))+i*10-n.height, 0, 0)
  end
end

function cart.splash.touch()
  n.switch_mode("main")
end

function cart.main.draw()
  if (#carts==0) then
    n.border(1)
    n.colour(4)
    n.print("NEMO83@COLOURCOUNTRY.NET", n.width/2, ((-n.t)%(n.height+112))-16, 0, 0)
    n.colour(2)
    n.print("SISESTAGE KASSETT", n.width/2, ((-n.t)%(n.height+112))-48, 0, 0)
    n.colour(3)
    n.print(n.name, n.width/2, ((-n.t)%(n.height+112))-80, 0, 0)
    return
  end
  n.border(5)
  n.colour(3,4)
  n.cls()
  choice = math.ceil((n.height/2 - scrollY) / 24)
  if choice<1 then
    scrollY = n.height/2
    choice=1
  end
  if choice>#carts then
    scrollY = (n.height/2) - (#carts*24)
    choice=#carts
  end
  local first = math.max(1, choice-4)
  local last = math.min(#carts, choice+4)
  local y = scrollY-12
  for i=first, last do
    if i==choice then
      local l = n.breakText(carts[i].info:upper(), n.width-20, true)
      n.colour(0,8)
      boxY = y
      boxSize = 20+(12*#l)
      n.rect(8,boxY,n.width-16,boxSize)
      n.print(carts[i].name:upper(), n.width/2, y+8, 0, 0)
      n.colour(5,8)
      n.printLines(l, n.width/2, y+20, 0, 0)
      y = y+24+(12*#l)
    else
      n.colour(2,8)
      n.rect(8,y,n.width-16,20)
      n.print(carts[i].name:upper(), n.width/2, y+8, 0, 0)
      y = y+24
    end
  end
  n.colour()
  n.print(n.name, n.width/2, 16, 0, 0)
  n.colour(4)
  n.print(msg, n.width/2, 24, 0, 0)
end

function cart.main.touch(x,y,isNew)
  if (isNew) then
    if y>boxY and y<(boxY+boxSize) then
      n.switch_cart(choice)
    end
    initY = y - scrollY
  end
  scrollY = y - initY
end

return cart
