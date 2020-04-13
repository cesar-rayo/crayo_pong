-- import lua file
push = require 'push'

-- import classes
Class = require 'class'
require 'Paddle'
require 'Ball'

-- window size
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- virtual size (rendering window)
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

-- movement speed
PADDLE_SPEED = 200

-- GAME States: start, play, serve, done

TARGET_SCORE = 3

-- initialize application
function love.load()
    -- set the title of our application window
    love.window.setTitle('Pong')

    -- default filter
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- initialize random class (unique base on unix time)
    math.randomseed(os.time())

    -- import new font with default size
    retroFont = love.graphics.newFont('font.ttf', 8)
    scoreFont = love.graphics.newFont('font.ttf', 32)
    largeFont = love.graphics.newFont('font.ttf', 16)

    -- load audio files in memory (static)
    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static')
    }

    -- set window using push lib
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,  -- window is resizable
        vsync = true
    })

    -- scoreboard initialize
    player1Score = 0
    player2Score = 0

    -- starts serving player 1
    servingPlayer = 1

    player1 = Paddle(10, 30, 5, 20)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)

    -- place a ball in the middle of the screen
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

    -- game state variable used to transition between different parts of the game
    -- (used for beginning, menus, main game, high score list, etc.)
    -- we will use this to determine behavior during render and update
    gameState = 'start'
end

-- Calculate new window size
function love.resize(w, h)
    push:resize(w, h)
end

-- Controls
function love.update(dt)
    if gameState == 'serve' then
        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dx = math.random(140, 200)
        else
            ball.dx = -math.random(140, 200)
        end
    elseif gameState == 'play' then
        -- detect ball collision with paddles
        if ball:collides(player1) then
            -- changes ball direction
            ball.dx = -ball.dx * 1.03 -- increase speed in 30 %
            ball.x = player1.x + 5 -- where 5 is paddle width

            -- keep Y  direction but randomize bouncing angle
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
            sounds['paddle_hit']:play()
        end
        if ball:collides(player2) then
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - 4

            -- keep Y  direction but randomize bouncing angle
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
            sounds['paddle_hit']:play()
        end

        -- detect upper and lower screen boundary and reverse
        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        -- -4 to account for the ball's size
        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        -- Detect when ball goes beyond edges
        if ball.x < 0 then
            servingPlayer = 1
            player2Score = player2Score + 1
            sounds['score']:play()

            if player2Score == TARGET_SCORE then
                winningPlayer = 2
                gameState = 'done'
            else
                gameState = 'serve'
                -- places the ball in the middle of the screen, no velocity
                ball:reset()
            end
        end

        if ball.x > VIRTUAL_WIDTH then
            servingPlayer = 2
            player1Score = player1Score + 1
            sounds['score']:play()
            
            if player1Score == TARGET_SCORE then
                winningPlayer = 1
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
            end
        end
    end

    -- player 1 controls
    -- set speed
    if love.keyboard.isDown('w') then
        player1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_SPEED
    else
        player1.dy = 0
    end

    -- player 2 controls
    -- set speed
    if love.keyboard.isDown('up') then
        player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        player2.dy = PADDLE_SPEED
    else
        player2.dy = 0
    end

    -- update our ball based on its DX and DY only if we're in play state;
    -- scale the velocity by dt so movement is framerate-independent
    if gameState == 'play' then
        ball:update(dt)
    end

    -- execute Paddle:update
    player1:update(dt)
    player2:update(dt)
end

-- Menu
function love.keypressed(key)
    -- keys can be accessed by string name
    if key == 'escape' then
        -- exit
        love.event.quit()
    -- if key enter is down
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'done' then
            -- reset game
            gameState = 'serve'

            ball:reset()

            player1Score = 0
            player2Score = 0

            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end
        end
    end
end

function love.draw()
    -- begin rendering at virtual resolution
    push:apply('start')
    
    -- background color is set as rgba, where each values is between 0 and 1
    love.graphics.clear(.40, .45, .52, 255)
    
    -- print scoreboard
    displayScore()
    
    if gameState == 'start' then
        love.graphics.setFont(retroFont)
        love.graphics.printf('Welcome to Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to begin!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        love.graphics.setFont(retroFont)
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!", 
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
        -- no UI messages to display in play
    elseif gameState == 'done' then
        -- UI messages
        love.graphics.setFont(largeFont)
        love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!',
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(retroFont)
        love.graphics.printf('Press Enter to restart!', 0, 30, VIRTUAL_WIDTH, 'center')
    end

    -- render ball
    ball:render()
    
    -- render player 1
    -- set color rgba, where each values is between 0 and 1
    love.graphics.setColor(.08, .58, .81)
    player1:render()

    -- render player 2
    -- set color rgba, where each values is between 0 and 1
    love.graphics.setColor(1, .24, .24)
    player2:render()

    displayFPS()

    -- end rendering at virtual resolution
    push:apply('end')
end

function displayFPS()
    -- simple FPS display across all states
    love.graphics.setFont(retroFont)
    love.graphics.setColor(0, 1, 0, 255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
end

function displayScore()
    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50, 
        VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30,
        VIRTUAL_HEIGHT / 3)
end
