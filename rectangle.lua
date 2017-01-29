local Rectangle = {}

function Rectangle.new(x,y,w,h)
    return {x=x, y=y, w=w, h=h}
end

function Rectangle.intersects(self, other)
    return not ( other.x > (self.x+self.w) or (other.x+other.w) < self.x or other.y > (self.y+self.h) or (other.y+other.h) < self.y)
end

function Rectangle.getCenter(self)
    return { x=self.x+self.w/2, y=self.y+self.h/2 }
end

function Rectangle.contains(self, x, y)
    return x >= self.x and y >= self.y and x <= self.x+self.w and y <= self.y+self.h
end

function Rectangle.fullyContains(self, rec2)
    return Rectangle.contains(self, rec2.x, rec2.y) and Rectangle.contains(self, rec2.x+rec2.w, rec2.y) and Rectangle.contains(self, rec2.x, rec2.y+rec2.h) and Rectangle.contains(self, rec2.x+rec2.w, rec2.y+rec2.h)
end

function Rectangle.draw(self, r, g, b, a)
    love.graphics.setColor(r, g, b, a)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
    love.graphics.setColor(255, 255, 255, 255)
end


return Rectangle