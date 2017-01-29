local Timer = {}


-- If ticks is omitted an infinite loop will occurr
function Timer.new(time, ticks)
    local self = {}
    self.ticks = ticks or 1000000000
    self.infinite = (ticks==1000000000)
    self.time = time
    self.maxtime = time
    self.finished = (self.ticks <= 0)
    self.elapsed = 0.00
    
    return self
end


function Timer.update(self, dt)
    local ok = false
    
    if self.ticks > 0 then
        self.time = self.time - dt
        self.elapsed = self.elapsed + dt
        
        if self.time <= 0 then
            self.time = self.maxtime
            
            if not self.infinite then
                self.ticks = self.ticks - 1
            end
            
            ok = true
            self.finished = (self.ticks <= 0)
        end
    end
    
    return ok
end


return Timer