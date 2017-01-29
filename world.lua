local World = { UNIT_TEXTURE = love.graphics.newImage("units.png"), ITEM_TEXTURE = love.graphics.newImage("items.png"), MISSILE_TEXTURE = love.graphics.newImage("missiles.png"), UZX = 4, UZY = 4, MZX = 3, MZY = 3, LEVEL_TEXTURE = love.graphics.newImage("map.png"), TILE_SIZE=32, WZX=4, WZY=4, EFFECT_TEXTURE = love.graphics.newImage("effects.png"), EZX=4, EZY=4 }
local ORDERS = { STAY=0, MOVE=1, ATTACK=2 }


local Timer = require("timer")
local Rectangle = require("rectangle")
local Types = require("baseobj")


local PLAYER_1 = 1
local PLAYER_2 = 2

World.GAME_MUSIC = love.audio.newSource("We are so close.mp3")
World.GAME_MUSIC:setVolume(0.75)


World.UNIT_TEXTURE:setFilter("nearest", "nearest")
World.ITEM_TEXTURE:setFilter("nearest", "nearest")
World.MISSILE_TEXTURE:setFilter("nearest", "nearest")
World.LEVEL_TEXTURE:setFilter("nearest", "nearest")
World.EFFECT_TEXTURE:setFilter("nearest", "nearest")


local SUMMONING_TIME = 3

local ENEMY_TYPES = { Types.UNIT_TYPES.WARRIOR, Types.UNIT_TYPES.ARCHER, Types.UNIT_TYPES.MAGE, Types.UNIT_TYPES.DWARF }


-- HELPERS


local function GetTargetXY(self, x, y)
    local ret = {}
    
    for _, u in ipairs(self.units) do
        if Rectangle.contains(u.rect, x, y) then
            table.insert(ret, u)
        end
    end
    
    
    return ret
end


local function GetPlayerTargetXY(self, x, y, play)
    --local ret = {}
    
    for _, u in ipairs(self.units) do
        if Rectangle.contains(u.rect, x, y) and u.player == play then
            return u--table.insert(ret, u)
        end
    end
    
    
    return nil
end


local function AddUnit(self, un)
    table.insert(self.units, un)
end


local function CountUnitsOfPlayer(self, pla)
    local can = 0
    
    for _, u in ipairs(self.units) do
        if u.player == pla then
            can = can + 1
        end
    end
    
    return can
end


local function GetUnitsOfPlayerInArea(self, area, pla)
    local ret = {}
    
    for _, u in ipairs(self.units) do
        if u.player == pla and Rectangle.intersects(u.rect, area) then
            table.insert(ret, u)
        end
    end
    
    return ret
end



local function AddTimedEvent(self, func, _timer, _data)
    table.insert(self.timedevents, {call=func, timer=_timer, data=_data})
end


local function CreateRectangle(x,y,w,h)
    return {x=x,y=y,w=w,h=h}
end


-- NEGATIVE DAMAGE IS CONSIDERED HEALING
local function DamageUnit(self, damage, source)
    if damage > 0 then
        damage = math.max(0, damage-self.armor)
        
        if source then
            if source.kind.id == Types.UNIT_TYPES.ARCHER.id and self.kind.id == Types.UNIT_TYPES.SKELETON.id then
                damage = damage * 0.25
            elseif (source.kind.id == Types.UNIT_TYPES.ARCHER.id or source.kind.id == Types.UNIT_TYPES.WARRIOR.id or source.kind.id == Types.UNIT_TYPES.DWARF.id) and self.kind.id == Types.UNIT_TYPES.GHOST.id then
                damage = damage * 0.25
            elseif source.kind.id == Types.UNIT_TYPES.VAMPIRE.id then
                source.life = math.min(source.kind.hp, source.life+2)
            elseif source.kind.id == Types.UNIT_TYPES.ZOMBIE.id then
                self.speed = self.speed * 0.85
                self.damage = self.damage * 0.85
                self.armor = 0
                self.infected=true
            end
        end
        
    end
    
    self.life = math.min(self.life - damage, self.kind.hp)
    self.lastAttacker = source
