Modules = {
    ambience = "ambience",
    avatar = "avatar",
    bundle = "bundle",
    ease = "ease",
    explode = "github.com/aduermael/modzh/explode:701075b",
    particles = "particles",
    sfx = "sfx",
    uitheme = "uitheme",
    ui = "uikit",
    fifo = "github.com/aduermael/modzh/fifo:05cc60a",
    poolSystem = "github.com/Donorhan/cubzh-library/pool-system:2ab8d15",
    roomModule = "github.com/Donorhan/cubzh-library/room-module:2ab8d15",
    dustifyModule = "github.com/Donorhan/cubzh-library/dustify:2ab8d15",
    helpers = "github.com/Donorhan/cubzh-library/helpers:2ab8d15",
    skybox = "github.com/Nanskip/cubzh-modules/skybox:8aa8b62",
}

Config = {
    Items = {
        "vico.coin",
        "littlecreator.dumbell",
        "claire.desk7",
        "piaa.book_shelf",
        "claire.sofa2",
        "claire.office_cabinet",
        "boumety.shelf3",
        "uevoxel.antena02",
        "uevoxel.bed",
        "kooow.bathtub_with_yl_duck",
        "wrden.bathroom_cabinet",
        "voxels.clothes_rack",
        "voxels.sidetable_4",
        "kooow.cardboard_box_long",
        "kooow.cardboard_box_small",
        "kooow.solarpanel",
        "chocomatte.ramen",
        "minadune.spikes",
        "claire.kitchen_counter",
        "kooow.table_round_gwcloth",
        "claire.painting15",
        "claire.painting6",
        "claire.painting9",
        "claire.painting12",
        "uevoxel.gym01",
        "chocomatte.treadmill",
        "uevoxel.couch",
        "pratamacam.lighting",
        "pratamacam.table01",
        "pratamacam.green_screen",
        "pratamacam.chair01",
        "pratamacam.snake_plant",
        "avatoon.book_shelf",
        "chocomatte.diner_food",
        "voxels.punching_bag",
        "uevoxel.vending_machine01",
        "claire.painting13",
        "voxels.drafting_table",
        "voxels.easel",
        "voxels.globe",
        "voxels.open_upright_piano",
        "pratamacam.vintage__robot",
        "chocomatte.tomato_crate",
    },
}

-----------------
-- Configuration
-----------------
local GAME_BONUSES = { DIG_FAST = 1, FOOD = 2, COIN = 3 }
local GAME_DEAD_REASON = { STARVING = 1, DAMAGE = 1, TRAMPLED = 2, FALL_DAMAGE = 3 }
local ROOM_DIMENSIONS = Number3(140, 62, 48)
local COLLISION_GROUP_PLAYER = CollisionGroups(1)
local COLLISION_GROUP_FLOOR_BELOW = CollisionGroups(2)
local COLLISION_GROUP_WALL = CollisionGroups(3)
local COLLISION_GROUP_BONUS = CollisionGroups(4)
local COLLISION_GROUP_ENNEMY = CollisionGroups(5)
local COLLISION_GROUP_PARTICLES = CollisionGroups(6)
local COLLISION_GROUP_PROPS = CollisionGroups(7)

local spawners = {}
local gameManager = {}
local levelManager = {}
local playerManager = {}
local uiManager = {}
local leaderboard = nil

local gameConfig = {
    gravity = Number3(0, -850, 0),
    floorInMemoryMax = 8,
    moneyProbability = 0.3,
    bonusProbability = 0.035,
    foodProbability = 0.01,
    bonusesRotationSpeed = 1.5 * math.pi,
    music = "https://raw.githubusercontent.com/Donorhan/cubzh-oops-no-elevator/main/dancing-with-shadows.mp3",
    musicVolume = 0.5,
    leaderboardName = "no-elevator",
    camera = {
        followSpeed = 0.1,
        defaultZoom = -175,
        playerOffset = Number3(0, 20, -175),
        zoomSpeed = 2.0,
        minZoom = -250,
        maxZoom = -100,
        lockTranslationOnY = true,
    },
    theme = {
        room = {
            saturation = 27,
            backgroundLightness = 58,
            wallLightness = 36,
            exteriorColor = Color(168, 165, 165),
        },
        ui = {
            backgroundColor = Color(32, 37, 48, 220),
            hungerBar = {
                width = 20,
                height = Screen.Height * 0.5,
                colorHSL = { 131, 78, 65 },
                padding = 4,
            }
        },
        roomThemeCount = 10,
        roomOffsetZ = ROOM_DIMENSIONS.Z * 0.5,
        skybox = "https://i.ibb.co/hgRhk0t/Standard-Cube-Map.png",
    },
    player = {
        defaultLife = 1,
        defaultSpeed = 75,
        defaultJumpHeight = 200,
        defaultDigForce = -15000,
        defaultAngerMax = 10, -- 10 seconds to destroy things
        destroyGroundAngerReductionAmount = 0.175, -- Anger reduction amount when destroying ground
        foodBonusTimeAdded = 8, -- Time added to the anger when eating food bonus
        viewRange = 3, -- Amount of rooms to the under the player
        floorImpactSize = Number3(2, 2, 2), -- Block to destroy on player impact
        bumpVelocity = Number2(0, 170), -- Bump velocity when player jump on something
        timeBetweenDashGhosts = 0.021,
        dashGhostDuration = 0.23,
        dashGhostColor = Color(157, 157, 255, 0.9),
        defaultLight = {
            radius = 32,
            hardness = 0.15,
            color = Color(0.9, 0.7, 0.9),
        },
    },
    points = {
        food = 100,
        destroyedGround = 1,
        destroyedProps = 10,
        coin = 1,
        killedEnnemies = 25,
    },
    ennemies = {
        police = {
            speed = 40,
        },
    },
    avatars = {
        gaetan = "",
        aduermael = "",
        nanskip = "",
        boumety = "",
        pratamacam = "",
        voxels = "",
        uevoxel = "",
    },
    howTo = {
        jumpState = false,
        jumpText = nil,
        digState = false,
        digText = nil,
    },
}


-----------------
--- Helpers
-----------------
local followPlayerPosition = function (avatar)
    local targetPosition = Player.Position
    if Player.IsHidden then
        targetPosition = Camera.Position
    end

    local targetRotation = helpers.math.lookAt(avatar.Position, targetPosition)
    avatar.Head.Rotation = targetRotation
end

local hierarchyActions = require("hierarchyactions")
local changeTint = function(shape, h)
    hierarchyActions:applyToDescendants(shape, { includeRoot = true }, function(o)
        if typeof(o) == "Shape" or typeof(o) == "MutableShape" then
            for i = 1, #o.Palette - 1 do
                local color = o.Palette[i].Color
                local HSLColor = helpers.colors.RGBToHSL(color)
                HSLColor.h = h
                HSLColor.s = 20
                local newColor = helpers.colors.HSLToRGB(HSLColor.h, HSLColor.s, HSLColor.l)

                o.Palette[i].Color = newColor
            end
        end
    end)
end

local inverseDirection = function (obj, direction, speed)
    local newDirection = direction or -obj.Motion.X
    if newDirection < 0 then
        obj.Motion:Set(-speed, 0, 0)
        ease:linear(obj.Rotation, 0.2).Y = math.rad(-90 + 360)
    else
        obj.Motion:Set(speed, 0, 0)
        ease:linear(obj.Rotation, 0.2).Y = math.rad(90)
    end
end

local clonePlayer = function()
    local ghost = Object()
    ghost.IsHidden = true
    ghost.Rotation = Player.Rotation
    ghost.Position = Player.Position
    ghost.Scale = Player.Scale
    ghost._palette = Palette()
    local color = Color(255, 255, 255, 0)
    for _ = 1, 30 do
        ghost._palette:AddColor(color)
    end
    
    hierarchyActions:applyToDescendants(Player, { includeRoot = true }, function(o)
        if typeof(o) == "Shape" or typeof(o) == "MutableShape" then
            local clonedPart = o:Copy()
            clonedPart:SetParent(ghost)
            clonedPart.Physics = PhysicsMode.Disabled
            clonedPart.CollidesWithGroups = COLLISION_GROUP_NONE
            clonedPart.CollisionGroups = COLLISION_GROUP_NONE
            clonedPart.IsUnlit = true
            clonedPart.Shadow = false
            clonedPart.InnerTransparentFaces = false
            clonedPart.LocalRotation = o.LocalRotation
            clonedPart.LocalPosition = o.LocalPosition
            clonedPart.LocalScale = o.LocalScale
            clonedPart.Palette = ghost._palette
        end
    end)

    return ghost
end

local spawnDashGhost = function(color, duration)
    local playerCloned = playerManager._dashGhostPool:acquire()
    if playerCloned == nil then
        return
    end

    playerCloned:SetParent(World)
    playerCloned.IsHidden = false
    playerCloned.Rotation = Player.Rotation
    playerCloned.Position = Player.Position
    playerCloned.Scale = Player.Scale

    local conf = {
        onUpdate = function(obj)
            local updatedColor = Color(color.R, color.G, color.B, obj.easeLerp)
            for i = 1, #playerCloned._palette do
                playerCloned._palette[i].Color = updatedColor
            end
        end,
        onDone = function()
            ease:cancel(playerCloned.easeColor)
            playerCloned.IsHidden = true
            playerCloned:RemoveFromParent()
            playerManager._dashGhostPool:release(playerCloned)
        end,
    }

    ease:cancel(playerCloned.easeColor)
    playerCloned.easeLerp = color.A / 255.0
    playerCloned.easeColor = ease:linear(playerCloned, duration, conf)
    playerCloned.easeColor.easeLerp = 0.0
end


