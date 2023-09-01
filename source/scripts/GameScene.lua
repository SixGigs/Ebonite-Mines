---@diagnostic disable: param-type-mismatch
local gfx <const> = playdate.graphics
local ldtk <const> = LDtk

ldtk.load("levels/world.ldtk", false)

class('GameScene').extends()

function GameScene:init()
    -- The string "Level_0" comes from the name of the LDtk level
    self:goToLevel("Level_0")
end

function GameScene:goToLevel(level_name)
    gfx.sprite.removeAll()

    for layer_name, layer in pairs(ldtk.get_layers(level_name)) do
        if layer.tiles then
            local tilemap = ldtk.create_tilemap(level_name, layer_name)

            local layerSprite = gfx.sprite.new()
            layerSprite:setTilemap(tilemap)
            layerSprite:setCenter(0, 0)
            layerSprite:moveTo(0, 0)
            layerSprite:setZIndex(layer.zIndex)
            layerSprite:add()

            -- The string "Solid" is the name I assigned solid tiles in LDtk
            -- This string must match the type of tile rule you want to exclude in future
            local emptyTiles = ldtk.get_empty_tileIDs(level_name, "Solid", layer_name)
            if emptyTiles then
                gfx.sprite.addWallSprites(tilemap, emptyTiles)
            end
        end
    end
end