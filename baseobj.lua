local bases = {}


local MELEE = 0

local function CreateRectangle(x,y,w,h)
    return {x=x,y=y,w=w,h=h}
end


function bases.CreateUnitType(uid, _rect, _hp, _dmg, _arm, _as, _ms, _range, _missile)
    return { id=uid, hp=_hp, rect=_rect, dmg=_dmg, arm=_arm, aspd=_as, mspd=_ms, range=_range, rangesq=_range*_range, missile=_missile }
end

function bases.CreateHeroType(uid, _rect, _hp, _dmg, _arm, _as, _ms, _range, _mana, _skills)
    local htp = bases.CreateUnitType(uid, _rect, _hp, _dmg, _arm, _as, _ms, _range, nil)
    htp.mana = _mana
    htp.skills = _skills
    
    return htp
    --return { ishero=true, rect=_rect, hp=_hp, dmg=_dmg, arm=_arm, aspd=_as, mspd=_ms, range=_range, mana=_mana, skills=_skills }
end


function bases.CreateMissileType(id, speed, mdist, rect)
    return { id=id, spd=speed, maxdist=mdist, rect=rect }
end

function bases.CreateSpellType(sid, sname, manacost, cooldown, _range)
    return { id=sid, name=sname, cost=manacost, cdtime = cooldown, range = _range }
end


-- IF DURATION IS BIGGER THAN FRAMENUMBER*FRAMETIME, THEN, THE EFFECT WILL BEGIN PLAYING AGAIN
-- NOTE: EFFECTS ANIMATIONS ARE SEQUENTIAL ON THE X AXIS, LOOK AT EFFECTS.PNG TO FIND IT OUT

function bases.CreateEffectType(sid, _duration, _framenumber, _frametime, _rect)
    return { id=sid, duration=_duration, qframes=_framenumber, frametime=_frametime, rect=_rect }
end


bases.EFFECT_BLOOD = bases.CreateEffectType(1, 0.5, 3, 0.5/3, CreateRectangle(0,0,8,8))
bases.EFFECT_TELEPORT = bases.CreateEffectType(1, 0.5, 3, 0.5/3, CreateRectangle(0,8,8,8))
bases.EFFECT_EXPLOSION = bases.CreateEffectType(1, 0.5, 3, 0.5/3, CreateRectangle(0,16,8,8))


bases.SPELL_BLAST = bases.CreateSpellType(1, "Blast", 12, 0.25, 325)
bases.SPELL_DRAIN = bases.CreateSpellType(4, "Drain", 16, 1.25, 225)

bases.SPELL_BURNINGHANDS = bases.CreateSpellType(2, "Burning Hands", 25, 1.5, 125)
bases.SPELL_TELEPORT = bases.CreateSpellType(3, "Teleport", 20, 2, 600)
bases.SPELL_SUMMON = bases.CreateSpellType(5, "Giant", 60, 30, 180)


bases.SPELL_SKELETON = bases.CreateSpellType(6, "Skeleton", 12, 1, 180)
bases.SPELL_EXPLODE = bases.CreateSpellType(7, "Explosion", 30, 5, 250)
bases.SPELL_RAISE = bases.CreateSpellType(8, "Undead Call", 20, 1.1, 200)



bases.BLAST_MISSILE = bases.CreateMissileType(1, 192, bases.SPELL_BLAST.range, CreateRectangle(0,0,8,8)) --{ spd=192, maxdist=325, rect=CreateRectangle(0,0,8,8) }
bases.FIRE_MISSILE = bases.CreateMissileType(2, 128, 200, CreateRectangle(8,0,8,8))
bases.ARROW_MISSILE = bases.CreateMissileType(3, 228, 400, CreateRectangle(16,0,8,8))
bases.DRAIN_MISSILE = bases.CreateMissileType(4, 200, 225, CreateRectangle(24,0,8,8))



bases.UNIT_TYPES = {
    ROTHAN = bases.CreateHeroType(1, CreateRectangle(0,0,8,8), 100, 15, 1, 1.00, 68, MELEE, 100, {bases.SPELL_BLAST, bases.SPELL_DRAIN, bases.SPELL_TELEPORT, bases.SPELL_BURNINGHANDS, bases.SPELL_SUMMON} ),
    WARRIOR = bases.CreateUnitType(2, CreateRectangle(8,0,8,8), 15, 6, 1, 0.8, 82, MELEE),
    ARCHER = bases.CreateUnitType(3, CreateRectangle(16,0,8,8), 12, 9, 0, 1.25, 78, 76, bases.ARROW_MISSILE),
    MAGE = bases.CreateUnitType(4, CreateRectangle(24,0,8,8), 10, 11, 0, 1.4, 72, 56, bases.BLAST_MISSILE),
    DWARF = bases.CreateUnitType(5, CreateRectangle(32,0,8,8), 15, 7, 0, 0.7, 78, MELEE),
    GIANT = bases.CreateUnitType(6, CreateRectangle(40, 0, 16, 16), 72, 20, 3, 1.5, 70, MELEE),
    VEXEN = bases.CreateHeroType(7, CreateRectangle(0, 16, 8, 8), 110, 12, 1, 1.00, 70, MELEE, 100, {bases.SPELL_BLAST, bases.SPELL_DRAIN, bases.SPELL_SKELETON, bases.SPELL_EXPLODE, bases.SPELL_RAISE}),
    SKELETON = bases.CreateUnitType(8, CreateRectangle(8, 16, 8, 8), 10, 6, 0, 1.05, 80, MELEE),
    ZOMBIE = bases.CreateUnitType(9, CreateRectangle(16,16,8,8), 20, 5, 2, 1.15, 70, MELEE),
    VAMPIRE = bases.CreateUnitType(10, CreateRectangle(24,16,8,8), 16, 12, 1, 0.75, 85, MELEE),
    GHOST = bases.CreateUnitType(11, CreateRectangle(32,16,8,8), 8, 2, 0, 0.25, 100, 30, bases.BLAST_MISSILE)
}



return bases