-----------------
-- Spawners
-----------------
spawners = {
    coinPool = nil,
    groundParticlePool = nil,
    bonusesRotation = 0,
    lastFoodSpawnedFloorCount = 0,
    init = function ()
        spawners.coinPool = poolSystem.create(55, function() return spawners.createBonus(GAME_BONUSES.COIN) end, true)
        spawners.groundParticlePool = poolSystem.create(70, spawners.createGroundParticle, true)
    end,
    randomPositionInRoom = function(paddingX, paddingY)
        local x = math.random(-ROOM_DIMENSIONS.X / 2.0 + paddingX, ROOM_DIMENSIONS.X / 2.0 - paddingX)
        local y = paddingY
        local z = gameConfig.theme.roomOffsetZ

        return Number3(x, y, z)
    end,
    createGroundParticle = function()
        local oneCube = MutableShape()
        oneCube:AddBlock(Color.White, 0, 0, 0)
        oneCube.CollisionGroupsMask = 0
        oneCube.CollidesWithMask = 0
        oneCube.IsUnlit = true
        return oneCube
    end,
    createBonus = function(bonusType)
        local bonus
        local callback

        if bonusType == GAME_BONUSES.DIG_FAST then
            bonus = Shape(Items.littlecreator.dumbell)
            bonus.LocalRotation.X = 15
            callback = function(_)
                sfx("coin_1", { Position = bonus.Position, Pitch = 1.0 + math.random() * 0.15, Volume = 0.65 })
                playerManager.startDigging(5, true)
            end
        elseif bonusType == GAME_BONUSES.FOOD then
            bonus = Shape(Items.chocomatte.ramen)
            bonus.LocalRotation.X = 0.45
            bonus.LocalScale = Number3(0.6, 0.6, 0.6)
            callback = function(_)
                sfx("eating_4", { Position = bonus.Position, Pitch = 1.0 + math.random() * 0.15, Volume = 0.65 })
                playerManager._anger = math.max(0, playerManager._anger - gameConfig.player.foodBonusTimeAdded)
                gameManager.increaseStat("food", 1, bonus)
                spawners.spawnPointsText(Player.Position + Number3(0, 25, 0), gameConfig.points.food)
            end
        elseif bonusType == GAME_BONUSES.COIN then
            bonus = Shape(Items.vico.coin)
            bonus.LocalScale = Number3(0.85, 0.85, 0.85)
            callback = function(coin)
                sfx("coin_1", { Position = bonus.Position, Pitch = 1.0 + math.random() * 0.15, Volume = 0.65 })
                gameManager.increaseStat("coins", 1, bonus)
                spawners.coinPool:release(coin)
            end
        end

        bonus.IsUnlit = true
        bonus.CollisionGroups = COLLISION_GROUP_BONUS
        bonus.CollidesWithGroups = COLLISION_GROUP_PLAYER
        bonus.Physics = PhysicsMode.Trigger
        bonus.Pivot = Number3(bonus.Width * 0.5, bonus.Height * 0.5, bonus.Depth * 0.5)
        bonus.Tick = function(self)
            self.LocalRotation.Y = spawners.bonusesRotation
        end

        local config = {
            velocity = function()
                return Number3(((math.random() * 2) - 1) * 35, 30 + math.random(100), ((math.random() * 2) - 1) * 5)
            end,
            life = function()
                return 0.3
            end,
            color = function()
                return Color(244, 247, 153)
            end,
            scale = function()
                return 0.3 + math.random() * 0.5
            end,
        }
        local explosionEmitter = particles:newEmitter(config)

        bonus.OnCollisionBegin = function(self, collider)
            if collider ~= Player then
                return
            end

            explosionEmitter.Position = self.Position
            explosionEmitter:spawn(10)
            callback(self)
            self:RemoveFromParent()
        end

        return bonus
    end,
    spawnBonus = function(room, bonusType)
        if bonusType == nil then
            bonusType = GAME_BONUSES.DIG_FAST
        end

        local bonus = spawners.createBonus(bonusType)
        bonus:SetParent(room)

        local position = spawners.randomPositionInRoom(40, 0)
        bonus.LocalPosition = Number3(position.X, -30, 0)

        return bonus
    end,
    spawnPointsText = function(position, pointsCount)
        local t = Text()
        t.Text = "+" .. pointsCount
        t.IsUnlit = true
        t.Tail = false
        t.Color = Color.White
        t.FontSize = 8
        t.BackgroundColor = Color(0, 0, 0, 20)
        t:SetParent(World)
        t.Position = position
        t.lifetime = 0
        t.Tick = function (_, dt)
            t.lifetime = t.lifetime + dt
            t.Position.Y = t.Position.Y + (22 * dt)
            if t.lifetime >= 0.65 then
                t:RemoveFromParent()
            end
        end
    end,
    spawnCoins = function(room)
        local position = spawners.randomPositionInRoom(40, 0)
        local startX = position.X
        local startY = 32
        local spacing = 7

        local type = math.random(1, 2)
        if type == 1 then
            local rowCount = 3
            for row = 1, rowCount do
                local xOffset = -(row - 1) * (spacing / 2)

                for col = 1, row do
                    local x = startX + xOffset + (col - 1) * spacing
                    local y = startY - (row - 1) * spacing

                    local coin = spawners.coinPool:acquire()
                    coin:SetParent(room)
                    coin.LocalPosition = Number3(x, y, 0)
                end
            end
        elseif type == 2 then
            local rowCount = math.random(1, 3)
            local colCount = 3
            for row = 1, rowCount do
                for col = 1, colCount do
                    local x = startX + (col - 1) * spacing
                    local y = startY - (row - 1) * spacing

                    local coin = spawners.coinPool:acquire()
                    coin:SetParent(room)
                    coin.LocalPosition = Number3(x, y, 0)
                end
            end
        end
    end,
    spawnEnnemy = function(room, position, _ennemyType)
        local npc = MutableShape()
        npc:AddBlock(Color(0, 0, 0, 0), 0, 0, 0)
        npc.Pivot = Number3(0.5, 0, 0.5)
        npc.CollidesWithGroups = COLLISION_GROUP_FLOOR_BELOW + COLLISION_GROUP_WALL + COLLISION_GROUP_PROPS
        npc.CollisionGroups = COLLISION_GROUP_ENNEMY
        npc.Physics = PhysicsMode.Dynamic
        npc.Scale = Number3(8, 8, 8)
        npc.Rotation.Y = math.pi / 2

        local model = avatar:get({ usernameOrId = "fax", eyeBlinks = true, defaultAnimations = true })
        model:SetParent(npc)
        model.LocalPosition = Number3(0, 0, 0)
        model.Physics = PhysicsMode.Disabled
        model.LocalScale = Number3(0.5, 0.5, 0.5) / npc.Scale
        model.Shadow = true
        Timer(1, false, function()
            model.Animations.Walk:Play()
        end)

        local direction = math.random(1, 2) == 1 and -1 or 1
        inverseDirection(npc, direction, gameConfig.ennemies.police.speed)
        npc.kill = function(reason)
            npc.Physics = PhysicsMode.Disabled
            dustifyModule.dustify(npc, { direction = npc.Motion, velocity = Number3(50, 100, 5), bounciness = 0.15, collisionGroups = COLLISION_GROUP_PARTICLES, collidesWithGroups = COLLISION_GROUP_FLOOR_BELOW + COLLISION_GROUP_WALL })
            npc.IsHidden = true
            if reason == GAME_DEAD_REASON.TRAMPLED then
                sfx("eating_1",
                    { Position = npc.Position, Pitch = 1.0 + math.random() * 0.15, Volume = 0.65 })
                playerManager.calmDownAnger(1)
                gameManager.increaseStat("killedEnnemies", 1, npc)
                spawners.spawnPointsText(Player.Position + Number3(0, 20, 0), gameConfig.points.killedEnnemies)
            elseif reason == GAME_DEAD_REASON.FALL_DAMAGE then
                sfx("hurt_scream_male_" .. math.random(1, 5),
                    { Position = npc.Position, Pitch = 0.5 + math.random() * 0.15, Volume = 0.65 })
            end
    
            npc:RemoveFromParent()
            gameManager._cameraContainer.shake(10)
        end
    
        npc.takeDamage = function (damage, reason, _collider)
            npc.life = npc.life - damage
            if npc.life <= 0 then
                npc.kill(reason)
            else
                helpers.shape.flash(model.Body, Color.White, 0.25)
            end
        end
    
        npc.OnCollisionBegin = function(self, collider, normal)
            if not collider:GetParent() then
                return
            end

            if collider.CollisionGroups == COLLISION_GROUP_WALL or collider.CollisionGroups == COLLISION_GROUP_PROPS then
                if math.abs(normal.X) > 0.5 then
                    inverseDirection(npc, nil, gameConfig.ennemies.police.speed)
                end
            elseif collider.CollisionGroups == COLLISION_GROUP_FLOOR_BELOW and normal.Y >= 1.0 then
                if collider:GetParent():GetParent().id ~= self.spawnFloor then
                    self.takeDamage(self.life + 1, GAME_DEAD_REASON.FALL_DAMAGE, collider)
                end
            end
        end

        npc:SetParent(room)
        npc.LocalPosition = Number3(position.X, position.Y, 0)
        npc.spawnFloor = room:GetParent():GetParent().id
        npc.life = 1

        return npc
    end,
    spawnGroundParticle = function(position, color)
        local pcube = spawners.groundParticlePool:acquire()
        pcube.CollisionGroups = COLLISION_GROUP_PARTICLES
        pcube.CollidesWithGroups = COLLISION_GROUP_FLOOR_BELOW + COLLISION_GROUP_WALL

        pcube.Position = position
        pcube.Position.Z = 0
        pcube.LocalScale = Number3(1.5, 1.5, 1.5)
        pcube.LocalRotation = { math.random() * math.pi * 2.0,
            math.random() * math.pi * 2.0,
            0.0 }

        pcube.Physics = true
        pcube.Velocity.Y = math.random(30, 50)
        pcube.Velocity.X = math.random(-50, 50)

        -- Need to remove block before adding, or pcube colors wrap around
        local oldblock = pcube:GetBlock(0, 0, 0)
        if oldblock ~= nil then oldblock.Color = color end

        Timer(2, false, function()
            spawners.groundParticlePool:release(pcube)
            pcube:RemoveFromParent()
        end)

        return pcube
    end,
    update = function(dt)
        spawners.bonusesRotation = spawners.bonusesRotation - gameConfig.bonusesRotationSpeed * dt
        if spawners.bonusesRotation > 2 * math.pi then
            spawners.bonusesRotation = spawners.bonusesRotation - 2 * math.pi
        end
    end,
}


-----------------
-- Game manager
-----------------
gameManager = {
    _cameraContainer = nil,
    _money = 0,
    _score = 0,
    _stats = {
        coins = 0,
        food = 0,
        killedEnnemies = 0,
        destroyedProps = 0,
        destroyedGround = 0,
    },
    _playing = false,
    _music = nil,

    init = function()
        ambience:set({
            sky = {
                skyColor = Color(255,168,255),
                horizonColor = Color(213,144,201),
                abyssColor = Color(76,144,255),
                lightColor = Color(101,147,175),
                lightIntensity = 0.820000,
            },
            sun = {
                color = Color(245,227,194),
                intensity = 0.900000,
                rotation = Number3(1.0061164, 0.865181, 0.000000), -- rotation = Number3(1.061164, 3.665181, 0.000000),
            },
            ambient = {
                skyLightFactor = 0.070000,
                dirLightFactor = 0.220000,
            }
        })
        gameManager.initCamera()
        spawners.init()

        if gameConfig.music then
            HTTP:Get(gameConfig.music, function(res)
                if res.StatusCode ~= 200 then
                    return
                end

                _music = AudioSource()
                _music.Sound = res.Body
                _music.Volume = gameConfig.musicVolume
                _music.Loop = true
                _music.Spatialized = false
                World:AddChild(_music)
                _music:Play()
            end)
        end

        -- Load avatars
        for username, _ in pairs(gameConfig.avatars) do
            local model, _ = avatar:get({ usernameOrId = username, eyeBlinks = true, defaultAnimations = true })
            gameConfig.avatars[username] = model
        end
    end,
    initCamera = function()
        local cameraContainer = Object()
        cameraContainer.decay = 2
        cameraContainer.shakeMaxAmplitude = Number2(6, 12)
        cameraContainer.traumaPower = 1.5
        cameraContainer.trauma = 0
        cameraContainer:SetParent(World)

        cameraContainer.targetFollower = Object()
        cameraContainer.targetFollower:SetParent(cameraContainer)
        Camera:SetParent(World)
        Camera:SetModeFree()
        Camera.Rotation:Set(0, 0, 0)
        cameraContainer.time = 0

        -- Set zoom according screen size
        local minZoom = -190
        local maxZoom = -160
        local aspectRatioMultiplier = 1.2
        local function updateCameraZoom()
            local screenRatio = Screen.Width / Screen.Height
            local baseZoom = -175
            local adjustedZoom = baseZoom * (screenRatio * aspectRatioMultiplier)

            adjustedZoom = math.max(minZoom, math.min(maxZoom, adjustedZoom))

            gameConfig.camera.defaultZoom = adjustedZoom
            gameConfig.camera.playerOffset.Z = adjustedZoom
        end

        updateCameraZoom()
        Screen.DidResize = function()
            updateCameraZoom()
        end

        cameraContainer.Tick = function(_, dt)
            local playerPositionY = Player.Position.Y + gameConfig.camera.playerOffset.Y
            if playerPositionY < cameraContainer.targetFollower.LocalPosition.Y then
                cameraContainer.targetFollower.LocalPosition.Y = playerPositionY
            end
        
            if not gameConfig.camera.lockTranslationOnY then
                cameraContainer.targetFollower.LocalPosition.X = Player.Position.X + gameConfig.camera.playerOffset.X
            else
                cameraContainer.targetFollower.LocalPosition.X = 0
            end

            local shakeOffset = Number3.Zero
            if cameraContainer.trauma ~= 0 then
                cameraContainer.time = cameraContainer.time + dt * 10

                local traumaSquared = cameraContainer.trauma ^ cameraContainer.traumaPower
                
                local noiseX = math.sin(cameraContainer.time * 5.37) + math.sin(cameraContainer.time * 8.17) * 0.7
                local noiseY = math.cos(cameraContainer.time * 6.71) + math.cos(cameraContainer.time * 9.23) * 0.7

                shakeOffset.X = noiseX * traumaSquared * cameraContainer.shakeMaxAmplitude.X
                shakeOffset.Y = noiseY * traumaSquared * cameraContainer.shakeMaxAmplitude.Y
                
                cameraContainer.trauma = math.max(0, cameraContainer.trauma - cameraContainer.decay * dt)
            end

            cameraContainer.Position = shakeOffset
        
            local speed = gameConfig.camera.followSpeed * dt * 60
            local lerpedPositionY = (cameraContainer.targetFollower.Position.Y - Camera.Position.Y) * speed
            Camera.Position.Y = Camera.Position.Y + lerpedPositionY
        
            local lerpedPositionX = (cameraContainer.targetFollower.Position.X - Camera.Position.X) * speed
            Camera.Position.X = Camera.Position.X + lerpedPositionX
        
            local lerpedPositionZ = (gameConfig.camera.playerOffset.Z - Camera.Position.Z) * speed
            Camera.Position.Z = Camera.Position.Z + lerpedPositionZ
        end

        cameraContainer.shake = function(intensity)
            cameraContainer.trauma = math.min(cameraContainer.trauma + intensity, 1.0)
        end

        cameraContainer.zoom = function(targetZoom)
            gameConfig.camera.playerOffset.Z = math.max(gameConfig.camera.minZoom, math.min(gameConfig.camera.maxZoom, targetZoom))
        end

        gameManager._cameraContainer = cameraContainer
    end,
    increaseStat = function(stat, amount, _obj)
        gameManager._stats[stat] = gameManager._stats[stat] + amount
    end,
    startGame = function()
        gameManager._cameraContainer.targetFollower.Position = Number3.Zero
        Camera.Position:Set(0, 0, gameConfig.camera.playerOffset.Z)

        levelManager.reset()
        playerManager.reset()

        gameManager._playing = true
        gameManager._stats = {
            coins = 0,
            food = 0,
            killedEnnemies = 0,
            destroyedProps = 0,
            destroyedGround = 0,
        }

        uiManager.showHUD()
    end,
    endGame = function(reason)
        if not gameManager._playing then
            return
        end

        playerManager.onKilled(reason)
        gameManager._playing = false

        Timer(0.75, false, function()
            uiManager.showScoreScreen()
        end)
    end,
}

