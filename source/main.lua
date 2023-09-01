-- PlayDate SDK CoreLibs
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

-- Community Libraries
import "scripts/Libraries/AnimatedSprite"
import "scripts/Libraries/LDtk"

-- My Scripts
import "scripts/GameScene"

-- Create GameScene Object
GameScene()

-- Constants
local pd <const> = playdate
local gfx <const> = playdate.graphics

-- Main Update Loop
function pd.update()
    gfx.sprite.update()
    pd.timer.updateTimers()
end