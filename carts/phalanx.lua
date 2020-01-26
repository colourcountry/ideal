game = {
  splash={},
  main={},
  clear={},
  start_mode="splash",
  name="PHALANX",
  info="a shooting game",
  msg=""
}

bg = 8
hi = 0

function draw_scene()
  n.colour(0)
  player:draw()
  n.colour(7)
  bullets:each(function(e, rm)
    e:draw()
  end)
  n.colour(1)
  super_bullets:each(function(e, rm)
    e:draw()
  end)
  n.colour(4)
  mobs:each(function(e, rm)
    e:draw()
  end)
end


function game.start()
  game.msg = game.name
  player = n.ent(n.width/2, n.height-16, 8, "A")
  score = 0
  mobs = n.loop()
  bullets = n.loop()
  super_bullets = n.loop()
end

function game.main.start()
  player = n.ent(n.width/2, n.height-16, 8, "A")
  score = 0
  recoil = 0
  mobs = n.loop()
  bullets = n.loop()
  super_bullets = n.loop()
  bg = math.floor(math.random(9))
  mob_dx = 1
  for i=0,4 do
    for j=0,2 do
      mobs:add( n.ent(12+i*24,40+j*24, 8, "B") )
    end
  end
end

function game.splash.touch(x, y, isNew)
  if (isNew) then
    n.switch_mode("main")
  end
end

function game.splash.draw()
  n.border(bg)
  draw_scene()
  draw_hiscore()
  n.print(game.msg, n.width/2, n.height/2-20, 0, 0)
  n.print("TOUCH TO BEGIN", n.width/2, n.height/2, 0, 0)
end

function game.clear.draw()
  draw_scene()
  draw_score()
  game.msg = game.name
  n.print("STAGE CLEAR", n.width/2, n.height/2, 0, 0)
  if score>hi then
    hi = score
  end
end

function game.clear.touch(x, y, isNew)
  if isNew then
    n.switch_mode("splash")
  end
end

function game.main.update()
  if score>0 then
    score = score - 1
  end
  if recoil>0 then
    recoil = recoil - 1
  end

  local reverse = false
  mobs:each(function(m, m_rm)
    m.dx = mob_dx
    m:move()
    m.dy = 0
    if not m:is_on_screen() then
       reverse=true
    end
    if m:collides(player) then
      game.msg = "GAME OVER"
      n.switch_mode("splash")
    end
    if m.y>n.height then
      m_rm() -- managed to reach the bottom
    end
  end)
  if reverse then
    mob_dx = -mob_dx
    mobs:each(function(m, rm_rm)
      m.dy = 10
    end)
  end

  bullets:each(function(b,b_rm)
    b:move()
    if not b:is_on_screen() then
      b.dx = -b.dx
      b:move()
      if b:is_on_screen() then
        super_bullets:add(b)
      end
      b_rm()
      return
    end
    mobs:each(function(m, m_rm)
      if b:collides(m) then
        m_rm()
        b_rm()
        score = score + 100
      end
    end)
  end)

  super_bullets:each(function(b,b_rm)
    b:move()
    if not b:is_on_screen() then
      b_rm()
    end
    mobs:each(function(m, m_rm)
      if b:collides(m) then
        m_rm()
        score = score + 100
      end
    end)
  end)

  if (mobs.length==0) then
    n.switch_mode("clear")
  end
end

function draw_score()
  n.colour(0)
  n.print("SCORE", n.width/4, 0, 0, -1)
  n.print(score, n.width/4, 8, 0, -1)
  draw_hiscore()
end

function draw_hiscore()
  n.colour(0)
  n.print("HI", 3*n.width/4, 0, 0, -1)
  n.print(hi, 3*n.width/4, 8, 0, -1)
end

function game.main.draw()
  n.border(bg)
  n.colour(0,bg)
  draw_score()
  draw_scene()
end

function direction(x,y)
  a = math.sqrt(x*x+y*y)
  return x/a, y/a
end

function game.main.touch(x, y, isNew)
  local dx, dy = direction(x-player.x, y-player.y)
  if (dx>0) then
    player.x = math.min(player.x+2, n.width)
  end
  if (dx<0) then
    player.x = math.max(player.x-2, 0)
  end

  if (recoil>0) then
    return
  end
  recoil=10
  score = math.max(0, score-1)
  local b = n.ent(player.x, player.y, 8, "o")
  b.dx = dx*4
  b.dy = dy*4
  bullets:add(b)
end

return game