-----------------
-- Floors management
-----------------
levelManager = {
    _floors = nil,
    _lastFloorSpawned = 0,
    _floorWithoutZombieCount = 0,
    _totalFloorSpawned = 0,
    _lastRoomConfigs = {}, -- Used to avoid same rooms in a row
    _roofTop = nil,
    _roomsPool = nil,

    init = function()
        levelManager._floors = fifo()

        skybox.load({ url = gameConfig.theme.skybox }, function(obj)
            obj:SetParent(Camera)
            obj.Tick = function(self)
                self.Position = Camera.Position - Number3(self.Scale.X, self.Scale.Y, -self.Scale.Z) / 2
            end
        end)

        levelManager._roofTop = levelManager.generateRoom(true, -1)

        -- Pre-generate rooms
        local poolRoomConfig = 0
        levelManager._roomsPool = poolSystem.create(gameConfig.theme.roomThemeCount, function()
            poolRoomConfig = poolRoomConfig + 1
            if poolRoomConfig > gameConfig.theme.roomThemeCount then
                poolRoomConfig = 1
            end

            return levelManager.generateRoom(false, poolRoomConfig)
        end, true)
    end,
    currentFloor = function(positionY)
        return math.floor(positionY / ROOM_DIMENSIONS.Y)
    end,
    getNewRandomConfig = function()
        local maxAttempts = 10
        local attempts = 0
        local newConfig

        repeat
            newConfig = math.random(1, gameConfig.theme.roomThemeCount)
            attempts = attempts + 1
        until (not table.contains(levelManager._lastRoomConfigs, newConfig) or attempts >= maxAttempts)
        table.insert(levelManager._lastRoomConfigs, 1, newConfig)
        if #levelManager._lastRoomConfigs > 3 then
            table.remove(levelManager._lastRoomConfigs)
        end

        return newConfig
    end,
    reset = function()
        levelManager.removeFloors(#levelManager._floors)
        levelManager._floors:flush()
        levelManager._lastFloorSpawned = 0
        levelManager._totalFloorSpawned = 0
        levelManager._roomsPool:releaseAll()
        spawners.groundParticlePool:releaseAll()
        spawners.coinPool:releaseAll()
        levelManager.spawnFloors(gameConfig.player.viewRange)
    end,
    generateRoom = function (groundOnly, config)
        local room = Object()

        local hue = math.random(0, 360)
        local saturation = gameConfig.theme.room.saturation
        local backgroundColor = helpers.colors.HSLToRGB(hue, saturation, gameConfig.theme.room.backgroundLightness)
        local wallColor = helpers.colors.HSLToRGB(hue, saturation, gameConfig.theme.room.wallLightness)
        local bottomColor = helpers.colors.HSLToRGB(hue, saturation, math.random(65, 70))
        if groundOnly then
            bottomColor = nil
        end

        local roomConfig = {
            width = 36,
            height = (ROOM_DIMENSIONS.Y / 4.0) + 2, -- + 2 = bloc from ground & ceiling
            depth = (ROOM_DIMENSIONS.Z / 4.0),
            exteriorColor = gameConfig.theme.room.exteriorColor,
            bottom = {
                color = bottomColor,
                blocScale = 2,
                thickness = 1,
            },
            left = {
                blocScale = 3,
                color = wallColor,
                thickness = 2,
            },
            right = {
                blocScale = 2,
                color = wallColor,
                thickness = 2,
            },
            front = {
                ignore = true,
                thickness = 2,
                color = wallColor,
            },
            top = {
                blocScale = 1,
                thickness = 1,
                ignore = true,
            },
            back = {
                blocScale = 2,
                color = backgroundColor,
                thickness = 1,
            },
        }

        if groundOnly then
            roomConfig.left.ignore = false
            roomConfig.left.color = gameConfig.theme.room.exteriorColor
            roomConfig.right.ignore = false
            roomConfig.right.color = gameConfig.theme.room.exteriorColor
            roomConfig.back.ignore = false
            roomConfig.back.color = gameConfig.theme.room.exteriorColor
            roomConfig.height = 4
        end

        local roomStructure = roomModule.create(roomConfig)
        roomStructure.root:SetParent(room)
        roomStructure.root.Scale = Number3(4, 4, 4)
        roomStructure.walls[Face.Left].Shadow = true
        roomStructure.walls[Face.Right].Shadow = true

        if roomStructure.walls[Face.Back] then
            roomStructure.walls[Face.Back].Physics = PhysicsMode.Disabled
        end

        local roomProps = Object()
        roomProps:SetParent(room)
        roomProps.LocalPosition = Number3(0, (roomConfig.bottom.thickness * roomStructure.root.Scale.Y), 0)

        -- windows
        local windowChoice = math.random(1, 10)
        if windowChoice == 1 then
            roomStructure:createHoleFromBlockCoordinates(Face.Left, Number3(0, 6, 1), Number3(2, 4, 1))
        elseif windowChoice == 2 then
            roomStructure:createHoleFromBlockCoordinates(Face.Right, Number3(0, 6, 1), Number3( 2, 4, 1))
        end

        roomProps.config = config
        levelManager.addStaticProps(roomProps, hue)

        room.structure = roomStructure
        room.propsContainer = roomProps

        local dynamicPropsContainer = Object()
        dynamicPropsContainer:SetParent(roomProps)
        room.dynamicPropsContainer = dynamicPropsContainer

        -- Floor number
        local colorIntensity = math.max(255 - levelManager._totalFloorSpawned, 0)
        local t = Text()
        t:SetParent(room.propsContainer)
        t.Text = "0"
        t.Type = TextType.World
        t.Anchor = { 1, 0.5 }
        t.IsUnlit = true
        t.Color = Color(255, colorIntensity, colorIntensity)
        t.BackgroundColor = Color(0, 0, 0, 70)
        t.FontSize = 8
        t.LocalPosition = { ROOM_DIMENSIONS.X / 2.0 - 12, ROOM_DIMENSIONS.Y - 12, -ROOM_DIMENSIONS.Z * 0.5 }
        room.floorNumber = t

        return room
    end,
    destroyGround = function(floorCollider)
        local ray = Ray(Player.Position, Number3(0, -1, 0))
        local impact = ray:Cast(floorCollider, nil, true)
        if impact == nil or impact.Block == nil then
            return
        end

        gameManager._cameraContainer.shake(50)
        sfx("wood_impact_3", { Position = floorCollider.Position, Pitch = 0.5 + math.random() * 0.2, Volume = 0.65 })
        Client:HapticFeedback()
        for _ = 0, 10 do
        local particle = spawners.spawnGroundParticle(impact.Block.Position, impact.Block.Color)
            particle:SetParent(World)
        end

        floorCollider.Physics = PhysicsMode.StaticPerBlock
        local impactPosition = impact.Block.Coordinates
        floorCollider.room:createHoleFromBlockCoordinates(Face.Bottom, impactPosition, gameConfig.player.floorImpactSize)
        playerManager.calmDownAnger(gameConfig.player.destroyGroundAngerReductionAmount)
        gameManager.increaseStat("destroyedGround", 1, nil)
    end,
    damageProp = function(prop, damageCount)
        prop.life = prop.life - (damageCount or 1)
        if prop.life > 0 then
            local soundDamage = prop.soundDamage or "punch_1"
            sfx(soundDamage, { Position = prop.Position, Pitch = 0.8 + math.random() * 0.1, Volume = 0.55 })
            helpers.shape.flash(prop, prop.damageColor or Color.White, 0.25)
        else
            local destroySound = prop.destroySound or "gun_shot_2"
            sfx(destroySound, { Position = prop.Position, Pitch = 1.0 + math.random() * 0.1, Volume = 0.55 })
            dustifyModule.dustify(prop, { collisionGroups = COLLISION_GROUP_PARTICLES, collidesWithGroups = COLLISION_GROUP_FLOOR_BELOW + COLLISION_GROUP_WALL, bounciness = 0.15, stride = 5 })
            prop:RemoveFromParent()
            playerManager.calmDownAnger(3)
            gameManager.increaseStat("destroyedProps", 1, prop)
            spawners.spawnPointsText(Player.Position + Number3(0, 20, 0), gameConfig.points.destroyedProps)
        end
    end,
    prepareProp = function(floor, prop, soundDamage, destroySound, collide, disableShadow)
        prop.life = 1
        prop:SetParent(floor)
        prop.Shadow = not disableShadow
        if collide then
            prop.CollisionGroups = COLLISION_GROUP_PROPS
            prop.CollidesWithGroups = COLLISION_GROUP_PLAYER
            prop.lifeTime = 0
            prop.soundDamage = soundDamage
            prop.destroySound = destroySound
        else
            hierarchyActions:applyToDescendants(prop, { includeRoot = true }, function(o)
                o.CollisionGroups = COLLISION_GROUP_NONE
                o.CollidesWithGroups = COLLISION_GROUP_NONE
                o.Physics = PhysicsMode.Disabled
            end)
        end
    end,
    addStaticProps = function (floor, hue)
        if floor.config == -1 then
            local prop = Shape(Items.uevoxel.antena02)
            levelManager.prepareProp(floor, prop)
            prop.Physics = PhysicsMode.Disabled
            prop.Scale = Number3(0.6, 0.6, 0.6)
            prop.LocalRotation.Y = 9
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - 22, prop.Height * 0.5 - 3, -15)

            prop = Shape(Items.kooow.solarpanel)
            levelManager.prepareProp(floor, prop)
            prop.Physics = PhysicsMode.Disabled
            prop.Scale = Number3(0.5, 0.5, 0.5)
            prop.LocalRotation.Y = 0
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 13, prop.Height * 0.5 - 8, -15)

            -- Instructions
            local instructionsContainer = Object()
            instructionsContainer:SetParent(floor)
            instructionsContainer.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 - 3, 50, 0)

            local actionName = "Click"
            if Client.IsMobile then
                actionName = "Tap"
            end

            local t = Text()
            t:SetParent(instructionsContainer)
            t.Anchor = { 0, 0.5 }
            t.Text = "How to play"
            t.IsUnlit = true
            t.Tail = false
            t.Color = Color.White
            t.BackgroundColor = Color.Black
            t.FontSize = 8

            t = Text()
            t:SetParent(instructionsContainer)
            t.LocalPosition = Number3(0, -11, 0)
            t.Anchor = { 0, 0.5 }
            t.Text = actionName .. " to jump"
            t.IsUnlit = true
            t.Tail = false
            t.Color = Color.White
            t.BackgroundColor = Color(0, 0, 0, 180)
            t.FontSize = 5
            gameConfig.howTo.jumpText = t
            gameConfig.howTo.jumpState = false

            t = Text()
            t:SetParent(instructionsContainer)
            t.LocalPosition = Number3(0, -20, 0)
            t.Anchor = { 0, 0.5 }
            t.Text = actionName .. " in the air to dig"
            t.IsUnlit = true
            t.Tail = false
            t.Color = Color.White
            t.BackgroundColor = Color(0, 0, 0, 180)
            t.FontSize = 5
            gameConfig.howTo.digText = t
            gameConfig.howTo.digState = false
        elseif floor.config == 1 then
            local prop = Shape(Items.claire.desk7)
            levelManager.prepareProp(floor, prop)
            prop.Scale = Number3(0.6, 0.6, 0.6)
            prop.LocalRotation.Y = 90
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 20, prop.Height * 0.5 - 5, ROOM_DIMENSIONS.Z * 0.5 - 10)
            changeTint(prop, hue)

            prop = Shape(Items.claire.sofa2)
            levelManager.prepareProp(floor, prop)
            prop.LocalScale = Number3(1.2, 1.2, 1.2)
            prop.LocalRotation.Y = math.pi
            prop.LocalPosition = Number3(0, prop.Height * 0.5, ROOM_DIMENSIONS.Z * 0.5 - 11)
            changeTint(prop, hue)

            prop = Shape(Items.piaa.book_shelf)
            levelManager.prepareProp(floor, prop)
            prop.Physics = PhysicsMode.Disabled
            prop.Scale = Number3(0.5, 0.5, 0.5)
            prop.Pivot = Number3(0, prop.Height * 0.5, 0)
            prop.LocalRotation.Y = 0
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - 33, prop.Height * 0.5 - 12, ROOM_DIMENSIONS.Z * 0.5 - 10)
            changeTint(prop, hue)

            prop = Shape(Items.boumety.shelf3)
            levelManager.prepareProp(floor, prop)
            prop.Physics = PhysicsMode.Disabled
            prop.Scale = Number3(0.5, 0.5, 0.5)
            prop.LocalRotation.Y = 0
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 20, ROOM_DIMENSIONS.Y * 0.5 - 5, ROOM_DIMENSIONS.Z * 0.5 - prop.Depth)
            changeTint(prop, hue)

            prop = Shape(Items.claire.painting9)
            levelManager.prepareProp(floor, prop, nil, nil, false, true)
            prop.Rotation.Y = math.pi / 2
            prop.LocalPosition = Number3(0, prop.Height * 0.5 + 22, ROOM_DIMENSIONS.Z * 0.5 - 10)
            changeTint(prop, hue)
        elseif floor.config == 2 then
            local prop = Shape(Items.claire.desk7)
            levelManager.prepareProp(floor, prop)
            prop.Scale = Number3(0.6, 0.6, 0.6)
            prop.LocalRotation.Y = -90
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - 20, prop.Height * 0.5 - 5, ROOM_DIMENSIONS.Z * 0.5 - 15)
            changeTint(prop, hue)

            prop = Shape(Items.uevoxel.vending_machine01)
            levelManager.prepareProp(floor, prop)
            prop.LocalRotation.Y = math.pi
            prop.Pivot = Number3(prop.Width * 0.5, 0, prop.Depth * 0.5)
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - 45, 0, ROOM_DIMENSIONS.Z * 0.5 - 5)
            prop.Scale = Number3(0.7, 0.7, 0.7)
            changeTint(prop, hue)

            prop = Shape(Items.claire.painting13)
            levelManager.prepareProp(floor, prop, nil, nil, false, true)
            prop.Rotation.Y = math.pi / 2
            prop.LocalScale = Number3(0.5, 0.5, 0.5)
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 55, ROOM_DIMENSIONS.Y * 0.5 - 5, ROOM_DIMENSIONS.Z * 0.5 - 10)
            changeTint(prop, hue)
        elseif floor.config == 3 then
            local prop = Shape(Items.claire.desk7)
            levelManager.prepareProp(floor, prop)
            prop.Scale = Number3(0.7, 0.7, 0.7)
            prop.LocalRotation.Y = math.pi
            prop.LocalPosition = Number3(-29, prop.Height * 0.5 - 5, ROOM_DIMENSIONS.Z * 0.5 - prop.Depth * 0.5 - 2)
            changeTint(prop, hue)

            prop = Shape(Items.piaa.book_shelf)
            levelManager.prepareProp(floor, prop)
            prop.Scale = Number3(0.6, 0.6, 0.6)
            prop.LocalRotation.Y = math.pi
            prop.LocalPosition = Number3(10,  prop.Height * 0.5 - 12, ROOM_DIMENSIONS.Z * 0.5 - prop.Depth * 0.5 - 5)
            changeTint(prop, hue)

            prop = Shape(Items.avatoon.book_shelf)
            levelManager.prepareProp(floor, prop)
            prop.Scale = Number3(0.6, 0.6, 0.6)
            prop.LocalRotation.Y = math.pi / 2
            prop.LocalPosition = Number3(-20, ROOM_DIMENSIONS.Y * 0.5, ROOM_DIMENSIONS.Z * 0.5 - prop.Depth * 0.5)
            changeTint(prop, hue)
        elseif floor.config == 4 then
            local prop = Shape(Items.kooow.cardboard_box_long)
            levelManager.prepareProp(floor, prop)
            prop.Scale = Number3(0.5, 0.5, 0.5)
            prop.LocalRotation.Y = -0.5
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 25, 0, 5)
            changeTint(prop, hue)

            prop = prop:Copy()
            levelManager.prepareProp(floor, prop)
            prop.Scale = Number3(0.5, 0.5, 0.5)
            prop.LocalRotation.Y = -0.95
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 13, 0, -1)
            changeTint(prop, hue)

            prop = Shape(Items.kooow.cardboard_box_small)
            levelManager.prepareProp(floor, prop)
            prop.Scale = Number3(0.5, 0.5, 0.5)
            prop.LocalRotation.Y = -0.5
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 21, 7, 5)
            changeTint(prop, hue)

            prop = Shape(Items.kooow.cardboard_box_small)
            levelManager.prepareProp(floor, prop)
            prop.Scale = Number3(0.7, 0.7, 0.7)
            prop.LocalRotation.Y = -2.35
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - 31, 0, 7)
            changeTint(prop, hue)

            prop = Shape(Items.kooow.cardboard_box_small)
            levelManager.prepareProp(floor, prop)
            prop.Scale = Number3(0.85, 0.85, 0.85)
            prop.LocalRotation.Y = -2
            prop.LocalPosition = Number3(0, 0, 8)
            changeTint(prop, hue)

            prop = Shape(Items.pratamacam.vintage__robot)
            levelManager.prepareProp(floor, prop)
            prop.Scale = Number3(0.45, 0.45, 0.45)
            prop.LocalRotation.Y = -2.33
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - 15, prop.Height - 4, 6)
            changeTint(prop, hue)
        elseif floor.config == 5 then
            local prop = Shape(Items.kooow.cardboard_box_long)
            levelManager.prepareProp(floor, prop)
            prop.Scale = Number3(0.5, 0.5, 0.5)
            prop.LocalRotation.Y = -2
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - 35, 0, 4)
            changeTint(prop, hue)

            prop = prop:Copy()
            levelManager.prepareProp(floor, prop)
            prop.Scale = Number3(0.4, 0.4, 0.4)
            prop.LocalRotation.Y = -6
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 23, 0, 6)
            changeTint(prop, hue)
        elseif floor.config == 6 then
            local prop = Shape(Items.claire.kitchen_counter)
            levelManager.prepareProp(floor, prop)
            prop.LocalScale = Number3(0.7, 0.7, 0.7)
            prop.LocalPosition = Number3(-19, 13, 11)
            changeTint(prop, hue)

            prop = Shape(Items.claire.painting15)
            levelManager.prepareProp(floor, prop, nil, nil, false, true)
            prop.Rotation.Y = math.pi / 2
            prop.LocalScale = Number3(0.5, 0.5, 0.5)
            prop.LocalPosition = Number3(35, ROOM_DIMENSIONS.Y * 0.5 + 1, ROOM_DIMENSIONS.Z * 0.5 - 10)
            changeTint(prop, hue)
        elseif floor.config == 7 then
            local prop = Shape(Items.chocomatte.treadmill)
            levelManager.prepareProp(floor, prop)
            prop.LocalScale = Number3(0.5, 0.5, 0.5)
            prop.Rotation.Y = 0
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - 35, 0, 1)
            changeTint(prop, hue)

            prop = Shape(Items.chocomatte.treadmill)
            levelManager.prepareProp(floor, prop)
            prop.LocalScale = Number3(0.5, 0.5, 0.5)
            prop.Rotation.Y = 0
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - 20, 0, 1)
            changeTint(prop, hue)

            prop = Shape(Items.claire.painting6)
            levelManager.prepareProp(floor, prop, nil, nil, false, true)
            prop.Rotation.Y = math.pi / 2
            prop.LocalScale = Number3(0.5, 0.5, 0.5)
            prop.LocalPosition = Number3(35, ROOM_DIMENSIONS.Y * 0.5 - 5, ROOM_DIMENSIONS.Z * 0.5 - 10)
            changeTint(prop, hue)

            prop = Shape(Items.voxels.punching_bag)
            levelManager.prepareProp(floor, prop)
            prop.LocalScale = Number3(0.5, 0.5, 0.5)
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 10, 0, 3)
            changeTint(prop, hue)
        elseif floor.config == 8 then
            local prop = Shape(Items.pratamacam.lighting)
            levelManager.prepareProp(floor, prop)
            prop.LocalScale = Number3(0.5, 0.5, 0.5)
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 10, 0, -20)
            prop.LocalRotation.Y = 0.6
            changeTint(prop, hue)

            local light = Light()
            light:SetParent(prop)
            light.Color = Color(255, 255, 0)
            light.Hardness = 0.9
            light.Range = 110
            light.Angle = 0.4
            light.Type = LightType.Spot
            light.LocalPosition = Number3(15, 50, 15)
            light.LocalRotation.Y = 6.45
            light.LocalRotation.X = 0.1
            light.CastsShadows = true
            light.Tick = function(o, dt)
                o.Range = 110 + (math.sin(dt) * 0.5 + 0.5) * 100
            end

            prop = Shape(Items.pratamacam.green_screen)
            levelManager.prepareProp(floor, prop, nil, nil, false, true)
            prop.Pivot = Number3(prop.Width * 0.5, 0, prop.Depth * 0.5)
            prop.Rotation.Y = math.pi
            prop.LocalScale = Number3(0.6, 0.6, 0.6)
            prop.LocalPosition = Number3(0, ROOM_DIMENSIONS.Y * 0.5 - prop.Height * 0.5, ROOM_DIMENSIONS.Z * 0.5 - 8)
            changeTint(prop, hue)

            prop = Shape(Items.pratamacam.chair01)
            levelManager.prepareProp(floor, prop)
            prop.LocalRotation.Y = -1.9
            prop.LocalScale = Number3(0.5, 0.5, 0.5)
            prop.LocalPosition = Number3(18, 5, 5)
            changeTint(prop, hue)

            prop = Shape(Items.pratamacam.snake_plant)
            levelManager.prepareProp(floor, prop)
            prop.LocalScale = Number3(0.5, 0.5, 0.5)
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - 15, 5, ROOM_DIMENSIONS.Z * 0.5 - 15)
            changeTint(prop, hue)
        elseif floor.config == 9 then
            local prop = Shape(Items.voxels.sidetable_4)
            levelManager.prepareProp(floor, prop)
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - 43, prop.Height * 0.5 - 5, ROOM_DIMENSIONS.Z * 0.5 - 16)
            changeTint(prop, hue)

            prop = Shape(Items.wrden.bathroom_cabinet)
            levelManager.prepareProp(floor, prop)
            prop.Scale = Number3(0.7, 0.7, 0.7)
            prop.LocalRotation.Y = -math.pi / 2
            prop.LocalPosition = Number3(15, prop.Height * 0.5 - 12, ROOM_DIMENSIONS.Z * 0.5 - 16)
            changeTint(prop, hue)

            prop = Shape(Items.voxels.clothes_rack)
            prop.Scale = Number3(0.7, 0.7, 0.7)
            levelManager.prepareProp(floor, prop)
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 10, 0, ROOM_DIMENSIONS.Z * 0.5 - 16)
            changeTint(prop, hue)
        elseif floor.config == 10 then
            local prop = Shape(Items.voxels.easel)
            levelManager.prepareProp(floor, prop)
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 22, prop.Height * 0.5 - 5, ROOM_DIMENSIONS.Z * 0.5 - 5)
            prop.Scale = Number3(0.5, 0.5, 0.5)
            prop.LocalRotation.Y = math.pi / 2 + 0.72
            changeTint(prop, hue)

            prop = Shape(Items.voxels.globe)
            levelManager.prepareProp(floor, prop)
            prop.LocalRotation.Y = math.random() * math.pi * 2
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - 33, prop.Height * 0.5 - 5, ROOM_DIMENSIONS.Z * 0.5 - 12)
            prop.Scale = Number3(0.6, 0.6, 0.6)
            changeTint(prop, hue)

            prop = Shape(Items.claire.painting12)
            levelManager.prepareProp(floor, prop, nil, nil, false, true)
            prop.Rotation.Y = math.pi / 2
            prop.LocalScale = Number3(0.85, 0.85, 0.85)
            prop.LocalPosition = Number3(0, prop.Height * 0.5 + 11, ROOM_DIMENSIONS.Z * 0.5 - 10)
            changeTint(prop, hue)
        end
    end,
    addDynamicProps = function (propsContainer, config)
        if config == 1 then
            local prop = Shape(Items.claire.office_cabinet)
            levelManager.prepareProp(propsContainer, prop, "hitmarker_2", "gun_shot_2", true)
            prop.Scale = Number3(0.6, 0.6, 0.6)
            prop.LocalRotation.Y = 0
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - prop.Width * 0.5 - 4, prop.Height * 0.5 - 5, 0)
            prop.Physics = PhysicsMode.Static
            prop.life = 2

            local avatarGaetan = gameConfig.avatars.gaetan
            if not avatarGaetan:GetParent() then
                avatarGaetan:SetParent(propsContainer)
                avatarGaetan.Shadow = true
                avatarGaetan.Physics = PhysicsMode.Dynamic
                avatarGaetan.Rotation.Y = math.pi - 0.35
                avatarGaetan.LocalPosition = Number3(-35, 0, 15)
                avatarGaetan.Scale = Number3(0.5, 0.5, 0.5)
                avatarGaetan.Tick = followPlayerPosition

                local avatarAdrien = gameConfig.avatars.aduermael
                avatarAdrien.Shadow = true
                avatarAdrien:SetParent(propsContainer)
                avatarAdrien.Physics = PhysicsMode.Dynamic
                avatarAdrien.Rotation.Y = math.pi - 0.25
                avatarAdrien.LocalPosition = Number3(-22, 0, 15)
                avatarAdrien.Scale = Number3(0.5, 0.5, 0.5)
                avatarAdrien.Tick = followPlayerPosition
            end
        elseif config == 2 then
            local prop = Shape(Items.claire.sofa2)
            levelManager.prepareProp(propsContainer, prop, nil, nil, true)
            prop.life = 2
            prop.LocalScale = Number3(1.2, 1.2, 1.2)
            prop.LocalRotation.Y = math.pi / 2
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 11, prop.Height * 0.5, ROOM_DIMENSIONS.Z * 0.5 - 25)
        elseif config == 3 then
            local prop = Shape(Items.claire.sofa2)
            levelManager.prepareProp(propsContainer, prop, nil, nil, true)
            prop.life = 2
            prop.LocalScale = Number3(1.2, 1.2, 1.2)
            prop.LocalRotation.Y = math.pi / 2
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 12, prop.Height * 0.5 + 1, -2)

            prop = Shape(Items.uevoxel.bed)
            levelManager.prepareProp(propsContainer, prop, nil, nil, true)
            prop.life = 4
            prop.Scale = Number3(0.7, 0.7, 0.7)
            prop.LocalRotation.Y = -math.pi / 2
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - prop.Depth * 0.5, prop.Height * 0.5 - 3, ROOM_DIMENSIONS.Z * 0.5 - 29)
        elseif config == 4 then
        elseif config == 5 then
            local position = spawners.randomPositionInRoom(5, 0)
            for i = 1, 4 do
                local prop = Shape(Items.minadune.spikes)
                levelManager.prepareProp(propsContainer, prop, nil, nil, true)
                prop.life = 50
                prop.damageColor = Color(255, 0, 0)
                prop.Physics = PhysicsMode.Static
                prop.Scale = Number3(0.4, 0.5, 1.5)
                prop.LocalRotation.Y = 0
                prop.LocalPosition = Number3(position.X, prop.Height * 0.5 - 2, 0)
                prop.OnCollisionBegin = function(self, collider, normal)
                    if math.abs(normal.Y) < 0.5 then
                        return
                    end
    
                    if collider.CollisionGroups == COLLISION_GROUP_PLAYER then
                        playerManager.takeDamage(1, gameConfig.player.bumpVelocity, prop)
                    end
                end
                prop.Tick = function(_, _) end
                prop.LocalPosition.Z = prop.LocalPosition.Z + (i * 5) - 15
            end
        elseif config == 6 then
            local prop = Shape(Items.kooow.table_round_gwcloth)
            levelManager.prepareProp(propsContainer, prop, nil, nil, true)
            prop.life = 2
            prop.LocalScale = Number3(0.5, 0.7, 0.5)
            prop.Rotation.Y = math.pi / 2
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - 40, 0, 0)

            local foodPlate = Shape(Items.chocomatte.diner_food)
            foodPlate:SetParent(prop)
            foodPlate.LocalPosition = Number3(35, 15, 15)

            prop = Shape(Items.chocomatte.tomato_crate)
            levelManager.prepareProp(propsContainer, prop, nil, nil, true)
            prop.LocalScale = Number3(0.5, 0.5, 0.5)
            prop.LocalRotation.Y = math.pi / 2
            prop.life = 2
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + prop.Depth * 0.5, 0, -2)

            local character = gameConfig.avatars.boumety
            if not character:GetParent() then
                character.Physics = false
                character:SetParent(propsContainer)
                character.Scale = Number3(0.5, 0.5, 0.5)
                character.LocalPosition = Number3(43, 0, 15)
                character.Rotation.Y = math.pi - 0.25
                character.Tick = followPlayerPosition
            end
        elseif config == 7 then
            local prop = Shape(Items.uevoxel.gym01)
            levelManager.prepareProp(propsContainer, prop, nil, nil, true)
            prop.life = 2
            prop.Rotation.Y = math.pi
            prop.LocalScale = Number3(0.6, 0.6, 0.6)
            prop.LocalPosition = Number3(-18, 7, 4)

            prop = Shape(Items.uevoxel.gym01)
            levelManager.prepareProp(propsContainer, prop, nil, nil, true)
            prop.life = 2
            prop.Rotation.Y = math.pi
            prop.LocalScale = Number3(0.6, 0.6, 0.6)
            prop.LocalPosition = Number3(9, 7, 4)

            local character = gameConfig.avatars.nanskip
            if not character:GetParent() then
                character.Physics = false
                character.Shadow = true
                character:SetParent(propsContainer)
                character.Scale = Number3(0.5, 0.5, 0.5)
                character.LocalPosition = Number3(-38, 0, 10)
                character.Rotation.Y = math.pi - 0.25
                character.Tick = followPlayerPosition
            end
        elseif config == 8 then
            local prop = Shape(Items.pratamacam.table01)
            levelManager.prepareProp(propsContainer, prop, nil, nil, true)
            prop.life = 3
            prop.LocalScale = Number3(0.8, 0.8, 0.8)
            prop.LocalPosition = Number3(0, 3, -5)

            local character = gameConfig.avatars.pratamacam
            if not character:GetParent() then
                character.Physics = false
                character.Shadow = true
                character:SetParent(propsContainer)
                character.Scale = Number3(0.5, 0.5, 0.5)
                character.LocalPosition = Number3(0, 0, 10)
                character.Tick = followPlayerPosition
            end
        elseif config == 9 then
            local prop = Shape(Items.kooow.bathtub_with_yl_duck)
            levelManager.prepareProp(propsContainer, prop, nil, nil, true)
            prop.LocalRotation.Y = math.pi / 2
            prop.life = 3
            prop.Scale = Number3(0.7, 0.7, 0.7)
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - 24, prop.Height * 0.5 - 9, ROOM_DIMENSIONS.Z * 0.5 - 10)
        elseif config == 10 then
            local prop = Shape(Items.voxels.drafting_table)
            levelManager.prepareProp(propsContainer, prop, nil, nil, true)
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + prop.Width * 0.5 - 6.5, prop.Height * 0.5 - 5, -8)
            prop.Scale = Number3(0.5, 0.5, 0.5)
            prop.LocalRotation.Y = math.pi / 2
            prop.life = 2

            prop = Shape(Items.voxels.open_upright_piano)
            levelManager.prepareProp(propsContainer, prop, "piano_attack", nil, true)
            prop.life = 2
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - prop.Depth * 0.5 - 6, prop.Height * 0.5 - 16, 0)
            prop.Scale = Number3(0.5, 0.5, 0.5)
            prop.LocalRotation.Y = math.pi / 2

            local character = gameConfig.avatars.voxels
            if not character:GetParent() then
                character.Physics = false
                character.Shadow = true
                character:SetParent(propsContainer)
                character.Scale = Number3(0.5, 0.5, 0.5)
                character.LocalPosition = Number3(-10, 0, 7)
                character.Rotation.Y = math.pi - 0.6
                character.Tick = followPlayerPosition
            end

            local character = gameConfig.avatars.uevoxel
            if not character:GetParent() then
                character.Physics = false
                character.Shadow = true
                character:SetParent(propsContainer)
                character.Scale = Number3(0.5, 0.5, 0.5)
                character.LocalPosition = Number3(10, 0, 7)
                character.Rotation.Y = math.pi + 0.6
                character.Tick = followPlayerPosition
            end
        end
    end,
    addFloorBonuses = function(floor)
        if math.random() < gameConfig.moneyProbability then
            spawners.spawnCoins(floor)
        end

        local floorLevel = math.abs(levelManager._lastFloorSpawned)
        if floorLevel > 3 and levelManager._floorWithoutZombieCount > 1 then
            local position = spawners.randomPositionInRoom(15, 5)
            position.Y = 0
            spawners.spawnEnnemy(floor, position)
            levelManager._floorWithoutZombieCount = 0
        else
            levelManager._floorWithoutZombieCount = levelManager._floorWithoutZombieCount + 1
        end

        if math.random() < gameConfig.foodProbability then
            spawners.spawnBonus(floor, GAME_BONUSES.FOOD)
            spawners.lastFoodSpawnedFloorCount = 0
        else
            spawners.lastFoodSpawnedFloorCount = spawners.lastFoodSpawnedFloorCount + 1
        end

        if floorLevel > 5 and math.random() < gameConfig.bonusProbability then
            local bonusType = math.random(GAME_BONUSES.DIG_FAST, GAME_BONUSES.DIG_FAST)
            spawners.spawnBonus(floor, bonusType)
        end
    end,
    spawnFloors = function(floorCount)
        local startFloor = levelManager._lastFloorSpawned - 1
        for floorLevel = 0, floorCount - 1 do
            local currentFloor = startFloor - floorLevel

            local floor = nil
            if currentFloor == -1 then
                floor = levelManager._roofTop
            elseif currentFloor == -2 then
                floor = levelManager._roomsPool:acquire()
            else
                floor = levelManager._roomsPool:acquireRandom()
            end
            floor:SetParent(World)
            floor.id = currentFloor
            floor.Position.Y = currentFloor * ROOM_DIMENSIONS.Y
            floor.floorNumber.Text = levelManager._totalFloorSpawned

            -- Configure destructurable floor
            floor.structure:createWall(Face.Bottom, 2, floor.structure.config.bottom.color)
            floor.structure.walls[Face.Bottom].Physics = PhysicsMode.Static
            floor.structure.walls[Face.Bottom].CollisionGroups = COLLISION_GROUP_FLOOR_BELOW
            floor.structure.walls[Face.Bottom].CollidesWithGroups = COLLISION_GROUP_PLAYER
            floor.structure.walls[Face.Bottom].Shadow = true
            if floor.structure.walls[Face.Bottom].paintShape then
                floor.structure.walls[Face.Bottom].paintShape.CollisionGroups = COLLISION_GROUP_NONE
                floor.structure.walls[Face.Bottom].paintShape.CollidesWithGroups = COLLISION_GROUP_NONE
                floor.structure.walls[Face.Bottom].paintShape.Physics = false
            end

            -- Room dynamic content: bonuses & destructurable props
            levelManager.addDynamicProps(floor.dynamicPropsContainer, floor.propsContainer.config)
            if currentFloor < -1 then
                levelManager.addFloorBonuses(floor.dynamicPropsContainer)
            else
                floor.floorNumber.IsHidden = true
            end

            levelManager._floors:push(floor)
            levelManager._totalFloorSpawned = levelManager._totalFloorSpawned + 1
        end

        -- Remove previous floors
        levelManager._lastFloorSpawned = levelManager._lastFloorSpawned - floorCount
        if #levelManager._floors > gameConfig.floorInMemoryMax then
            levelManager.removeFloors(#levelManager._floors - gameConfig.floorInMemoryMax)
        end
    end,
    removeFloor = function(floor)
        while floor.dynamicPropsContainer.ChildrenCount > 0 do
            local child = floor.dynamicPropsContainer:GetChild(1)
            if child.poolIndex then
                spawners.coinPool:release(child)
            end

            child:RemoveFromParent()
        end

        if floor.poolIndex then
            levelManager._roomsPool:release(floor)
        end
        floor:RemoveFromParent()
    end,
    removeFloors = function(count)
        for _ = 1, count do
            local oldRoom = levelManager._floors:pop()
            if oldRoom then
                levelManager.removeFloor(oldRoom)
            end
        end
    end,
    update = function(dt)
        spawners.update(dt)

        if not gameManager._playing then
            return
        end

        local playerCurrentFloor = levelManager.currentFloor(Player.Position.Y)
        if playerCurrentFloor < playerManager._lastFloorReached then
            playerManager._lastFloorReached = playerCurrentFloor
            levelManager.spawnFloors(1)
        end
    end,
}

