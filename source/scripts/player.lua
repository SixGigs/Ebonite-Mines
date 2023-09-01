-- PlayDate Constants
local pd <const> = playdate
local gfx <const> = playdate.graphics

-- Player Class
class('Player').extends(AnimatedSprite)

-- Initialise the Player Class
function Player:init(x, y, gameManager)
    -- Game Manager
    self.gameManager = gameManager

    -- Create State Machine
    local playerImageTable = gfx.imagetable.new("images/player-table-16-16")
    Player.super.init(self, playerImageTable)

    self:addState("idle", 1, 1)
    self:addState("run", 2, 3, {tickStep = 4})
    self:addState("jump", 4, 4)
    self:addState("dash", 4, 4)
    self:playAnimation()

    -- Sprite Properties
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.Player)
    self:setTag(TAGS.Player)
    self:setCollideRect(3, 3, 10, 13)

    -- Physics Properties
    self.xVelocity = 0
    self.yVelocity = 0
    self.gravity = 1.0
    self.maxSpeed = 2.0
    self.jumpVelocity = -6 -- This number is negative as we are moving up the screen
    self.drag = 0.1
    self.minimumAirSpeed = 0.5

    -- Player Abilities
    self.doubleJumpAbility = false
    self.dashAbility = false

    -- Double Jump
    self.doubleJumpAvailable = true

    -- Dash
    self.dashAvailable = true
    self.dashSpeed = 8
    self.dashMinimumSpeed = 3
    self.dashDrag = 0.8

    -- Player State
    self.touchingGround = false
    self.touchingCeiling = false
    self.touchingWall = false
    self.dead = false
end



-- The Default Collision Response is to Slide at the Moment
function Player:collisionResponse(other)
    local tag = other:getTag()
    if tag == TAGS.Hazard or tag == TAGS.Pickup then
        return gfx.sprite.kCollisionTypeOverlap
    end
    return gfx.sprite.kCollisionTypeSlide
end



-- This Method Updates the Player Animation, State, and Collisions
function Player:update()
    if self.dead then
        return
    end

    self:updateAnimation()

    self:handleState()
    self:handleMovementAndCollisions()
end



-- This Method Handles the Player States Set up Using the AnimatedSprite Library
function Player:handleState()
    if self.currentState == "idle" then
        self:applyGravity()
        self:handleGroundInput()
    elseif self.currentState == "run" then
        self:applyGravity()
        self:handleGroundInput()
    elseif self.currentState == "jump" then
        if self.touchingGround then
            self:changeToIdleState()
        end

        self:applyGravity()
        self:applyDrag(self.drag)
        self:handleAirInput()
    elseif self.currentState == "dash" then
        self:applyDrag(self.dashDrag)
        if (math.abs(self.xVelocity) <= self.dashMinimumSpeed) then
            self:changeToFallState()
        end
    end
end



-- This Method Handles Player Movement With Collisions
function Player:handleMovementAndCollisions()
    local _, _, collisions, length = self:moveWithCollisions(self.x + self.xVelocity, self.y + self.yVelocity)

    self.touchingGround = false
    self.touchingCeiling = false
    self.touchingWall = false
    local died = false

    for i = 1, length do
        -- Collision normal for ground is: -1 (on the y axis)
        -- Collision normal for the ceiling is: 1 (on the y axis)
        -- Collision normal for wall can being either (on the x axis)
        -- If the player touches anything with a Y normal of -1 (A.k.a: the ground), set touchingGround to true
        local collision = collisions[i]
        local collisionType = collision.type
        local collisionObject = collision.other
        local collisionTag = collisionObject:getTag()
        if collisionType == gfx.sprite.kCollisionTypeSlide then
            if collision.normal.y == -1 then
                self.touchingGround = true
                self.doubleJumpAvailable = true
                self.dashAvailable = true
            elseif collision.normal.y == 1 then
                self.touchingCeiling = true
            end

            if collision.normal.x ~= 0 then
                self.touchingWall = true
            end
        end

        if collisionTag == TAGS.Hazard then
            died = true
        elseif collisionTag == TAGS.Pickup then
            collisionObject:pickUp(self)
        end
    end

    -- Flip the player sprite depending on if they are moving left or right
    if self.xVelocity < 0 then
        self.globalFlip = 1
    elseif self.xVelocity > 0 then
        self.globalFlip = 0
    end

    if self.x < 0 then
        self.gameManager:enterRoom("west")
    elseif self.x > 400 then
        self.gameManager:enterRoom("east")
    elseif self.y < 0 then
        self.gameManager:enterRoom("north")
    elseif self.y > 240 then
        self.gameManager:enterRoom("south")
    end

    if died then
        self:die()
    end
end



function Player:die()
    self.xVelocity = 0
    self.yVelocity = 0
    self.dead = true
    self:setCollisionsEnabled(false)

    pd.timer.performAfterDelay(200, function()
        self:setCollisionsEnabled(true)
        self.dead = false
        self.gameManager:resetPlayer()
    end)
end



-- Input Helper Functions
function Player:handleGroundInput()
    if pd.buttonJustPressed(pd.kButtonA) then
        self:changeToJumpState()
    elseif pd.buttonJustPressed(pd.kButtonB) and self.dashAvailable and self.dashAbility then
        self:changeToDashState()
    elseif pd.buttonIsPressed(pd.kButtonLeft) then
        self:changeToRunState("left")
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self:changeToRunState("right")
    else
        self:changeToIdleState()
    end
end



function Player:handleAirInput()
    if pd.buttonJustPressed(pd.kButtonA) and self.doubleJumpAvailable and self.doubleJumpAbility then
        self.doubleJumpAvailable = false
        self:changeToJumpState()
    elseif pd.buttonJustPressed(pd.kButtonB) and self.dashAvailable and self.dashAbility then
        self:changeToDashState()
    elseif pd.buttonIsPressed(pd.kButtonLeft) then
        self.xVelocity = -self.maxSpeed
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self.xVelocity = self.maxSpeed
    end
end



-- State Transitions
function Player:changeToIdleState()
    self.xVelocity = 0
    self:changeState("idle")
end



function Player:changeToRunState(direction)
    if direction == "left" then
        self.xVelocity = -self.maxSpeed
        self.globalFlip = 1
    elseif direction == "right" then
        self.xVelocity = self.maxSpeed
        self.globalFlip = 0
    end
    self:changeState("run")
end



function Player:changeToJumpState()
    self.yVelocity = self.jumpVelocity
    self:changeState("jump")
end



function Player:changeToFallState()
    self:changeState("jump")
end



function Player:changeToDashState()
    self.dashAvailable = false
    self.yVelocity = 0
    if pd.buttonIsPressed(pd.kButtonLeft) then
        self.xVelocity = self.xVelocity - self.dashSpeed
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self.xVelocity = self.xVelocity + self.dashSpeed
    else
        if self.globalFlip == 1 then
            self.xVelocity = self.xVelocity - self.dashSpeed
        else
            self.xVelocity = self.xVelocity + self.dashSpeed
        end
    end
    self:changeState("dash")
end



-- Physics Helper Functions
function Player:applyGravity()
    self.yVelocity = self.yVelocity + self.gravity
    if self.touchingGround or self.touchingCeiling then
        self.yVelocity = 0
    end
end



function Player:applyDrag(amount)
    if self.xVelocity > 0 then
        self.xVelocity = self.xVelocity - amount
    elseif self.xVelocity < 0 then
        self.xVelocity = self.xVelocity + amount
    end

    if math.abs(self.xVelocity) < self.minimumAirSpeed or self.touchingWall then
        self.xVelocity = 0
    end
end