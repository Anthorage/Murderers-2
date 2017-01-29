local World = require("world")
local Rectangle = require("rectangle")
local Types = require("baseobj")

local winst = nil

local buttons = {}
local menufont = love.graphics.newFont(24)
local tutorialfont = love.graphics.newFont(20)

local menustate = 1


local helptext =
"WASD/ARROW KEYS : MOVEMENT\
LEFT MOUSE CLICK : SHOOT MISSILE\
RIGHT MOUSE CLICK : CAST CURRENT SPELL\
1,2,3,4 : CHANGE CURRENT SPELL\
\
AT THE BOTTOM OF THE SCREEN YOU CAN FIND YOUR HEALTH, ENERGY AND THE CURRENT SPELL COOLDOWN\
\
SPELLS WILL BE UNLOCKED EVERY 45 SECONDS (YOU START WITH ONE AND END UP WITH FOUR)\
\
ENEMIES SPAWN AT PORTALS ON THE MAP CORNERS\
\
MAGICAL STONES APPEAR AT PORTALS, TAKE THEM TO GET HEALTH AND ENERGY\
\
SOME SPELLS HAVE A CASTING RANGE (THE WHITE CIRCLE AROUND YOUR CHARACTER SHOWS THE CURRENT SPELL RANGE, THE GREEN CIRCLE SHOWS THE MISSILE ATTACK RANGE) (YOU CAN HIDE THEM BY PRESSING H)\
\
KILLING ENEMIES ALSO GIVES YOU ENERGY."


function love.load(arg)
    local gw = love.graphics.getWidth()
    local gh = love.graphics.getHeight()
    local btsx = 250
    local btsy = 75
    
    love.math.setRandomSeed(os.time())
    
    love.math.random()
    love.math.random()
    love.math.random()
    love.math.random()
    
    buttons.rothan = Rectangle.new( (gw - btsx)/2, gh/8, btsx, btsy )
    buttons.vexen = Rectangle.new( (gw-btsx)/2, (gh*3)/8 - btsy*0.5, btsx, btsy )
    buttons.tutorial = Rectangle.new( (gw-btsx)/2, (gh*5)/8 - btsy*0.5, btsx, btsy )
    buttons.exit = Rectangle.new ( (gw-btsx)/2, (gh*7)/8 - btsy, btsx, btsy )
    
    buttons.back = Rectangle.new( (gw-btsx)/2, (gh*5)/6, btsx, btsy)
    --winst = World.new()
end


function love.update(dt)
    if winst then
        if winst.hero.dead then
            World.clear(winst)
            winst = nil--World.new()
        else
            World.update(winst, dt)
        end
    end
end


function love.draw()
    if winst then
        World.draw(winst)
    else
        love.graphics.setFont(menufont)
        
        if menustate == 1 then
            Rectangle.draw(buttons.rothan, 255, 255, 255)
            love.graphics.printf("Play as Rothan", buttons.rothan.x, buttons.rothan.y+(buttons.rothan.h-menufont:getHeight())*0.5, buttons.rothan.w, "center")
            Rectangle.draw(buttons.vexen, 255, 255, 255)
            love.graphics.printf("Play as Vexen", buttons.vexen.x, buttons.vexen.y+(buttons.vexen.h-menufont:getHeight())*0.5, buttons.vexen.w, "center")
            Rectangle.draw(buttons.tutorial, 255, 255, 255)
            love.graphics.printf("Tutorial", buttons.tutorial.x, buttons.tutorial.y+(buttons.tutorial.h-menufont:getHeight())*0.5, buttons.tutorial.w, "center")
            Rectangle.draw(buttons.exit, 255, 255, 255)
            love.graphics.printf("Exit Game", buttons.exit.x, buttons.exit.y+(buttons.exit.h-menufont:getHeight())*0.5, buttons.exit.w, "center")
        else
            Rectangle.draw(buttons.back, 255, 255, 255)
            love.graphics.printf("Back", buttons.back.x, buttons.back.y+(buttons.back.h-menufont:getHeight())*0.5, buttons.back.w, "center")
            
            love.graphics.setFont(tutorialfont)
            love.graphics.printf(helptext, 4, 4, love.graphics.getWidth(), "left")
        end
    end--vexen
end


function love.keypressed(key, isrep)
    if winst then
        World.keypressed(winst, key, isrep)
    end
end

function love.mousepressed(x, y, button)
    if winst then
        World.mousepressed(winst, x, y, button)
    else
        if menustate == 1 then
            if Rectangle.contains(buttons.rothan, x, y) then
                winst = World.new(Types.UNIT_TYPES.ROTHAN)
            elseif Rectangle.contains(buttons.vexen, x, y) then
                winst = World.new(Types.UNIT_TYPES.VEXEN)
            elseif Rectangle.contains(buttons.exit, x, y) then
                love.event.quit()
            elseif Rectangle.contains(buttons.tutorial, x, y) then
                menustate=2
            end
        else
            if Rectangle.contains(buttons.back, x, y) then
                menustate = 1
            end
        end
    end
end