-----------------
-- Player management
-----------------
playerManager = {
    _digging = false,
    _diggingForceAccumulator = 0,
    _diggingInvincible = false,
    _lastFloorReached = 0,
    _life = 1,
    _jumpHeight = gameConfig.player.defaultJumpHeight,
    _speed = gameConfig.player.defaultSpeed,
    _anger = 0,
    _angerMax = gameConfig.player.defaultAngerMax,
    _invincible = false,
    _dashLastGhostElapsedTime = 0,
    _dashGhostPool = nil,

    init = function()
        Player.IsHidden = false
        Player.Head:AddChild(AudioListener)
        Player.CollisionGroups = COLLISION_GROUP_NONE
        Player.CollidesWithGroups = COLLISION_GROUP_WALL + COLLISION_GROUP_FLOOR_BELOW + COLLISION_GROUP_ENNEMY
        Player.OnCollisionBegin = playerManager.collisionBegin
        Player:SetParent(World)
        Player.Rotation:Set(0, math.rad(90), 0)

        -- light around player
        local l = Light()
        l.Radius = gameConfig.player.defaultLight.radius
        l.Hardness = gameConfig.player.defaultLight.hardness
        l.Color = gameConfig.player.defaultLight.color
        l.On = true
        l.LocalPosition.Z = -10
        l.LocalPosition.Y = 5
        l:SetParent(Player)
        Player.light = l

        -- particles
        local walkParticles = particles:newEmitter({
            physics = false,
            life = function()
                return math.random(1, 3) / 10.0
            end,
            velocity = function()
                return Number3(0, 0, 0)
            end,
            color = function()
                return Color(255, 255, 255)
            end,
            scale = function()
                return 1.5
            end,
            acceleration = function()
                return -gameConfig.gravity - Number3(0, -25, 0)
            end,
        })
        walkParticles:SetParent(Player)

        local t = 0.0
        local spawnDt = 0.05
        walkParticles.Tick = function(o, dt)
            t = t + dt
            while t > spawnDt do
                t = t - spawnDt

                if Player.IsOnGround and Player.Motion.X ~= 0 then
                    walkParticles:spawn(1)
                end
            end
        end

        playerManager._dashGhostPool = poolSystem.create(15, clonePlayer, true)
    end,
    reset = function()
        Player.Position = Number3(0, 0, 0)
        Player.Motion:Set(0, 0, 0)
        Player.Rotation:Set(0, math.rad(90), 0)
        Player.CollisionGroups = COLLISION_GROUP_PLAYER
        Player.Velocity = Number3.Zero
        Player.Physics = PhysicsMode.Dynamic
        Player.IsHidden = false
        playerManager._digging = false
        playerManager._diggingForceAccumulator = 0
        playerManager._invincible = false
        playerManager._diggingInvincible = false
        playerManager._lastFloorReached = 0
        playerManager._life = gameConfig.player.defaultLife
        playerManager._anger = 0
        playerManager._angerMax = gameConfig.player.defaultAngerMax
        gameManager._cameraContainer.zoom(gameConfig.camera.defaultZoom)
        gameConfig.camera.lockTranslationOnY = true
    end,
    calmDownAnger = function(value)
        playerManager._anger = math.max(0, playerManager._anger - value)
    end,
    startDigging = function(diggingForce, invincible)
        playerManager._digging = true
        playerManager._diggingForceAccumulator = diggingForce
        playerManager._diggingInvincible = invincible
        Player.light.Radius = 37
        Player.light.Hardness = 0.40
        Player.light.Color = Color(0.9, 0.7, 0.9)
    end,
    stopDigging = function()
        playerManager._digging = false
        playerManager._diggingForceAccumulator = 0
        playerManager._diggingInvincible = false
        Player.light.Radius = gameConfig.player.defaultLight.radius
        Player.light.Hardness = gameConfig.player.defaultLight.hardness
        Player.light.Color = gameConfig.player.defaultLight.color

        if Player.Motion.X == 0 then
            playerManager.reachedFirstFloor()
        end
    end,
    collisionBegin = function(self, collider, normal)
        if collider.CollisionGroups == COLLISION_GROUP_WALL then
            sfx("walk_concrete_1", {
                Position = Player.Position,
                Volume = 0.3,
                Pitch = 0.4 + math.random() * 0.2,
                Spatialized = true,
            })
            inverseDirection(self, nil, playerManager._speed)
        elseif collider.CollisionGroups == COLLISION_GROUP_FLOOR_BELOW then
            if playerManager._digging then
                if playerManager._diggingForceAccumulator > 0 then
                    levelManager.destroyGround(collider)
                    playerManager._diggingForceAccumulator = playerManager._diggingForceAccumulator - 1
                else
                    playerManager.stopDigging()
                end
            end
        elseif collider.CollisionGroups == COLLISION_GROUP_ENNEMY then
            if playerManager._invincible or playerManager._diggingInvincible then
                gameManager._cameraContainer.shake(750)
                levelManager.damageProp(collider, 9999)
                Client:HapticFeedback()
                return
            end

            -- Jump on ennemies
            if normal.Y > 0.8 then
                collider.takeDamage(1, GAME_DEAD_REASON.TRAMPLED)
                playerManager.stopDigging()
                Player.Velocity.Y = gameConfig.player.bumpVelocity.Y
                Client:HapticFeedback()
                gameManager._cameraContainer.shake(50)
                return
            end

            playerManager.takeDamage(1, Number2(-self.Motion.X * 20, 200), collider)
        elseif collider.CollisionGroups == COLLISION_GROUP_PROPS then
            if not playerManager._digging then
                if math.abs(normal.X) > 0.5 then
                    inverseDirection(self, nil, playerManager._speed)
                end
                return
            end

            if playerManager._invincible or playerManager._diggingInvincible then
                gameManager._cameraContainer.shake(750)
                levelManager.damageProp(collider, 9999)
                Client:HapticFeedback()
                return
            end

            gameManager._cameraContainer.shake(150)
            levelManager.damageProp(collider, 1)
            playerManager.stopDigging()
            Player.Velocity.Y = gameConfig.player.bumpVelocity.Y
            Player.Velocity.X = 0
            Client:HapticFeedback()
        end
    end,
    takeDamage = function(damageCount, _, collider)
        if playerManager._invincible or playerManager._diggingInvincible then
            if collider.takeDamage then
                collider.takeDamage(9999, GAME_DEAD_REASON.DAMAGE)
            end
            return
        end

        playerManager._life = playerManager._life - damageCount
        gameManager._cameraContainer.shake(damageCount * 50)

        if playerManager._life > 0 then
            sfx("hurtscream_1", { Position = Player.Position, Pitch = 1.0 + math.random() * 0.15, Volume = 0.65 })
        end
    end,
    reachedFirstFloor = function()
        Player.Motion:Set(playerManager._speed, 0, 0)
    end,
    onKilled = function(_)
        Player.IsHidden = true
        explode(Player.Body)
        Player.Motion:Set(0, 0, 0)
        Player.Physics = PhysicsMode.Disabled
        Player.IsHidden = true
        sfx("deathscream_3", { Position = Player.Position, Pitch = 1.0 + math.random() * 0.15, Volume = 0.65 })
        gameManager._cameraContainer.zoom(-20)
        gameConfig.camera.lockTranslationOnY = false
    end,
    update = function(dt)
        if not gameManager._playing then
            Player.Velocity = Number3.Zero
            return
        end

        -- Collisions can move player's depth so we must fix it here to avoid weird behaviors
        Player.Position.Z = 0

        if playerManager._digging then
            if playerManager._dashLastGhostElapsedTime >= gameConfig.player.timeBetweenDashGhosts then
                spawnDashGhost(gameConfig.player.dashGhostColor, gameConfig.player.dashGhostDuration)
                playerManager._dashLastGhostElapsedTime = 0
            else
                playerManager._dashLastGhostElapsedTime = playerManager._dashLastGhostElapsedTime + dt
            end
        end

        if playerManager._lastFloorReached < -1 then
            playerManager._anger = playerManager._anger + dt
            if playerManager._anger >= playerManager._angerMax then
                gameManager.endGame(GAME_DEAD_REASON.STARVING)
                return
            end
        end

        if playerManager._life <= 0 then
            gameManager.endGame(GAME_DEAD_REASON.DAMAGE)
            return
        end

        if playerManager._digging then
            Player.Velocity.Y = gameConfig.player.defaultDigForce
        end
    end
}

