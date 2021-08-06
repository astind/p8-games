

function _init()
  t = 0
  ship = {sp=1, x=60, y=60, health=4, points=0, imm=true, t=0, can_shoot=true, st=0, shooting=false, recharge=100, box={x1=0, y1=0, x2=7, y2=7} }
  bullets = {}
  enemies = {}
  explosions = {}
  stars = {}
  -- add stars
  for i = 1, 128 do
    add(stars, {x=rnd(128), y=rnd(128), s=rnd(2)+1 })
  end
  start()
end

function respawn()
  local n = flr(rnd(9))+2
  for i=1, n do
    local d = -1
    if rnd(1) < 0.5 then d=1 end
    add(enemies, {sp=17, m_x=i*16, m_y=-20-i*8, d=d, x=-32, y=32, r=12, box={x1=0, y1=0, x2=7, y2=7} })
  end
end

function start()
  _update = update_game
  _draw = draw_game
end

function game_over()
  _update = update_over
  _draw = draw_over
end

function update_over()
end

function draw_over()
  cls()
  print("game over", 50, 50, 4)
end

function update_game()
  -- update tick
  t = t + 1
  -- check ship immortality
  if ship.imm then
    ship.t = ship.t + 1
    if ship.t > 30 then
      ship.imm = false
      ship.t = 0
    end
  end

  if not ship.shooting and ship.recharge < 100 then
    ship.recharge = ship.recharge + 1
  end
  
  -- update shot count
  if not ship.can_shoot then
    ship.st = ship.st + 1
    if ship.st > 5 then
      ship.can_shoot = true
      ship.st = 0
    end
  end
  -- update star locations
  for star in all(stars) do
    star.y = star.y + star.s
    if star.y >= 128 then
      star.y = 0
      star.x = rnd(128)
    end
  end
  -- update explosions
  for ex in all(explosions) do
    ex.t = ex.t + 1
    if ex.t == 13 then
      del(explosions, ex)
    end
  end
  -- update ads location
  update_enemies(t)
  -- update bullet location
  update_bullets()
  -- change sprite animation depending on tick
  if (t % 6 < 3) then
    ship.sp = 1
  else
    ship.sp = 2
  end
  if ship.health <= 0 then
    game_over()
  end
  -- check for ship inputs
  ship_inputs()
end

function draw_game()
  -- clear and draw black background
  cls()
  -- draw the stars
  for star in all(stars) do
    pset(star.x, star.y, 6)
  end
  -- print the score
  print(ship.points, 9)
  -- draw ship
  if not ship.imm or t % 8 < 4 then
    spr(ship.sp, ship.x, ship.y)
  end
  -- draw explosions
  for ex in all(explosions) do
    circ(ex.x, ex.y, ex.t/2, 8 + ex.t % 3)
  end
  -- draw bullets
  for b in all(bullets) do
    spr(b.sp, b.x, b.y)
  end
  -- draw enemies
  for e in all(enemies) do
    spr(e.sp, e.x, e.y)
  end
  -- draw health
  for i=1,4 do
    if i <= ship.health then
      spr(33, 80+8*i, 3)
    else
      spr(34, 80+8*i, 3)
    end
  end
  -- draw energy
  for i=1,4 do
    if i <= ceil(ship.recharge / 25) then
      spr(4, 85+8*i, 14)
    else
      spr(5, 85+8*i, 14)
    end
  end
end

function abs_box(s)
  local box = {}
  box.x1 = s.box.x1 + s.x
  box.y1 = s.box.y1 + s.y
  box.x2 = s.box.x2 + s.x
  box.y2 = s.box.y2 + s.y
  return box
end

-- checks if two sprites collide
function collide(a,b)
  -- set up collide
  local box_a = abs_box(a)
  local box_b = abs_box(b)

  if box_a.x1 > box_b.x2 or
     box_a.y1 > box_b.y2 or
     box_b.x1 > box_a.x2 or
     box_b.y1 > box_a.y2 then
    return false
  end
  return true
end

function explode(x, y)
  add(explosions, {x=x, y=y, t=0})
end

function fire()
  if ship.can_shoot and ship.recharge > 0 then
    local b = {
      sp = 3,
      x = ship.x,
      y = ship.y,
      box = {x1=2, y1=0, x2=5, y2=4}
    }
    add(bullets, b)
    if ship.recharge > 0 then
      ship.recharge = ship.recharge - 5
    end
    ship.can_shoot = false
  end
end

function update_bullets()
  for b in all(bullets) do
    -- update bullet location
    b.y = b.y - 3
    if b.y < 0 then
      -- remove bulllets that have left the screen
      del(bullets, b)
    end
    -- check for bullet collisions
    for e in all(enemies) do
      if collide(b,e) then
        del(enemies, e)
        ship.points = ship.points + 1
        explode(e.x, e.y)
      end
    end
  end
end

function ship_inputs()
  if btn(0) then ship.x = ship.x - 1 end
  if btn(1) then ship.x = ship.x + 1 end
  if btn(2) then ship.y = ship.y - 1 end
  if btn(3) then ship.y = ship.y + 1 end
  if btn(4) then
    ship.shooting = true
    fire()
  else
    ship.shooting = false 
  end
end

function update_enemies(t)
  if #enemies <= 0 then
    respawn()
  end

  for e in all(enemies) do
    e.m_y = e.m_y + 1.3
    e.x = e.r * sin(t/50) + e.m_x
    e.y = e.r * cos(t/50) + e.m_y
    if not ship.imm and collide(ship, e) then
      -- hits the ship
      ship.imm = true
      del(enemies, e)
      ship.health = ship.health - 1;
    end
    if e.y > 150 then
      del(enemies, e)
    end
  end
end