end


local function AddMissile(self, mis)
    table.insert(self.missiles, mis)
end


local function GetDistance(x1,y1,x2,y2)
    local dx = x2-x1
    local dy = y2-y1
    
    return math.sqrt(dx*dx+dy*dy)
end



-- USEFULL

local function CreateEffect(self, _x, _y, _eft, _attached )
    local tab = {x=_x, y=_y, kind=_eft, attached=_attached, elapsed=0, anim=0, quad=love.graphics.newQuad(_eft.rect.x, _eft.rect.y, _eft.rect.w, _eft.rect.h, World.EFFECT_TEXTURE:getWidth(), World.EFFECT_TEXTURE:getHeight() ), expired=false }
    
    table.insert(self.effects,  tab)
    
    return tab
end


local function CreateMissile(_x, _y, _tx, _ty, mid, _owner, _damage, _target)
    return { x=_x, y=_y, target=_target, dmg=_damage or _owner.kind.dmg, kind=mid, tx=_tx, ty=_ty, owner=_owner, dist=mid.maxdist, ignore={}, quad=love.graphics.newQuad(mid.rect.x, mid.rect.y, mid.rect.w, mid.rect.h, World.MISSILE_TEXTURE:getWidth(), World.MISSILE_TEXTURE:getHeight()), expired=false }
end


local function CreateUnit(px, py, utp, _player)
    return { x=px, y=py, order = ORDERS.STAY, target=nil, speed=utp.mspd, rect=Rectangle.new(px-utp.rect.w*World.UZX*0.5,py-utp.rect.h*World.UZY*0.5,utp.rect.w*World.UZX,utp.rect.h*World.UZY), life=utp.hp, kind = utp, player=_player, lastAttacker=nil, dead=false, atkcd = utp.aspd*0.5, quads = {love.graphics.newQuad(utp.rect.x, utp.rect.y, utp.rect.w, utp.rect.h, World.UNIT_TEXTURE:getWidth(), World.UNIT_TEXTURE:getHeight()), love.graphics.newQuad(utp.rect.x, utp.rect.y+utp.rect.h, utp.rect.w, utp.rect.h, World.UNIT_TEXTURE:getWidth(), World.UNIT_TEXTURE:getHeight())}, facing=1, anim=1, armor = utp.arm, damage = utp.dmg }
end


local function MoveObject(self, x, y, borders)
    if self.rect then
        if Rectangle.fullyContains(borders, Rectangle.new(self.rect.x+x, self.rect.y+y, self.rect.w, self.rect.h) ) then
            self.x = self.x + x
            self.y = self.y + y
            
            self.rect.x = self.rect.x + x
            self.rect.y = self.rect.y + y
        end
    else
        self.x = self.x+x
        self.y = self.y+y
    end
end



local function MoveObjectTowards(self, x, y, spd, borders)
    local dx = x-self.x
    local dy = y-self.y
    local norm = math.sqrt(dx*dx+dy*dy)
    
    dx = dx/norm
    dy = dy/norm
    
    --self.x = self.x + dx * spd
    --self.y = self.y + dy * spd
    MoveObject(self, dx*spd, dy*spd, borders)
    
    return norm-spd
end



local function CreateItem(px, py, tid)
    return {x=px, y=py, kind=tid, quad=love.graphics.newQuad(0,0,8,8, World.ITEM_TEXTURE:getWidth(), World.ITEM_TEXTURE:getHeight())}
end


---------------- EVENTS

local function OnItemAcquire(self, item)
    local mcan = 11
    local hcan = 3
    
    if self.hero.kind.id == Types.UNIT_TYPES.ROTHAN.id then
        mcan = mcan + 4
        hcan = hcan + 2
    end
    
    self.hero.mana = math.min(self.hero.mana + mcan, self.hero.kind.mana)
    self.hero.life = math.min(self.hero.life + hcan, self.hero.kind.hp)
end