-----------------
-- UI --
-----------------
uiManager = {
    POWER_BAR_WIDTH = 100,
    POWER_BAR_HEIGHT = 100,
    ICONS_SIZE = 25,

    _gameOverScreen = nil,
    _HUDScreen = nil,
    _lifeShapes = {},
    _previousMoneyCount = 0,

    init = function()
    end,
    update = function(self, _)
        if uiManager._HUDScreen then
            if uiManager._angerBar then
                local hungerRatio = math.min(1, math.max(0, 1 - (playerManager._anger / playerManager._angerMax)))
                local maxHeight = gameConfig.theme.ui.hungerBar.height - gameConfig.theme.ui.hungerBar.padding
                uiManager._angerBar.Height = maxHeight * hungerRatio

                local startHue = gameConfig.theme.ui.hungerBar.colorHSL[1]
                local endHue = 0
                local lerpedHue = startHue * hungerRatio + endHue * (1 - hungerRatio)
                local color = helpers.colors.HSLToRGB(
                    lerpedHue,
                    gameConfig.theme.ui.hungerBar.colorHSL[2],
                    gameConfig.theme.ui.hungerBar.colorHSL[3]
                )
                uiManager._angerBar.Color = color
            end
        end
    end,
    hideAllScreens = function()
        if uiManager._gameOverScreen then
            uiManager._gameOverScreen:remove()
            uiManager._gameOverScreen = nil
        end
        if uiManager._HUDScreen then
            uiManager._HUDScreen:remove()
            uiManager._HUDScreen = nil
        end
    end,
    showHUD = function()
        local uiPadding = uitheme.current.padding * 2
        local hudBackgroundColor = gameConfig.theme.ui.backgroundColor:Copy()
        hudBackgroundColor.A = 150

        local hungerBarBackground
        local frame = ui:createFrame(Color(0, 0, 0, 0))
        uiManager._HUDScreen = frame
        frame.Width = 25
        frame.Height = 50
        frame.Position = Number2(Screen.Width - frame.Width, uiPadding)
        frame.parentDidResize = function(_)
            frame.Position = Number2(Screen.Width - frame.Width, Screen.Height * 0.5 - frame.Height * 0.5)
        end

        -- Hunger bar
        local barPadding = gameConfig.theme.ui.hungerBar.padding
        hungerBarBackground = ui:createFrame(hudBackgroundColor)
        hungerBarBackground:setParent(frame)
        hungerBarBackground.Width = gameConfig.theme.ui.hungerBar.width
        hungerBarBackground.Height = gameConfig.theme.ui.hungerBar.height
        hungerBarBackground.LocalPosition = Number2(0, -hungerBarBackground.Height * 0.5)
        uiManager._angerBarBackground = hungerBarBackground

        local hungerBar = ui:createFrame(gameConfig.theme.ui.hungerBar.highColor)
        hungerBar:setParent(hungerBarBackground)
        hungerBar.Width = gameConfig.theme.ui.hungerBar.width - barPadding
        hungerBar.Height = gameConfig.theme.ui.hungerBar.height - barPadding
        hungerBar.LocalPosition = Number3(barPadding * 0.5, barPadding * 0.5, 0)
        uiManager._angerBar = hungerBar

        frame:parentDidResize()
    end,
    showScoreScreen = function()
        if uiManager._gameOverScreen then
            uiManager._gameOverScreen:remove()
            uiManager._gameOverScreen = nil
        end

        uiManager._angerBarBackground.IsHidden = true

        local uiPadding = uitheme.current.padding
        local textPadding = 10

        local frame = ui:createFrame(gameConfig.theme.ui.backgroundColor)
        uiManager._gameOverScreen = frame

        frame.Width = 400
        frame.Height = 400
        frame.parentDidResize = function()
            if Client.IsMobile then
                frame.Width = Screen.Width - uiPadding * 4
                frame.LocalPosition = Number2(uiPadding * 2, Screen.Height / 2 - frame.Height / 2 -
                Screen.SafeArea.Top)
            else
                frame.LocalPosition = { Screen.Width / 2 - frame.Width / 2, Screen.Height / 2 - frame.Height / 2 -
                Screen.SafeArea.Top }
            end
        end
        frame:parentDidResize()

        -- Score details
        local floorReached = math.abs(playerManager._lastFloorReached) - 1

        local totalScore = (
            gameManager._stats.coins +
            gameManager._stats.food * gameConfig.points.food +
            gameManager._stats.killedEnnemies * gameConfig.points.killedEnnemies +
            gameManager._stats.destroyedProps * gameConfig.points.destroyedProps
        ) * floorReached

        if floorReached > 35 then
            sfx("crowdapplause_1", { Pitch = 1.0 , Volume = 0.45 })
        end

        -- Save score to leaderboard
        leaderboard:set({
            score = totalScore,
            value = { totalScore = totalScore, floorReached = floorReached },
        })

        -- Title
        local titleText = ui:createText("Game Over!", Color.White, "big")
        titleText:setParent(frame)
        titleText.object.Anchor = { 0.5, 0 }
        titleText.LocalPosition = { frame.Width * 0.5, frame.Height - titleText.Height - uiPadding * 4 }

        -- Score details container
        local lineHeight = 36
        local linePadding = 4
        local lineColor = Color(255, 255, 255, 50)
        local detailsContainer = ui:createFrame(Color(0, 0, 0, 0))
        local darkTextColor = Color(32, 37, 48, 255)
        detailsContainer:setParent(frame)
        detailsContainer.Width = frame.Width - uiPadding * 4
        detailsContainer.Height = (lineHeight + linePadding) * 4 - linePadding
        detailsContainer.LocalPosition = { uiPadding * 2, titleText.LocalPosition.Y - detailsContainer.Height - uiPadding - 20 }

        -- Stats details
        local createStatLine = function(text, value, y, delay)
            Timer(delay, false, function()
                local statFrame = ui:createFrame(lineColor)
                statFrame:setParent(detailsContainer)
                statFrame.Width = detailsContainer.Width
                statFrame.Height = lineHeight
                statFrame.LocalPosition = { 0, y }

                local statText = ui:createText(text, Color.White, "small")
                statText:setParent(statFrame)
                statText.LocalPosition = { 8, statFrame.Height * 0.5 - statText.Height * 0.5 }

                local valueText = ui:createText(tostring(value), Color.White, "small")
                valueText:setParent(statFrame)
                valueText.object.Anchor = { 1, 0 }
                valueText.LocalPosition = { statFrame.Width - 8, statFrame.Height * 0.5 - valueText.Height * 0.5 }

                sfx("buttonpositive_2", { Pitch = 1.0 + delay, Volume = 0.65 })
            end)
        end

        createStatLine("Props destroyed", gameManager._stats.destroyedProps * gameConfig.points.destroyedProps, (lineHeight + linePadding) * 3, 0.4)
        createStatLine("Enemies defeated", gameManager._stats.killedEnnemies * gameConfig.points.killedEnnemies, (lineHeight + linePadding) * 2, 0.7)
        createStatLine("Food eaten", gameManager._stats.food * gameConfig.points.food, lineHeight + linePadding, 1.0)
        createStatLine("Coins collected", gameManager._stats.coins, 0, 1.3)

        local floorContainer
        Timer(1.6, false, function()
            floorContainer = ui:createFrame(Color(227, 208, 129))
            floorContainer:setParent(frame)
            floorContainer.Width = frame.Width - uiPadding * 4
            floorContainer.Height = lineHeight
            floorContainer.LocalPosition = { uiPadding * 2, detailsContainer.LocalPosition.Y - floorContainer.Height - uiPadding }

            local floorText = ui:createText("Floor reached", Color.White, "small")
            floorText:setParent(floorContainer)
            floorText.LocalPosition = { textPadding, floorContainer.Height * 0.5 - floorText.Height * 0.5 }
            floorText.Color = darkTextColor

            local floorValue = ui:createText("×" ..tostring(floorReached), Color.White, "small")
            floorValue:setParent(floorContainer)
            floorValue.object.Anchor = { 1, 0 }
            floorValue.LocalPosition = { floorContainer.Width - textPadding, floorContainer.Height * 0.5 - floorValue.Height * 0.5 }
            floorValue.Color = darkTextColor

            sfx("buttonpositive_3", { Pitch = 1.0 , Volume = 0.65 })
        end)

        -- Total score
        local nextButton
        Timer(2.1, false, function()
            local totalScoreContainer = ui:createFrame(Color(0, 0, 0, 0))
            totalScoreContainer:setParent(frame)
            totalScoreContainer.Width = frame.Width - uiPadding * 4
            totalScoreContainer.Height = lineHeight
            totalScoreContainer.LocalPosition = { uiPadding * 2, uiPadding }

            local scoreTitle = ui:createText("Total Score", Color.White, "default")
            scoreTitle:setParent(totalScoreContainer)
            scoreTitle.object.Anchor = { 0, 0.5 }
            scoreTitle.LocalPosition = { textPadding, totalScoreContainer.Height * 0.5 }

            local scoreValue = ui:createText(tostring(totalScore), Color.White, "big")
            scoreValue:setParent(totalScoreContainer)
            scoreValue.object.Anchor = { 1, 0.5 }
            scoreValue.LocalPosition = { totalScoreContainer.Width - textPadding, totalScoreContainer.Height * 0.5 }

            sfx("buttonnegative_1", { Pitch = 0.8 , Volume = 0.65 })
            nextButton.IsHidden = false
        end)

        -- Buttons container
        local buttonsContainer = ui:createFrame(Color(0, 0, 0, 0))
        buttonsContainer:setParent(frame)
        buttonsContainer.Width = frame.Width
        buttonsContainer.Height = 40
        buttonsContainer.LocalPosition = { 0, -buttonsContainer.Height - uiPadding }

        -- Next button (to leaderboard)
        nextButton = ui:createButton("Show leaderboard")
        nextButton.Width = buttonsContainer.Width
        nextButton.Height = buttonsContainer.Height
        nextButton:setColor(Color(70, 129, 244), Color.White)
        nextButton:setParent(buttonsContainer)
        nextButton.IsHidden = true
        nextButton.onRelease = function()
            if uiManager._gameOverScreen.IsHidden or nextButton.IsHidden then
                return
            end

            sfx("button_5", { Pitch = 1.0 , Volume = 1 })
            uiManager.showLeaderboardScreen(totalScore, floorReached)
        end
    end,
    showLeaderboardScreen = function(totalScore, floorReached)
        if uiManager._gameOverScreen then
            uiManager._gameOverScreen:remove()
            uiManager._gameOverScreen = nil
        end

        local uiPadding = uitheme.current.padding

        local frame = ui:createFrame(Color(0, 0, 0, 0))
        uiManager._gameOverScreen = frame

        frame.Width = 400
        frame.Height = 500
        frame.parentDidResize = function()
            if Client.IsMobile then
                frame.Width = Screen.Width - uiPadding * 4
                frame.LocalPosition = Number2(uiPadding * 2, Screen.Height / 2 - frame.Height / 2 -
                Screen.SafeArea.Top)
            else
                frame.LocalPosition = { Screen.Width / 2 - frame.Width / 2, Screen.Height / 2 - frame.Height / 2 -
                Screen.SafeArea.Top }
            end
        end
        frame:parentDidResize()

        local newGameButton = ui:createButton("Try again")
        newGameButton.Width = frame.Width - uiPadding * 2
        newGameButton:setColor(Color(51, 178, 73), Color.White)
        newGameButton:setParent(frame)
        newGameButton.LocalPosition = { uiPadding, uiPadding }
        newGameButton.onRelease = function()
            if uiManager._gameOverScreen.IsHidden then
                return
            end

            sfx("button_5", { Pitch = 1.0 , Volume = 1 })
            uiManager.hideAllScreens()
            gameManager.startGame()
            uiManager._angerBarBackground.IsHidden = false
        end

        local niceLeaderboard = requireNiceleaderboard()({
            leaderboardName = gameConfig.leaderboardName,
        })
        niceLeaderboard:setParent(frame)
        niceLeaderboard.Width = frame.Width - uiPadding * 2
        niceLeaderboard.Height = frame.Height - newGameButton.Height - uiPadding * 3
        niceLeaderboard.LocalPosition = { frame.Width / 2 - niceLeaderboard.Width / 2, uiPadding + newGameButton.Height + uiPadding }
        niceLeaderboard:show()
    end,
    markHowToAsDone = function(howToStepText)
        howToStepText.BackgroundColor = Color(0, 128, 0, 180)
        ease:inOutQuad(howToStepText, 0.15, {
            onDone = function()
                ease:inOutQuad(howToStepText, 0.15).Scale = Number3(1, 1, 1)
            end,
        }).Scale = Number3(1.15, 1.15, 1.0)
    end,
}

