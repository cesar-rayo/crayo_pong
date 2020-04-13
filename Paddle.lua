Paddle = Class{}

function Paddle:init(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.dy = 0
end

function Paddle:update(dt)
    if self.dy < 0 then
        self.y = math.max(0, self.y + self.dy * dt)
    else
        -- global var VIRTUAL_HEIGHT
        self.y = math.min(VIRTUAL_HEIGHT - self.height, self.y + self.dy * dt)
    end
end

function Paddle:render()
    -- create a "filled" rectangle in position (x,y) with size width, height
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end