local function OnUnitDeath(self, who)
    if who.lastAttacker and who.lastAttacker.player == PLAYER_1 then
        self.hero.mana = math.min(self.hero.mana+4, self.hero.kind.mana)
        self.kills = self.kills + 1
        
        if self.hero.kind.id == Types.UNIT_TYPES.VEXEN.id then
            self.hero.life = math.min(self.hero.kind.hp, self.hero.life+3)
            self.hero.mana = math.min(self.hero.kind.mana, self.hero.mana+3)
        end
        --AddTimedEvent(self, GIVESTONES, Timer.new(2, 1), {who})
    end
    
    CreateEffect(self, who.x, who.y, Types.EFFECT_BLOOD, who)
end



local function OnMissileHit(self, missile, unit)
    local sameplayer = unit.player == missile.owner.player
    --DamageUnit(unit, missile.owner.kind.dmg, missile.owner)
    --unit.life = unit.life - missile.owner.kind.dmg
    if sameplayer or (missile.id == Types.DRAIN_MISSILE and unit ~= self.hero ) then
        return false
    end--elseif missile.owner.player == PLAYER_2 then
    
    
    
    DamageUnit(unit, missile.dmg, missile.owner)
    
    return true
end


local function OnMissileExpire(self, missile)
    
end



local function OnSpellCast(self, caster, spell, tx, ty)
    local ret = false
    
    local px = caster.rect.x+caster.rect.w/2
    local py = caster.rect.y+caster.rect.h/2
    local angle = math.atan2(ty-caster.y, tx-caster.x)
    local dist = GetDistance(caster.x, caster.y, tx, ty)
    
    if dist >= spell.range then
        return ret
    end
    
    if spell.id == Types.SPELL_BLAST.id then -- Use the name or the spell id
        AddMissile(self, CreateMissile(px, py, tx, ty, Types.BLAST_MISSILE, caster, 15, nil))
        ret = true
    elseif spell.id == Types.SPELL_BURNINGHANDS.id then
        local dis = 125
        local sep = 15 * (math.pi/180)
        
        for i=-3, 3 do
            local fang = angle + i*sep
            AddMissile(self, CreateMissile(px, py, px + dis*math.cos(fang), py + dis* math.sin(fang), Types.FIRE_MISSILE, caster, 20, nil))
        end
        
        ret = true
    elseif spell.id == Types.SPELL_TELEPORT.id then
        if Rectangle.fullyContains(self.borders, Rectangle.new(tx-caster.rect.w/2, ty-caster.rect.h/2, caster.rect.w, caster.rect.h)) then
            MoveObject(caster, tx-caster.x, ty-caster.y, self.borders)
            CreateEffect(self, px, py, Types.EFFECT_TELEPORT)
            CreateEffect(self, tx, ty, Types.EFFECT_TELEPORT)
            ret=true
        end
    elseif spell.id == Types.SPELL_DRAIN.id then
        local tar = GetPlayerTargetXY(self, tx, ty, PLAYER_2)
        if tar and dist <= Types.DRAIN_MISSILE.maxdist then
            DamageUnit(tar, 18, caster)
            AddMissile(self, CreateMissile(tar.x, tar.y, px, py, Types.DRAIN_MISSILE, tar, -8, caster))
            ret = true
        end
    elseif spell.id == Types.SPELL_SUMMON.id then
        if Rectangle.fullyContains(self.borders, Rectangle.new(tx-Types.UNIT_TYPES.GIANT.rect.w*0.5*World.UZX, ty-Types.UNIT_TYPES.GIANT.rect.h*0.5*World.UZY, Types.UNIT_TYPES.GIANT.rect.w*World.UZX, Types.UNIT_TYPES.GIANT.rect.h*World.UZY)) and CountUnitsOfPlayer(self, PLAYER_1) < 5 then
            AddUnit(self, CreateUnit(tx, ty, Types.UNIT_TYPES.GIANT, PLAYER_1))
            ret = true
        end
    elseif spell.id == Types.SPELL_SKELETON.id then
        if Rectangle.fullyContains(self.borders, Rectangle.new(tx-Types.UNIT_TYPES.SKELETON.rect.w*0.5*World.UZX, ty-Types.UNIT_TYPES.SKELETON.rect.h*0.5*World.UZY, Types.UNIT_TYPES.SKELETON.rect.w*World.UZX, Types.UNIT_TYPES.SKELETON.rect.h*World.UZY)) and CountUnitsOfPlayer(self, PLAYER_1) < 4 then
            AddUnit(self, CreateUnit(tx, ty, Types.UNIT_TYPES.SKELETON, PLAYER_1))
            ret=true
        end
    elseif spell.id == Types.SPELL_EXPLODE.id then
        local tar = GetTargetXY(self, tx, ty, PLAYER_2)
        local dam = 20
        local damaoe = 12
        local esize = 72
        
        if #tar > 0 and tar[1] ~= caster and tar[1].life < dam then
            tar = tar[1]
            
            if tar.kind.id == Types.UNIT_TYPES.SKELETON.id then
                --caster.mana = math.min(caster.kind.mana, caster.mana+5)
                damaoe = damaoe + 4
                esize = esize + 24
            end
            
            DamageUnit(tar, dam, caster)
            CreateEffect(self, tar.x, tar.y, Types.EFFECT_EXPLOSION)
            
            --self.hero.x = 200
            
            for _, uns in ipairs( GetUnitsOfPlayerInArea(self, Rectangle.new(tx-esize/2, ty-esize/2, esize, esize), PLAYER_2 )) do
                DamageUnit(uns, damaoe, caster)
                
            end
            
            ret = true
        end
        
        
    elseif spell.id == Types.SPELL_RAISE.id then
        local chances = {Types.UNIT_TYPES.ZOMBIE, Types.UNIT_TYPES.GHOST, Types.UNIT_TYPES.VAMPIRE}
        if Rectangle.fullyContains(self.borders, Rectangle.new(tx-Types.UNIT_TYPES.SKELETON.rect.w*0.5*World.UZX, ty-Types.UNIT_TYPES.SKELETON.rect.h*0.5*World.UZY, Types.UNIT_TYPES.SKELETON.rect.w*World.UZX, Types.UNIT_TYPES.SKELETON.rect.h*World.UZY)) and CountUnitsOfPlayer(self, PLAYER_1) < 4 then
            
            AddUnit(self, CreateUnit(tx, ty, chances[love.math.random(#chances)], PLAYER_1))
            
            ret = true
        end
    end
    
    return ret -- Returning true substracts the mana cost from the spell and puts it on cooldown
end


-------


local function CreateHero(px, py, utp)
    local hero = CreateUnit(px,py,utp, PLAYER_1)
    --hero.speed = hero.speed * 1.25
    hero.mana = utp.mana
    hero.skills = {}
    
    for _, sp in ipairs(utp.skills) do
        table.insert( hero.skills, {kind=sp, cd=0, usable=false} )
    end
    
    hero.primary = hero.skills[1]
    hero.secondary = hero.skills[2]
    
    hero.primary.usable = true
    hero.secondary.usable = true
    
    return hero
end



local function GetCameraXY(borders)
    return { x = love.graphics.getWidth()*0.5 - (borders.x + borders.w*0.5), y = love.graphics.getHeight()*0.5 - (borders.y + borders.h*0.5) }
end


local function CastSpell(self, skill, x, y)
    if self.hero.mana >= skill.kind.cost and skill.usable and skill.cd <= 0.001 and OnSpellCast(self, self.hero, skill.kind, x, y) then
        self.hero.mana = self.hero.mana - skill.kind.cost
        skill.cd = skill.kind.cdtime
    end
end



local function HeroLogic(self, dt)
    local dx = 0
    local dy = 0
    
    
    for _, sk in ipairs(self.hero.skills) do
        if sk.cd > 0 then
            sk.cd = sk.cd - dt
        end
    end
    
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        dx = -1 --self.hero.x = self.hero.x - self.hero.speed*dt
    elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        --self.hero.x = self.hero.x + self.hero.speed*dt
        dx = 1
    end
    
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        dy = -1--self.hero.y = self.hero.y - self.hero.speed*dt
    elseif love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        dy = 1 --self.hero.y = self.hero.y + self.hero.speed*dt
    end
    
    if dx ~= 0 or dy ~= 0 then
        local modifier = 1
        
        if dx ~= 0 and dy ~= 0 then
            modifier = 0.707
        end
        
        --self.hero.x = self.hero.x + self.hero.speed * dt * dx * modifier
        --self.hero.y = self.hero.y + self.hero.speed * dt * dy * modifier
        
        --self.hero.rect.x = self.hero.x
        --self.hero.rect.y = self.hero.y
        
        local npx = self.hero.speed * dt * dx * modifier
        local npy = self.hero.speed * dt * dy * modifier
        
        if dx > 0 then
            self.hero.facing = 1
        elseif dx < 0 then
            self.hero.facing = -1
        end
        
        --if Rectangle.fullyContains(self.borders, Rectangle.new(self.hero.rect.x+npx, self.hero.rect.y+npy, self.hero.rect.w, self.hero.rect.h) ) then
            MoveObject(self.hero, self.hero.speed*dt*dx*modifier, self.hero.speed*dt*dy*modifier, self.borders)
            
        --else
            --MoveObjectTowards(self.hero, self.borders.x+self.borders.w/2, self.borders.y+self.borders.h/2, dt*self.hero.speed)
        --end
    end
end





local SIGHT_RANGE = 256
local SIGHT_RANGE_SQ = SIGHT_RANGE*SIGHT_RANGE


local function FindNewTarget(self, unit)
    local minu = nil
    local mindis = 0
    
    for _, ene in ipairs(self.units) do
        local sqdist = (unit.x-ene.x)*(unit.x-ene.x) + (unit.y-ene.y) * (unit.y-ene.y)
        
        if ene ~= unit and ene.player ~= unit.player and sqdist <= SIGHT_RANGE_SQ then
            if not minu or sqdist < mindis then
                minu = ene
                mindis = sqdist
            end
        end
    end
    
    --if not minu and self.player == PLAYER_2 then
        --return self.hero
    --end
    
    return minu
end


local function UnitLogic(self, unit, dt)
    
    if not unit.target or unit.target.life <= 0 then
        local ntar = FindNewTarget(self, unit)
        unit.target = ntar -- or self.hero
        
        --if not ntar and unit.player == PLAYER_2 then
            --unit.target = self.hero
        --end
    end
    
    if unit.target then
        local dist = GetDistance(unit.x, unit.y, unit.target.x, unit.target.y)
        local myrange = (unit.rect.w+unit.rect.h)/4
        local enerange = (unit.target.rect.w+unit.target.rect.h)/4
        
        if unit.target.x >= unit.x then
            unit.facing = 1
        else
            unit.facing = -1
        end
        
        if dist > SIGHT_RANGE then
            unit.target = nil
            --unit.target = FindNewTarget(self, unit)
            --unit.target = FindNewTarget(self, unit)
        elseif dist > (unit.kind.range+myrange+enerange) then
            unit.target = FindNewTarget(self, unit)
            MoveObjectTowards(unit, unit.target.x, unit.target.y, unit.speed*dt, self.borders)
        else
            unit.atkcd = unit.atkcd - dt
            
            if unit.atkcd <= 0 then
                if unit.kind.missile then
                    AddMissile(self, CreateMissile(unit.x, unit.y, unit.target.x, unit.target.y, unit.kind.missile, unit, unit.damage, nil ))
                else
                    DamageUnit(unit.target, unit.kind.dmg , unit)
                end
                unit.atkcd = unit.kind.aspd
            end
        end
    elseif unit.player == PLAYER_2 then
        MoveObjectTowards(unit, self.hero.x, self.hero.y, unit.speed*dt, self.borders)
        
        if self.hero.x >= unit.x then
            unit.facing = 1
        else
            unit.facing = -1
        end
    end
    
    
end

function World.update(self, dt)
    --self.timer = self.timer + math.floor(dt*1000)
    
    self.gametime = self.gametime + dt
    
    
    for ep, tev in ipairs(self.timedevents) do
        if Timer.update(tev.timer, dt) then
            if tev.call( self, tev.data ) then
                table.remove(self.timedevents, ep)
            end
        end
    end
    
    
    HeroLogic(self, dt)
    
    
    local nt = math.min( math.floor(self.timer.elapsed / 45), #self.hero.skills - 2)
    
    self.timer.maxtime = SUMMONING_TIME - nt*0.525
    
    self.hero.skills[nt+2].usable = true
    
    
    if Timer.update(self.timer, dt) then
        local id = math.floor(love.math.random(#ENEMY_TYPES))
        local rid = self.regions[love.math.random(#self.regions)]

        table.insert(self.units, CreateUnit(rid.x+rid.w/2, rid.y+rid.h/2, ENEMY_TYPES[ id ], PLAYER_2))
    end
    
    if Timer.update(self.itemtimer, dt) then
        local reg = self.regions[love.math.random(#self.regions)]
        if #self.items < 10 then
            table.insert(self.items, CreateItem( reg.x + 4 + love.math.random(reg.w-8), reg.y + 4 + love.math.random(reg.h-8), 0 ) )
        end
    end
    
    for ups, u in ipairs(self.units) do
        if u.life > 0 then
            if u ~= self.hero then
                UnitLogic(self, u, dt)
                --MoveObjectTowards(u, self.hero.x, self.hero.y, u.speed*dt)
            end
            
            --if not Rectangle.fullyContains(self.borders, u.rect) then
                --MoveObjectTowards(u, self.borders.x+self.borders.w/2, self.borders.y+self.borders.h/2, dt*u.speed*2, self.borders)
            --end
            
            u.anim = math.floor( ((self.gametime*2) % 2) + 1)
            
            for ip, m in ipairs(self.missiles) do
                if Rectangle.contains(u.rect, m.x, m.y) and not m.ignore[u] and u ~= m.owner then
                    if OnMissileHit(self, m, u) then
                        table.remove(self.missiles, ip)
                        if u.life <= 0 then
                            break
                        end
                    else
                        m.ignore[u] = true
                    end
                end
            end
        end
        
        if u.life <= 0 then
            OnUnitDeath(self, u)
            u.dead = (u.life <= 0)
            
            if u.dead then
                table.remove(self.units, ups)
            end
        end
        
    end
    
    
    for ip, m in ipairs(self.missiles) do
        local tx = m.tx
        local ty = m.ty
        
        if m.target then
            tx = m.target.x
            ty = m.target.y
        end
        
        m.dist = m.dist - dt*m.kind.spd
        m.angle = math.atan2( ty-m.y, tx-m.x)
        
        if m.dist <= 0 or MoveObjectTowards(m, tx, ty, m.kind.spd*dt) <= dt*m.kind.spd then
            OnMissileExpire(self, m)
            m.expired=true
            table.remove(self.missiles, ip)
        end
    end
    
    
    for p, i in ipairs(self.items) do
        if Rectangle.contains(self.hero.rect, i.x, i.y) then
            --self.hero.mana = math.min(self.hero.mana + 5, self.hero.kind.mana)
            OnItemAcquire(self, i)
            table.remove(self.items, p)
            --self.stones = self.stones + 1
        end
    end
    
    
    for pd, ef in ipairs(self.effects) do
        local nanim = 0
        
        ef.elapsed = ef.elapsed + dt
        
        if ef.elapsed < ef.kind.duration then
            if ef.attached then
                ef.x = ef.attached.x
                ef.y = ef.attached.y
            end
            
            nanim = math.floor(ef.elapsed/ef.kind.frametime) % ef.kind.qframes
            
            --if nanim > ef.kind.qframes then
                --nanim = 0
            --end
            
            if ef.anim ~= nanim then
                ef.quad = love.graphics.newQuad(ef.kind.rect.x + ef.kind.rect.w * nanim, ef.kind.rect.y, ef.kind.rect.w, ef.kind.rect.h, World.EFFECT_TEXTURE:getWidth(), World.EFFECT_TEXTURE:getHeight())
            end
        else
            ef.expired=true
            table.remove(self.effects, pd)
        end
    end
    
end


function World.draw(self)
    local lgw = love.graphics.getWidth()
    local lgh = love.graphics.getHeight()
    
    love.graphics.translate(self.camera.x, self.camera.y)
    
    love.graphics.draw(World.LEVEL_TEXTURE, 0, 0, 0, 4, 4)
    
    love.graphics.setLineWidth(2)
    love.graphics.setColor(255, 255, 0, 255)
    love.graphics.rectangle("line", self.borders.x, self.borders.y, self.borders.w, self.borders.h)
    
    love.graphics.setColor(255, 0, 255, 255)
    
    
    --for _, r in ipairs(self.regions) do
        --love.graphics.rectangle("line", r.x, r.y, r.w, r.h)
    --end
    
    love.graphics.setLineWidth(1)
    love.graphics.setColor(255, 255, 255, 255)
    
    
    for _, i in ipairs(self.items) do
        --love.graphics.circle("line", i.x, i.y, 8, 4)
        love.graphics.draw(World.ITEM_TEXTURE, i.quad, i.x, i.y, 0, World.MZX, World.MZY, 4, 4)
    end
    
    
    for _, u in ipairs(self.units) do
        --if u == self.hero then
            --love.graphics.setColor(0, 255, 0, 255)
        --end
        
        --love.graphics.circle("line", u.x+16, u.y+16, 16, 8)
        if u.infected then
            love.graphics.setColor(255, 192, 192, 255)
        end
        
        love.graphics.draw(World.UNIT_TEXTURE, u.quads[u.anim], u.x, u.y, 0, u.facing*World.UZX, World.UZY, u.kind.rect.w/2, u.kind.rect.h/2)
        --love.graphics.rectangle("line", u.rect.x, u.rect.y, u.rect.w, u.rect.h)
        
        --if u == self.hero then
            --love.graphics.setColor(255, 255, 255, 255)
        --end
        if u.infected then
            love.graphics.setColor(255, 255, 255, 255)
        end
    end
    
    if not self.hideCast then
    love.graphics.setScissor(self.borders.x+self.camera.x, self.borders.y+self.camera.y, self.borders.w, self.borders.h)
    love.graphics.circle("line", self.hero.x, self.hero.y, self.hero.secondary.kind.range, 24)
    
    love.graphics.setColor(0, 255, 0, 255)
    love.graphics.circle("line", self.hero.x, self.hero.y, self.hero.primary.kind.range, 24)
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.setScissor()
    end
    
    for _, m in ipairs(self.missiles) do
        --love.graphics.circle("fill", m.x, m.y, 4, 5)
        love.graphics.draw(World.MISSILE_TEXTURE, m.quad, m.x, m.y, m.angle, World.MZX, World.MZY, m.kind.rect.w/2, m.kind.rect.h/2)
    end
    
    for _, ef in ipairs(self.effects) do
        love.graphics.draw(World.EFFECT_TEXTURE, ef.quad, ef.x, ef.y, 0, World.EZX, World.EZY, ef.kind.rect.w/2, ef.kind.rect.h/2)
    end
    
    
    love.graphics.setColor(255, 255, 255, 255)

    love.graphics.translate(-self.camera.x, -self.camera.y)
    
    love.graphics.setFont(self.font)
    
    love.graphics.print("Kills: " .. self.kills, 120, 0)
    
    
    local ready = math.floor(self.hero.secondary.cd * 10) / 10
    
    if ready <= 0 then
        ready = "READY"
    end
    
    local stonetext = self.hero.secondary.kind.name .. " ["..ready.."]"
    love.graphics.print(stonetext, (lgw - self.font:getWidth(stonetext) ) * 0.5, lgh-35)
    
    stonetext = "Time: " .. math.floor(self.gametime)
    love.graphics.print(stonetext, lgw - self.font:getWidth(stonetext) - 120, 0)
    
    stonetext = "Spell unlocked in: " .. math.floor(45-(self.gametime%45))
    
    if  not self.hero.skills[#self.hero.skills].usable then
	love.graphics.print(stonetext, lgw/2 - self.font:getWidth(stonetext) / 2, 0)
	end
    
    
    love.graphics.setColor(255, 0, 0, 128)
    love.graphics.rectangle("fill", 45, lgh - 35, 200, 30)
    love.graphics.setColor(255, 0, 0, 255)
    love.graphics.rectangle("fill", 45, lgh-35, 200 * (self.hero.life/self.hero.kind.hp), 30)
    
    love.graphics.setColor(55, 55, 255, 128)
    love.graphics.rectangle("fill", lgw - 245, lgh-35, 200, 30)
    love.graphics.setColor(55, 55, 255, 255)
    love.graphics.rectangle("fill", lgw - 245, lgh-35, 200 * (self.hero.mana/self.hero.kind.mana), 30)
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.rectangle("line", lgw-45-200*(1-(self.hero.mana/self.hero.kind.mana))-self.hero.secondary.kind.cost, lgh-35, self.hero.secondary.kind.cost, 30)
    
    love.graphics.setColor(255, 255, 255, 255)
    
end



function World.keypressed(self, key, isrep)
    if key == "1" and self.hero.skills[2].usable then
        self.hero.secondary = self.hero.skills[2]
    elseif key == "2" and self.hero.skills[3].usable then
        self.hero.secondary = self.hero.skills[3]
    elseif key == "3" and self.hero.skills[4].usable then
        self.hero.secondary = self.hero.skills[4]
    elseif key == "4" and self.hero.skills[5].usable then
        self.hero.secondary = self.hero.skills[5]
    elseif key == "h" then
        self.hideCast=not self.hideCast
    end
end

function World.mousepressed(self, x, y, button)
    x = x - self.camera.x
    y = y - self.camera.y
    
    if button == 1 then
        CastSpell(self, self.hero.primary, x, y)
    elseif button == 2 then
        CastSpell(self, self.hero.secondary, x, y)
    end
end



function World.clear(self)
    self.units = nil
    self.effects = nil
    self.missiles = nil
    self.timedevents = nil
    self.items = nil
    self.regions = nil
    World.GAME_MUSIC:stop()
end

function World.new(who)
    local rwid = World.TILE_SIZE*4
    local rhei = World.TILE_SIZE*4
    local lsiz = 2
    local summontime = 1.5
    local itemtime = 3
    
    local _borders = Rectangle.new(0,0, World.LEVEL_TEXTURE:getWidth()*World.WZX, World.LEVEL_TEXTURE:getHeight()*World.WZY)--{ x=0, y=0, w=700, h=500 }
    local _hero = CreateHero( _borders.x+_borders.w/2, _borders.y+_borders.h/2, who )
    
    local _reg1 = Rectangle.new(_borders.x+1, _borders.y+1, rwid, rhei) --{ x=_borders.x+1, y=_borders.y+1, w=rwid, h=rhei }
    local _reg2 = Rectangle.new(_borders.x+_borders.w-rwid-lsiz, _borders.y+1, rwid, rhei) --{ x=_borders.x+_borders.w-rwid-lsiz, y=_borders.y+1, w=rwid, h=rhei }
    local _reg3 = Rectangle.new(_borders.x+1,_borders.y+_borders.h-rhei-lsiz,rwid,rhei)--{ x=_borders.x+1, y=_borders.y+_borders.h-rhei-lsiz, w=rwid, h=rhei }
    local _reg4 = Rectangle.new(_borders.x+_borders.w-rwid-lsiz,_borders.y+_borders.h-rhei-lsiz,rwid,rhei)--{ x=_borders.x+_borders.w-rwid-lsiz, y=_borders.y+_borders.h-rhei-lsiz, w=rwid, h=rhei }
    
    --World.GAME_MUSIC:stop()
    World.GAME_MUSIC:play()
    World.GAME_MUSIC:setLooping(true)
    
    return { borders =_borders, hero=_hero, camera=GetCameraXY(_borders), units={_hero}, regions={_reg1,_reg2,_reg3,_reg4}, timer = Timer.new(summontime), kills = 0, stones = 0, font = love.graphics.newFont(24), gametime=0.00, items={}, itemtimer = Timer.new(itemtime), missiles = {}, timedevents = {}, effects={}, hideCast=false }
end



return World