-----------------
-- Client --
-----------------
Client.OnStart = function()
    -- Global
    Screen.Orientation = "portrait"
    Config.ConstantAcceleration = gameConfig.gravity
    Dev.DisplayColliders = false

    -- Disable the default controls
    Client.DirectionalPad = nil
    Client.AnalogPad = nil
    Pointer.Drag = nil

    -- Init
    uiManager:init()
    levelManager.init()
    playerManager.init()
    gameManager.init()
    leaderboard = Leaderboard(gameConfig.leaderboardName)

    gameManager.startGame()
end

Client.Tick = function(dt)
    playerManager.update(dt)
    levelManager.update(dt)
    uiManager:update(dt)
end

Pointer.Down = function()
    if not gameManager._playing then
        return
    end

    if Player.IsOnGround then
        Player.Velocity.Y = playerManager._jumpHeight

        if not gameConfig.howTo.jumpState and gameConfig.howTo.jumpText ~= nil then
            uiManager.markHowToAsDone(gameConfig.howTo.jumpText)
            gameConfig.howTo.jumpState = true
        end
    elseif not playerManager._digging then
        playerManager.startDigging(1)

        if not gameConfig.howTo.digState and gameConfig.howTo.digText ~= nil then
            if not gameConfig.howTo.jumpState then
                uiManager.markHowToAsDone(gameConfig.howTo.jumpText)
                gameConfig.howTo.jumpState = true
            end

            uiManager.markHowToAsDone(gameConfig.howTo.digText)
            gameConfig.howTo.digState = true
        end
    end
end

-- TODO: remove when the module leaderboard will be ready
function requireNiceleaderboard()
    local mod = {}

    local MIN_HEIGHT = 100
    local MIN_WIDTH = 100
    local AVATAR_SIZE = 50

    local ui = require("uikit")
    local theme = require("uitheme").current
    local conf = require("config")
    local api = require("api")
    local uiAvatar = require("ui_avatar")

    local defaultConfig = {
        leaderboardName = "default",
        -- function(response) that can return a string to be displayed below score
        -- response is of this form { score = 1234, updated = OSTime, value = AnyLuaValue }
        extraLine = nil,
    }

    setmetatable(mod, {
        __call = function(_, config)
            if Client.BuildNumber < 186 then
                error("niceLeaderboard can only be used from Cubzh 0.1.8", 2)
            end
            local ok, err = pcall(function()
                config = conf:merge(defaultConfig, config, {
                    acceptTypes = {
                        leaderboardName = { "string" },
                        extraLine = { "function" },
                    },
                })
            end)
            if not ok then
                error("niceLeaderboard(config) - config error: " .. err, 2)
            end

            local status = "loading"
            local leaderboard

            local requests = {}
            local nbUserInfoToFetch = 0
            local pendingUserInfoRequestScore = {} -- requests to retrieve user info

            local function cancelRequests()
                for _, r in ipairs(requests) do
                    r:Cancel()
                end
                requests = {}
                nbUserInfoToFetch = 0
                pendingUserInfoRequestScore = {}
            end

            -- cache for users (usernames, avatars)
            local users = {}
            local friendScores = {}

            local recycledCells = {}

            local cellSelector = ui:frameScrollCellSelector()
            cellSelector:setParent(nil)

            local scroll

            local cellParentDidResize = function(self)
                local parent = scroll
                if parent == nil then
                    return
                end
                
                -- Définir une hauteur fixe pour toutes les cellules
                local CELL_HEIGHT = 80 -- Ajuster cette valeur selon vos besoins
                self.Width = parent.Width - 4
                self.Height = CELL_HEIGHT

                local availableWidth = self.Width - theme.padding * 3 - AVATAR_SIZE

                -- Ajuster l'échelle des textes
                self.username.object.Scale = 1
                local scale = math.min(1, availableWidth / self.username.Width)
                self.username.object.Scale = scale

                self.score.object.Scale = 1
                scale = math.min(1, availableWidth / self.score.Width)
                self.score.object.Scale = scale

                -- Calculer l'espace vertical disponible
                local totalTextHeight = self.username.Height + self.score.Height
                if self.extraLine:isVisible() then
                    self.extraLine.object.Scale = 1
                    scale = math.min(1, availableWidth / self.extraLine.Width)
                    self.extraLine.object.Scale = scale
                    totalTextHeight = totalTextHeight + self.extraLine.Height
                end

                -- Positionner les éléments verticalement de manière centrée
                local startY = (self.Height + totalTextHeight) * 0.5 - theme.padding

                self.username.pos = {
                    theme.padding * 2 + AVATAR_SIZE + availableWidth * 0.5 - self.username.Width * 0.5,
                    startY - self.username.Height,
                }
                
                self.score.pos = {
                    theme.padding * 2 + AVATAR_SIZE + availableWidth * 0.5 - self.score.Width * 0.5,
                    self.username.pos.Y - self.score.Height,
                }

                if self.extraLine:isVisible() then
                    self.extraLine.pos = {
                        theme.padding * 2 + AVATAR_SIZE + availableWidth * 0.5 - self.extraLine.Width * 0.5,
                        self.score.pos.Y - self.extraLine.Height,
                    }
                end

                -- Centrer l'avatar verticalement
                self.avatar.pos = {
                    theme.padding,
                    self.Height * 0.5 - AVATAR_SIZE * 0.5,
                }

                -- Ajuster la taille de l'avatar pour qu'il rentre dans la cellule
                self.avatar.Width = math.min(AVATAR_SIZE, self.Height - theme.padding * 2)
                self.avatar.Height = self.avatar.Width

                if self.userID == Player.UserID then
                    cellSelector:setParent(self)
                    cellSelector.Width = self.Width
                    cellSelector.Height = self.Height
                end
            end

            local function formatNumber(num)
                local formatted = tostring(num)
                local k
                while true do
                    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
                    if k == 0 then
                        break
                    end
                end
                return formatted
            end

            local messageCell

            local functions = {}

            local loadCell = function(index)
                if status == "scores" then
                    if index <= #friendScores then
                        local cell = table.remove(recycledCells)
                        if cell == nil then
                            cell = ui:frameScrollCell()

                            cell.username = ui:createText("", { color = Color.White })
                            cell.username:setParent(cell)

                            cell.score = ui:createText("", { color = Color(200, 200, 200) })
                            cell.score:setParent(cell)

                            cell.extraLine = ui:createText("", { color = Color(100, 100, 100), size = "small" })
                            cell.extraLine:setParent(cell)

                            cell.avatar = uiAvatar:getHeadAndShoulders({
                                -- usernameOrId = score.userID,
                            })
                            cell.avatar:setParent(cell)
                            cell.avatar.Width = AVATAR_SIZE
                            cell.avatar.Height = AVATAR_SIZE

                            cell.parentDidResize = cellParentDidResize
                            cell.onPress = function(_)
                                cell:getQuad().Color = Color(220, 220, 220)
                                Client:HapticFeedback()
                            end

                            cell.onRelease = function(self)
                                if self.userID ~= nil and self.username.Text ~= nil then
                                    Menu:ShowProfile({
                                        id = self.userID,
                                        username = self.username.Text,
                                    })
                                end
                                cell:getQuad().Color = Color.White
                            end

                            cell.onCancel = function(_)
                                cell:getQuad().Color = Color.White
                            end
                        end

                        local score = friendScores[index]

                        cell.userID = score.userID
                        cell.username.Text = score.user.username or "newbie"
                        cell.score.Text = formatNumber(score.score)
                        cell.avatar:load({ usernameOrId = score.userID })

                        cell:getQuad().Color = Color.White

                        if config.extraLine ~= nil then
                            cell.extraLine.Text = config.extraLine(score)
                            cell.extraLine:show()
                        else
                            cell.extraLine:hide()
                        end

                        cell:parentDidResize()

                        return cell
                    end
                elseif status == "no_scores" or status == "error" then
                    if index == 1 then
                        if messageCell == nil then
                            messageCell = ui:frame()

                            messageCell.label = ui:createText("This is a test", { color = Color.White, size = "small" })
                            messageCell.label:setParent(messageCell)

                            messageCell.btn = ui:buttonNeutral({ content = "Test", textSize = "small" })
                            messageCell.btn:setParent(messageCell)

                            messageCell.parentDidResize = function(self)
                                local parent = scroll
                                if parent == nil then
                                    return
                                end
                                self.Width = parent.Width - 4

                                messageCell.label.object.MaxWidth = self.Width - theme.padding * 2

                                self.Height = math.max(
                                    parent.Height - 4,
                                    messageCell.label.Height + self.btn.Height + theme.padding * 3
                                )

                                local h = self.btn.Height + theme.padding + self.label.Height
                                local y = self.Height * 0.5 - h * 0.5

                                self.btn.pos = {
                                    self.Width * 0.5 - self.btn.Width * 0.5,
                                    y,
                                }
                                self.label.pos = {
                                    self.Width * 0.5 - self.label.Width * 0.5,
                                    self.btn.pos.Y + self.btn.Height + theme.padding,
                                }
                            end
                        end

                        if status == "no_scores" then
                            messageCell.label.Text = "No scores to display yet!"
                            messageCell.btn.Text = "👥 Add Friends"
                            messageCell.btn.onRelease = function()
                                Menu:ShowFriends()
                            end
                        else
                            messageCell.label.Text = "❌ Error: couldn't load scores."
                            messageCell.btn.Text = "Retry"
                            messageCell.btn.onRelease = function()
                                functions.refresh()
                            end
                        end

                        messageCell:parentDidResize()

                        return messageCell
                    end
                end
            end

            local unloadCell = function(_, cell)
                cell:setParent(nil)
                if cell ~= messageCell then
                    table.insert(recycledCells, cell)
                end
            end

            local node = ui:frameTextBackground()

            scroll = ui:scroll({
                backgroundColor = theme.buttonTextColor,
                padding = 2,
                cellPadding = 2,
                direction = "down",
                -- centerContent = true,
                loadCell = loadCell,
                unloadCell = unloadCell,
            })
            scroll:setParent(node)
            scroll.pos = {
                theme.padding,
                theme.padding,
            }
            scroll:hide()

            local loading = require("ui_loading_animation"):create({ ui = ui })
            loading.parentDidResize = function(self)
                local parent = self.parent
                loading.pos = {
                    parent.Width * 0.5 - loading.Width * 0.5,
                    parent.Height * 0.5 - loading.Height * 0.5,
                }
            end
            loading:setParent(node)

            node.parentDidResizeSystem = function(self)
                self.Width = math.max(MIN_WIDTH, self.Width)
                self.Height = math.max(MIN_HEIGHT, self.Height)

                scroll.Width = self.Width - theme.padding * 2
                scroll.Height = self.Height - theme.padding * 2
            end
            node:parentDidResizeSystem()

            local localUserScrollIndex

            local function refresh()
                if nbUserInfoToFetch > 0 then
                    return
                end

                if not uiManager._gameOverScreen then
                    return
                end

                loading:hide()
                scroll:flush()
                scroll:refresh()
                scroll:show()

                if localUserScrollIndex ~= nil then
                    scroll:setScrollIndexVisible(localUserScrollIndex)
                end

                node:parentDidResizeSystem()
                if node.parentDidResize then
                    node:parentDidResize()
                end
            end
            functions.refresh = refresh

            local function displayScores(scores)
                status = "scores"
                nbUserInfoToFetch = #scores
                localUserScrollIndex = nil

                friendScores = scores

                for i, s in ipairs(friendScores) do
                    if s.userID == Player.UserID then
                        localUserScrollIndex = i
                    end

                    if users[s.userID] ~= nil then
                        s.user = users[s.userID]
                        nbUserInfoToFetch = nbUserInfoToFetch - 1
                        refresh()
                    else
                        if pendingUserInfoRequestScore[s.userID] == nil then
                            local req = api:getUserInfo(s.userID, function(userInfo, err)
                                if err ~= nil then
                                    pendingUserInfoRequestScore[s.userID] = nil
                                    return
                                end
                                pendingUserInfoRequestScore[s.userID] = nil
                                users[s.userID] = {
                                    username = userInfo.username,
                                }
                                s.user = users[s.userID]
                                nbUserInfoToFetch = nbUserInfoToFetch - 1
                                refresh()
                            end, {
                                "username",
                            })
                            pendingUserInfoRequestScore[s.userID] = s
                            table.insert(requests, req)
                        end
                    end
                end
            end

            leaderboard = Leaderboard(config.leaderboardName)

            local function load()
                status = "loading"
                cancelRequests()
                friendScores = {}

                cellSelector:setParent(nil)
                scroll:hide()
                scroll:flush()
                loading:show()

                -- fetch best scores first
                -- load neighbors only if user not in top 5
                local req = leaderboard:get({
                    mode = "best",
                    friends = true,
                    limit = 10,
                    callback = function(scores, err)
                        if err ~= nil then
                            if string.find(err, "404") then
                                status = "no_scores"
                            else
                                status = "error"
                            end
                            refresh()
                            return
                        end

                        for _, s in ipairs(scores) do
                            if s.userID == Player.UserID then
                                -- found user in top, display scores!
                                displayScores(scores)
                                return
                            end
                        end

                        -- local user not in top, get neighbors instead
                        cancelRequests()
                        local req = leaderboard:get({
                            mode = "neighbors",
                            friends = true,
                            limit = 10,
                            callback = function(scores, err)
                                if err ~= nil then
                                    if string.find(err, "404") then
                                        status = "no_scores"
                                    else
                                        status = "error"
                                    end
                                    refresh()
                                    return
                                end
                                displayScores(scores)
                            end,
                        })
                        table.insert(requests, req)
                    end,
                })
                table.insert(requests, req)
            end

            node.reload = load
            load()

            return node
        end,
    })

    return mod
end