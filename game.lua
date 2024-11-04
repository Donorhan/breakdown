Modules = {
    ambience = "ambience",
    avatar = "avatar",
    bundle = "bundle",
    ease = "ease",
    particles = "particles",
    sfx = "sfx",
    uitheme = "uitheme",
    ui = "uikit",
    explode = "github.com/aduermael/modzh/explode:b9e5d20",
    fifo = "github.com/aduermael/modzh/fifo:05cc60a",
    niceLeaderboardModule = "github.com/aduermael/modzh/niceleaderboard",
    poolSystem = "github.com/Donorhan/cubzh-library/pool-system:39f1c19",
    roomModule = "github.com/Donorhan/cubzh-library/room-module:39f1c19",
    helpers = "github.com/Donorhan/cubzh-library/helpers:39f1c19",
    skybox = "github.com/Nanskip/cubzh-modules/skybox:8aa8b62",
}

Config = {
    Items = {
        "vico.coin",
        "littlecreator.dumbell",
        "pratamacam.shortcake_slice",
        "chocomatte.police_martin",
        "mrchispop.heart",
        "raph.helmet_test",
        "pratamacam.backpack",
        "claire.desk7",
        "piaa.book_shelf",
        "claire.sofa2",
        "claire.office_cabinet",
        "boumety.shelf3",
        "claire.office_door",
        "pratamacam.vending_machine",
        "uevoxel.antena02",
        "kooow.cardboard_box_long",
        "kooow.cardboard_box_small",
        "kooow.solarpanel",
        "chocomatte.ramen",
    },
}

-----------------
-- Configuration
-----------------
local GAME_BONUSES = { DIG_FAST = 1, FOOD = 2, COIN = 3 }
local GAME_DEAD_REASON = { STARVING = 1, DAMAGE = 1, TRAMPLED = 2, FALL_DAMAGE = 3 }
local ROOM_DIMENSIONS = Number3(140, 65, 48)
local COLLISION_GROUP_PLAYER = CollisionGroups(1)
local COLLISION_GROUP_FLOOR_BELOW = CollisionGroups(2)
local COLLISION_GROUP_WALL = CollisionGroups(3)
local COLLISION_GROUP_BONUS = CollisionGroups(4)
local COLLISION_GROUP_ENNEMY = CollisionGroups(5)
local COLLISION_GROUP_PARTICLES = CollisionGroups(6)
local COLLISION_GROUP_PROPS = CollisionGroups(7)

local spawners = {}
local upgrades = {}
local gameManager = {}
local levelManager = {}
local playerManager = {}
local uiManager = {}

local gameConfig = {
    gravity = Number3(0, -850, 0),
    floorInMemoryMax = 8,
    moneyProbability = 0.35,
    bonusProbability = 0.05,
    bonusesRotationSpeed = 1.5 * math.pi,
    music = nil, -- "https://raw.githubusercontent.com/Donorhan/cubzh-library/main/game-musics/bit-bop.mp3",
    musicVolume = 0.5,
    foodSpawnFloorInterval = Number2(4, 7),
    camera = {
        followSpeed = 0.05,
        playerOffset = Number3(0, 20, -175),
    },
    theme = {
        room = {
            saturation = 18,
            backgroundLightness = 51,
            wallLightness = 36,
            exteriorColor = Color(150, 150, 150),
        },
        ui = {
            backgroundColor = Color(42, 50, 61),
            hungerBar = {
                width = 30,
                height = 250,
                colorHSL = { 131, 56, 46 },
            }
        },
        roomOffsetZ = ROOM_DIMENSIONS.Z * 0.5,
        skybox = "https://i.ibb.co/hgRhk0t/Standard-Cube-Map.png",
    },
    player = {
        defaultLife = 1,
        defaultSpeed = 67,
        defaultJumpHeight = 200,
        defaultDigForce = -15000,
        defaultHungerMax = 15, -- 15 seconds to find food
        foodBonusTimeAdded = 8, -- Time added to the hunger when eating food bonus
        viewRange = 3, -- Amount of rooms to the under the player
        floorImpactSize = Number3(2, 2, 2), -- Block to destroy on player impact
    },
    ennemies = {
        police = {
            speed = 30,
        },
    },
}

-----------------
-- Spawners
-----------------
upgrades = {
    helmet = {
        name = "Helmet",
        index = 4,
        levels = {
            {
                cost = 250,
                effect = function()
                    Player:EquipHat(Items.raph.helmet_test)
                    playerManager._hasHelmet = true
                end
            }
        }
    },
    backpack = {
        name = "Backpack",
        index = 5,
        levels = {
            {
                cost = 250,
                effect = function()
                    Player:EquipBackpack(Items.pratamacam.backpack)
                    playerManager._hasBackpack = true
                end
            }
        }
    },
    moreMoney = {
        name = "Spawn more money",
        index = 1,
        levels = {
            {
                cost = 30,
                effect = function()
                    gameManager._moneyProbability = gameConfig.moneyProbability + 0.1
                end
            },
            {
                cost = 100,
                effect = function()
                    gameManager._moneyProbability = gameConfig.moneyProbability + 0.2
                end
            },
            {
                cost = 200,
                effect = function()
                    gameManager._moneyProbability = gameConfig.moneyProbability + 0.3
                end
            },
            {
                cost = 350,
                effect = function()
                    gameManager._moneyProbability = gameConfig.moneyProbability + 0.4
                end
            }
        }
    },
    moreBonus = {
        name = "Spawn more bonus",
        index = 2,
        levels = {
            {
                cost = 20,
                effect = function()
                    gameManager._bonusProbability = gameConfig.bonusProbability + 0.025
                end
            },
            {
                cost = 100,
                effect = function()
                    gameManager._bonusProbability = gameConfig.bonusProbability + 0.5
                end
            },
            {
                cost = 250,
                effect = function()
                    gameManager._bonusProbability = gameConfig.bonusProbability + 0.75
                end
            },
            {
                cost = 500,
                effect = function()
                    gameManager._bonusProbability = gameConfig.bonusProbability + 0.1
                end
            }
        }
    },
}

-----------------
-- Spawners
-----------------
spawners = {
    coinPool = nil,
    groundParticlePool = nil,
    bonusesRotation = 0,
    lastFoodSpawnedFloorCount = 0,
    init = function ()
        spawners.coinPool = poolSystem.create(35, function() return spawners.createBonus(GAME_BONUSES.COIN) end, true)
        spawners.groundParticlePool = poolSystem.create(30, spawners.createGroundParticle, true)
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
        return oneCube
    end,
    breakPropParticleEffect = function(position)
        local explodeParticles = particles:newEmitter({
            life = function()
                return 0.75
            end,
            velocity = function()
                return Number3(40 * math.random(-1, 1), math.random(100, 250), 20 * math.random(-1, 1))
            end,
            color = function()
                return Color(255, 255, 255)
            end,
            scale = function()
                return 1.3
            end,
            acceleration = function()
                return Config.ConstantAcceleration
            end,
        })
        explodeParticles:SetParent(World)
        explodeParticles.Position = position
        explodeParticles:spawn(30)

        Timer(0.75, false, function()
            explodeParticles:RemoveFromParent()
        end)
    end,
    createBonus = function(bonusType)
        local bonus
        local callback

        if bonusType == GAME_BONUSES.DIG_FAST then
            bonus = Shape(Items.littlecreator.dumbell)
            bonus.LocalRotation.X = 15
            callback = function(_)
                sfx("coin_1", { Position = bonus.Position, Pitch = 1.0 + math.random() * 0.15, Volume = 0.65 })
                playerManager.startDigging(5)
            end
        elseif bonusType == GAME_BONUSES.FOOD then
            bonus = Shape(Items.chocomatte.ramen)
            bonus.LocalRotation.X = 0.45
            bonus.LocalScale = Number3(0.6, 0.6, 0.6)
            callback = function(_)
                sfx("eating_4", { Position = bonus.Position, Pitch = 1.0 + math.random() * 0.15, Volume = 0.65 })
                playerManager._hunger = math.max(0, playerManager._hunger - gameConfig.player.foodBonusTimeAdded)
            end
        elseif bonusType == GAME_BONUSES.COIN then
            bonus = Shape(Items.vico.coin)
            callback = function(coin)
                sfx("coin_1", { Position = bonus.Position, Pitch = 1.0 + math.random() * 0.15, Volume = 0.65 })
                gameManager._money = gameManager._money + 1
                spawners.coinPool:release(coin)
            end
        end

        bonus.type = bonusType
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
    spawnCoins = function(room)
        local position = spawners.randomPositionInRoom(40, 0)
        local startX = position.X
        local startY = 40
        local spacing = 8

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
                    coin.LocalRotation.Y = 0
                    table.insert(room.bonuses, coin)
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
                    table.insert(room.bonuses, coin)
                end
            end
        end
    end,
    spawnEnnemy = function(room, position)
        local ennemy = Shape(Items.chocomatte.police_martin)
        ennemy:SetParent(room.propsContainer)
        ennemy.Physics = PhysicsMode.Dynamic
        ennemy.CollisionGroups = COLLISION_GROUP_ENNEMY
        ennemy.CollidesWithGroups = COLLISION_GROUP_WALL + COLLISION_GROUP_FLOOR_BELOW + COLLISION_GROUP_PROPS
        ennemy.Scale = Number3(0.5, 0.5, 0.5)
        ennemy.Pivot = Number3(ennemy.Width * 0.5, 0, ennemy.Depth * 0.5)
        ennemy.lifeTime = 0

        ennemy.LocalPosition = Number3(position.X, position.Y, 0)
        ennemy.setDirectionLeft = function(value)
            if value then
                ennemy.Motion:Set(-gameConfig.ennemies.police.speed, 0, 0)
                ease:linear(ennemy.Rotation, 0.2).Y = math.rad(-90 + 360)
            else
                ennemy.Motion:Set(gameConfig.ennemies.police.speed, 0, 0)
                ease:linear(ennemy.Rotation, 0.2).Y = math.rad(90)
            end
        end

        local dieParticles = particles:newEmitter({
            life = function()
                return 2.0
            end,
            velocity = function()
                local v = Number3(20 + math.random() * 20, 0, 0)
                v:Rotate(0, math.random() * math.pi * 2, 0)
                v.Y = 30 + math.random() * 100
                return v
            end,
            color = function()
                return Color.Red
            end,
            scale = function()
                return 0.5 + math.random() * 2.0
            end,
            collidesWithGroups = function()
                return {}
            end,
        })

        ennemy.setDirectionLeft(math.random(1, 2) == 1)
        ennemy.spawnRoom = room
        ennemy.kill = function(reason)
            ennemy.Physics = PhysicsMode.Disabled

            if reason == GAME_DEAD_REASON.TRAMPLED then
                sfx("eating_1",
                    { Position = ennemy.Position, Pitch = 1.0 + math.random() * 0.15, Volume = 0.65 })

                dieParticles.Position = ennemy.Position
                dieParticles:spawn(15)

                ennemy.IsHidden = true
                ennemy:RemoveFromParent()
                gameManager._cameraContainer.shake(10)
            elseif reason == GAME_DEAD_REASON.FALL_DAMAGE then
                sfx("hurt_scream_male_" .. math.random(1, 5),
                    { Position = ennemy.Position, Pitch = 0.5 + math.random() * 0.15, Volume = 0.65 })

                local ennemyCopy = ennemy:Copy()
                ennemyCopy:SetParent(World)
                ennemyCopy.Position = ennemy.Position
                explode(ennemyCopy)

                ennemy.IsHidden = true
                gameManager._cameraContainer.shake(1)

                Timer(2.0, false, function()
                    ennemy:RemoveFromParent()
                    ennemyCopy:RemoveFromParent()
                end)
            end
        end

        ennemy.OnCollisionBegin = function(self, collider, normal)
            if collider.CollisionGroups == COLLISION_GROUP_WALL or collider.CollisionGroups == COLLISION_GROUP_PROPS then
                if math.abs(normal.X) > 0.5 then
                    ennemy.setDirectionLeft(self.Position.X > 0)
                end
            elseif collider.CollisionGroups == COLLISION_GROUP_FLOOR_BELOW then
                if self.lifeTime > 1.0 then
                    if normal.Y >= 1.0 then
                        if collider:GetParent() ~= self.spawnRoom then
                        self.kill(GAME_DEAD_REASON.FALL_DAMAGE)
                        end
                    end
                end
            end
        end

        ennemy.Tick = function(self, dt)
            self.lifeTime = self.lifeTime + dt
        end

        return ennemy
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
    _bonusProbability = gameConfig.bonusProbability,
    _money = 0,
    _moneyProbability = gameConfig.moneyProbability,
    _playing = false,
    _music = nil,

    init = function()
        ambience:set(ambience.noon)
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
    end,
    initCamera = function()
        local cameraContainer = Object()
        cameraContainer.decay = 1.1
        cameraContainer.shakeMaxAmplitude = Number2(1.5, 4)
        cameraContainer.traumaPower = 2.0
        cameraContainer.trauma = 0
        cameraContainer:SetParent(World)

        cameraContainer.targetFollower = Object()
        cameraContainer.targetFollower:SetParent(cameraContainer)
        Camera:SetParent(World)
        Camera:SetModeFree()
        Camera.Rotation:Set(0, 0, 0)

        cameraContainer.Tick = function(_, dt)
            local playerPositionY = Player.Position.Y + gameConfig.camera.playerOffset.Y
            if playerPositionY < cameraContainer.targetFollower.LocalPosition.Y then
                cameraContainer.targetFollower.LocalPosition.Y = playerPositionY
            end

            cameraContainer.Position.X = 0
            cameraContainer.Position.Y = 0
            if cameraContainer.trauma ~= 0 then
                local shakeAmountX = cameraContainer.shakeMaxAmplitude.X * (cameraContainer.trauma ^ 2)
                local shakeAmountY = cameraContainer.shakeMaxAmplitude.Y * (cameraContainer.trauma ^ 2)
                local shakeX = (math.random() * 2 - 1) * shakeAmountX
                local shakeY = (math.random() * 2 - 1) * shakeAmountY

                cameraContainer.Position.X = cameraContainer.Position.X + shakeX
                cameraContainer.Position.Y = cameraContainer.Position.Y + shakeY
                cameraContainer.trauma = math.max(0, cameraContainer.trauma - cameraContainer.decay * dt)
            end

            local lerpedPosition = (cameraContainer.targetFollower.Position.Y - Camera.Position.Y) * gameConfig.camera.followSpeed
            Camera.Position.Y = Camera.Position.Y + lerpedPosition
            Camera.Position.X = cameraContainer.targetFollower.Position.X
        end

        cameraContainer.shake = function(intensity)
            cameraContainer.trauma = math.min(cameraContainer.trauma + intensity, 1.0)
        end

        gameManager._cameraContainer = cameraContainer
    end,
    startGame = function()
        gameManager._cameraContainer.targetFollower.Position = Number3.Zero
        Camera.Position:Set(0, 0, gameConfig.camera.playerOffset.Z)

        levelManager.reset()
        playerManager.reset()

        gameManager._playing = true
        uiManager.showHUD()
    end,
    endGame = function(reason)
        if not gameManager._playing then
            return
        end

        playerManager.onKilled(reason)
        gameManager._playing = false

        Timer(0.75, false, function()
            uiManager.showGameOverScreen()
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

    init = function()
        levelManager._floors = fifo()

        skybox.load({ url = gameConfig.theme.skybox }, function(obj)
            obj:SetParent(Camera)
            obj.Tick = function(self)
                self.Position = Camera.Position - Number3(self.Scale.X, self.Scale.Y, -self.Scale.Z) / 2
            end
        end)
    end,
    reset = function()
        levelManager.removeFloors(#levelManager._floors)
        levelManager._floors:flush()
        levelManager._lastFloorSpawned = 0
        levelManager._totalFloorSpawned = 0
        spawners.groundParticlePool:releaseAll()
        spawners.coinPool:releaseAll()
        levelManager.spawnFloors(gameConfig.player.viewRange)
    end,
    generateRoom = function (groundOnly)
        local room = Object()

        math.randomseed(math.random(0, 360))
        local hue = math.random(0, 360)
        local saturation = gameConfig.theme.room.saturation

        local backgroundColor = helpers.colors.HSLToRGB(hue, saturation, gameConfig.theme.room.backgroundLightness)
        local wallColor = helpers.colors.HSLToRGB(hue, saturation, gameConfig.theme.room.wallLightness)
        local bottomColor = Color(170, 170, 170)

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
                ignore = groundOnly,
            },
            right = {
                blocScale = 2,
                color = wallColor,
                thickness = 2,
                ignore = groundOnly,
            },
            front = {
                ignore = true,
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
                ignore = groundOnly,
            },
        }

        local roomStructure = roomModule.create(roomConfig)
        roomStructure.root:SetParent(room)
        roomStructure.root.Scale = Number3(4, 4, 4)
        roomStructure.walls[Face.Bottom].CollisionGroups = COLLISION_GROUP_FLOOR_BELOW
        roomStructure.walls[Face.Bottom].CollidesWithGroups = COLLISION_GROUP_PLAYER

        if roomStructure.walls[Face.Back] then
            roomStructure.walls[Face.Back].Physics = PhysicsMode.Disabled
        end

        if bottomColor then
            roomStructure.walls[Face.Bottom].paintShape.CollisionGroups = COLLISION_GROUP_NONE
            roomStructure.walls[Face.Bottom].paintShape.CollidesWithGroups = COLLISION_GROUP_NONE
            roomStructure.walls[Face.Bottom].paintShape.Physics = false
        end

        local roomProps = Object()
        roomProps:SetParent(room)
        roomProps.LocalPosition = Number3(0, (roomConfig.bottom.thickness * roomStructure.root.Scale.Y), 0)

        -- windows
        local windowChoice = math.random(1, 10)
        if windowChoice == 1 then
            roomStructure:createHoleFromBlockCoordinates(Face.Back, Number3(7, 7, 1), Number3( 5, 4, 2))
        elseif windowChoice == 2 then
            roomStructure:createHoleFromBlockCoordinates(Face.Back, Number3(7, 7, 1), Number3( 5, 4, 2))
        elseif windowChoice == 3 then
            roomStructure:createHoleFromBlockCoordinates(Face.Right, Number3(0, 6, 1), Number3( 2, 3, 1))
        end

        levelManager.addProps(roomProps, groundOnly)

        room.structure = roomStructure
        room.propsContainer = roomProps

        return room
    end,
    destroyGround = function(floorCollider)
        local ray = Ray(Player.Position, Number3(0, -1, 0))
        local impact = ray:Cast(floorCollider, nil, true)
        if impact == nil or impact.Block == nil then
            return
        end

        gameManager._cameraContainer.shake(5)
        sfx("wood_impact_3", { Position = floorCollider.Position, Pitch = 0.5 + math.random() * 0.2, Volume = 0.65 })
        Client:HapticFeedback()
        for _ = 0, 10 do
        local particle = spawners.spawnGroundParticle(impact.Block.Position, impact.Block.Color)
            particle:SetParent(World)
        end

        floorCollider.Physics = PhysicsMode.StaticPerBlock
        local impactPosition = impact.Block.Coordinates
        floorCollider.room:createHoleFromBlockCoordinates(Face.Bottom, impactPosition, gameConfig.player.floorImpactSize)
    end,
    damageProp = function(prop, _)
        prop.life = prop.life - 1
        if prop.life > 0 then
            local soundDamage = prop.soundDamage or "punch_1"
            sfx(soundDamage, { Position = prop.Position, Pitch = 0.8 + math.random() * 0.1, Volume = 0.55 })
            helpers.shape.flash(prop, Color.White, 0.25)
        else
            local destroySound = prop.destroySound or "gun_shot_2"
            sfx(destroySound, { Position = prop.Position, Pitch = 1.0 + math.random() * 0.1, Volume = 0.55 })
            spawners.breakPropParticleEffect(prop.Position)
            prop:RemoveFromParent()
        end
    end,
    addProps = function (floor, groundOnly)
        math.randomseed(os.time() + math.random(0, 360))
        local randomConfig = math.random(1, 5)

        local prepareProp = function(prop, position, soundDamage, destroySound)
            prop.life = 1
            prop:SetParent(floor)
            prop.CollisionGroups = COLLISION_GROUP_PROPS
            prop.CollidesWithGroups = COLLISION_GROUP_PLAYER
            prop.soundDamage = soundDamage
            prop.destroySound = destroySound
        end

        if groundOnly then
            local prop = Shape(Items.uevoxel.antena02)
            prepareProp(prop)
            prop.Physics = PhysicsMode.Disabled
            prop.Scale = Number3(0.6, 0.6, 0.6)
            prop.LocalRotation.Y = 9
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - 13, prop.Height * 0.5 - 3, -15)

            prop = Shape(Items.kooow.solarpanel)
            prepareProp(prop)
            prop.Physics = PhysicsMode.Disabled
            prop.Scale = Number3(0.5, 0.5, 0.5)
            prop.LocalRotation.Y = 0
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 13, prop.Height * 0.5 - 8, -15)

            return
        end

        if randomConfig == 1 then
            local prop = Shape(Items.claire.desk7)
            prepareProp(prop)
            prop.Physics = PhysicsMode.Disabled
            prop.Scale = Number3(0.6, 0.6, 0.6)
            prop.LocalRotation.Y = 90
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 20, prop.Height * 0.5 - 5, ROOM_DIMENSIONS.Z * 0.5 - 10)

            prop = Shape(Items.claire.sofa2)
            prepareProp(prop)
            prop.Physics = PhysicsMode.Disabled
            prop.LocalRotation.Y = math.pi
            prop.LocalPosition = Number3(0, prop.Height * 0.5, ROOM_DIMENSIONS.Z * 0.5 - 10)

            prop = Shape(Items.piaa.book_shelf)
            prepareProp(prop)
            prop.Physics = PhysicsMode.Disabled
            prop.Scale = Number3(0.5, 0.5, 0.5)
            prop.Pivot = Number3(0, prop.Height * 0.5, 0)
            prop.LocalRotation.Y = 0
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - 33, prop.Height * 0.5 - 12, ROOM_DIMENSIONS.Z * 0.5 - 10)

            prop = Shape(Items.claire.office_cabinet)
            prepareProp(prop, Number3.Zero, "hitmarker_2", "gun_shot_2")
            prop.Scale = Number3(0.6, 0.6, 0.6)
            prop.LocalRotation.Y = 0
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - prop.Width * 0.5 - 4, prop.Height * 0.5 - 5, 0)
            prop.Physics = PhysicsMode.Static
            prop.life = 2

            prop = Shape(Items.boumety.shelf3)
            prepareProp(prop)
            prop.Physics = PhysicsMode.Disabled
            prop.Scale = Number3(0.5, 0.5, 0.5)
            prop.LocalRotation.Y = 0
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 20, ROOM_DIMENSIONS.Y * 0.5 - 5, ROOM_DIMENSIONS.Z * 0.5 - prop.Depth)
        elseif randomConfig == 2 then
            local prop = Shape(Items.claire.desk7)
            prepareProp(prop)
            prop.Physics = PhysicsMode.Disabled
            prop.Scale = Number3(0.6, 0.6, 0.6)
            prop.LocalRotation.Y = -90
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - 20, prop.Height * 0.5 - 5, ROOM_DIMENSIONS.Z * 0.5 - 15)

            prop = Shape(Items.claire.sofa2)
            prepareProp(prop)
            prop.Physics = PhysicsMode.Disabled
            prop.LocalRotation.Y = math.pi / 2
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 11, prop.Height * 0.5, ROOM_DIMENSIONS.Z * 0.5 - 20)

            prop = Shape(Items.claire.office_door)
            prepareProp(prop)
            prop.Physics = PhysicsMode.Disabled
            prop.LocalRotation.Y = 0
            prop.Pivot = Number3(prop.Width * 0.5, 0, prop.Depth * 0.5)
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 30, 0, ROOM_DIMENSIONS.Z * 0.5 - 5)
            prop.Scale = Number3(1.7, 1.7, 1.7)

            prop = Shape(Items.pratamacam.vending_machine)
            prepareProp(prop)
            prop.Physics = PhysicsMode.Disabled
            prop.Pivot = Number3(prop.Width * 0.5, 0, prop.Depth * 0.5)
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - 45, 0, ROOM_DIMENSIONS.Z * 0.5 - 15)
            prop.Scale = Number3(0.7, 0.7, 0.7)
        elseif randomConfig == 3 then
            local prop = Shape(Items.claire.desk7)
            prepareProp(prop)
            prop.Physics = PhysicsMode.Disabled
            prop.Scale = Number3(0.6, 0.6, 0.6)
            prop.LocalRotation.Y = 0
            prop.LocalPosition = Number3(-38, prop.Height * 0.5 - 5, ROOM_DIMENSIONS.Z * 0.5 - 5)

            prop = Shape(Items.claire.desk7)
            prepareProp(prop)
            prop.Physics = PhysicsMode.Disabled
            prop.Scale = Number3(0.6, 0.6, 0.6)
            prop.LocalRotation.Y = 0
            prop.LocalPosition = Number3(-17, prop.Height * 0.5 - 5, ROOM_DIMENSIONS.Z * 0.5 - 5)

            prop = Shape(Items.claire.sofa2)
            prepareProp(prop)
            prop.Physics = PhysicsMode.Disabled
            prop.LocalRotation.Y = math.pi / 2
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 10, prop.Height * 0.5, ROOM_DIMENSIONS.Z * 0.5 - 20)

            prop = Shape(Items.piaa.book_shelf)
            prepareProp(prop)
            prop.Physics = PhysicsMode.Static
            prop.Scale = Number3(0.5, 0.5, 0.5)
            prop.LocalRotation.Y = math.pi / 2
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - 9,  prop.Height * 0.5 - 12, 8)

            prop = Shape(Items.claire.office_door)
            prepareProp(prop)
            prop.Physics = PhysicsMode.Disabled
            prop.LocalRotation.Y = 0
            prop.Pivot = Number3(prop.Width * 0.5, 0, prop.Depth * 0.5)
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - 30, 0, ROOM_DIMENSIONS.Z * 0.5 - 5)
            prop.Scale = Number3(1.7, 1.7, 1.7)
        elseif randomConfig == 4 then
            local prop = Shape(Items.kooow.cardboard_box_long)
            prepareProp(prop)
            prop.Physics = PhysicsMode.Disabled
            prop.Scale = Number3(0.5, 0.5, 0.5)
            prop.LocalRotation.Y = -0.5
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 25, 0, 5)

            prop = prop:Copy()
            prepareProp(prop)
            prop.Physics = PhysicsMode.Disabled
            prop.Scale = Number3(0.5, 0.5, 0.5)
            prop.LocalRotation.Y = -0.95
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 13, 0, -1)

            prop = Shape(Items.kooow.cardboard_box_small)
            prepareProp(prop)
            prop.Physics = PhysicsMode.Disabled
            prop.Scale = Number3(0.5, 0.5, 0.5)
            prop.LocalRotation.Y = -0.5
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 21, 7, 5)
        elseif randomConfig == 5 then
            local prop = Shape(Items.kooow.cardboard_box_long)
            prepareProp(prop)
            prop.Physics = PhysicsMode.Disabled
            prop.Scale = Number3(0.5, 0.5, 0.5)
            prop.LocalRotation.Y = -2
            prop.LocalPosition = Number3(ROOM_DIMENSIONS.X * 0.5 - 35, 0, 4)

            prop = prop:Copy()
            prepareProp(prop)
            prop.Physics = PhysicsMode.Disabled
            prop.Scale = Number3(0.5, 0.5, 0.5)
            prop.LocalRotation.Y = -6
            prop.LocalPosition = Number3(-ROOM_DIMENSIONS.X * 0.5 + 33, 0, 3)
        end
    end,
    addFloorBonuses = function(floor)
        if math.random() < gameManager._moneyProbability then
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


        if spawners.lastFoodSpawnedFloorCount > math.random(gameConfig.foodSpawnFloorInterval.X, gameConfig.foodSpawnFloorInterval.Y) then
            spawners.spawnBonus(floor, GAME_BONUSES.FOOD)
            spawners.lastFoodSpawnedFloorCount = 0
        else
            spawners.lastFoodSpawnedFloorCount = spawners.lastFoodSpawnedFloorCount + 1
        end

        if floorLevel > 5 and math.random() < gameManager._bonusProbability then
            local bonusType = math.random(GAME_BONUSES.DIG_FAST, GAME_BONUSES.DIG_FAST)
            spawners.spawnBonus(floor, bonusType)
        end
    end,
    spawnFloors = function(floorCount)
        local startFloor = levelManager._lastFloorSpawned - 1
        for floorLevel = 0, floorCount - 1 do
            local currentFloor = startFloor - floorLevel
            local isFirstFloor = currentFloor == -1
            local floor = levelManager.generateRoom(isFirstFloor)
            floor:SetParent(World)
            floor.bonuses = {}

            floor.Position.Y = currentFloor * ROOM_DIMENSIONS.Y

            if not isFirstFloor then
                levelManager.addFloorBonuses(floor)

                local colorIntensity = math.max(255 - levelManager._totalFloorSpawned, 0)
                local t = Text()
                t:SetParent(floor)
                t.Text = levelManager._totalFloorSpawned
                t.Type = TextType.World
                t.Anchor = { 1, 0.5 }
                t.IsUnlit = true
                t.Color = Color(255, colorIntensity, colorIntensity)
                t.BackgroundColor = Color(0, 0, 0, 70)
                t.FontSize = 8
                t.LocalPosition = { ROOM_DIMENSIONS.X / 2.0 - 12, ROOM_DIMENSIONS.Y - 12, -ROOM_DIMENSIONS.Z * 0.5 }
            end

            levelManager._floors:push(floor)
            levelManager._totalFloorSpawned = levelManager._totalFloorSpawned + 1
        end
        levelManager._lastFloorSpawned = levelManager._lastFloorSpawned - floorCount

        if #levelManager._floors > gameConfig.floorInMemoryMax then
            levelManager.removeFloors(#levelManager._floors - gameConfig.floorInMemoryMax)
        end
    end,
    removeFloor = function(floor)
        for _, bonus in ipairs(floor.bonuses) do
            if bonus.poolIndex and bonus:GetParent() then
                spawners.coinPool:release(bonus)
            end
        end

        floor:RemoveFromParent()
    end,
    removeFloors = function(count)
        for _ = 0, count do
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

        local playerCurrentFloor = math.floor(Player.Position.Y / ROOM_DIMENSIONS.Y)
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
    _lastFloorReached = 0,
    _life = 1,
    _jumpHeight = gameConfig.player.defaultJumpHeight,
    _hasHelmet = false,
    _hasBackpack = false,
    _speed = gameConfig.player.defaultSpeed,
    _hunger = 0,
    _hungerMax = gameConfig.player.defaultHungerMax,
    _upgrades = {
        moreMoney = 0,
        moreBonus = 0,
        moreLife = 0,
        helmet = 0,
        backpack = 0,
    },

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
        l.Radius = 35
        l.Hardness = 0.1
        l.Color = Color(0.7, 0.7, 0.7)
        l.On = true
        l.LocalPosition.Z = -10
        l.LocalPosition.Y = 5
        l:SetParent(Player)

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
                return gameConfig.theme.room.exteriorColor
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
        playerManager._lastFloorReached = 0
        playerManager._life = gameConfig.player.defaultLife
        playerManager._hunger = 0
        playerManager._hungerMax = gameConfig.player.defaultHungerMax

        -- Apply upgrades
        for upgradeKey, upgrade in pairs(playerManager._upgrades) do
            if upgrade > 0 then
                upgrades[upgradeKey].levels[upgrade].effect()
            end
        end
    end,
    startDigging = function(diggingForce)
        playerManager._digging = true
        playerManager._diggingForceAccumulator = diggingForce
    end,
    stopDigging = function()
        playerManager._digging = false
        playerManager._diggingForceAccumulator = 0
        if Player.Motion.X == 0 then
            playerManager.reachedFirstFloor()
        end
    end,
    collisionBegin = function(self, collider, normal)
        local inverseDirection = function (direction)
            local newDirection = direction or -Player.Motion.X
            if newDirection < 0 then
                Player.Motion:Set(-playerManager._speed, 0, 0)
                ease:linear(Player.Rotation, 0.2).Y = math.rad(-90 + 360)
            else
                Player.Motion:Set(playerManager._speed, 0, 0)
                ease:linear(Player.Rotation, 0.2).Y = math.rad(90)
            end
        end

        if collider.CollisionGroups == COLLISION_GROUP_WALL then
            sfx("walk_concrete_1", {
                Position = Player.Position,
                Volume = 0.3,
                Pitch = 0.4 + math.random() * 0.2,
                Spatialized = true,
            })
            inverseDirection()
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
            if playerManager._hasHelmet and normal.Y < -0.8 then
                sfx("sword_impact_1", { Position = Player.Position, Pitch = 1.0 + math.random() * 0.1, Volume = 0.65 })
                collider.kill(GAME_DEAD_REASON.FALL_DAMAGE)
                return
            end

            if playerManager._hasBackpack and normal.Y > 0.8 then
                collider.kill(GAME_DEAD_REASON.TRAMPLED)
                return
            end

            playerManager.takeDamage(1, Number2(-self.Motion.X * 20, 200))
        elseif collider.CollisionGroups == COLLISION_GROUP_PROPS then
            if not playerManager._digging then
                inverseDirection()
                return
            end

            gameManager._cameraContainer.shake(2)
            levelManager.damageProp(collider, 1)
            playerManager.stopDigging()
            Player.Velocity.Y = 150
			Client:HapticFeedback()
        end
    end,
    takeDamage = function(damageCount, knockback)
        playerManager._life = playerManager._life - 1
        gameManager._cameraContainer.shake(damageCount * 3)
        Player.Velocity.X = knockback.X
        Player.Velocity.Y = knockback.Y

        if playerManager._life > 0 then
            sfx("hurtscream_1", { Position = Player.Position, Pitch = 1.0 + math.random() * 0.15, Volume = 0.65 })
        end
    end,
    reachedFirstFloor = function()
        Player.Motion:Set(playerManager._speed, 0, 0)
    end,
    onKilled = function(_)
        Player.IsHidden = true
        Player.Motion:Set(0, 0, 0)
        Player.Physics = PhysicsMode.Disabled
        explode(Player.Body)
        sfx("deathscream_3", { Position = Player.Position, Pitch = 1.0 + math.random() * 0.15, Volume = 0.65 })
    end,
    update = function(dt)
        if not gameManager._playing then
            Player.Velocity = Number3.Zero
            return
        end

        -- Collisions can move player's depth so we must fix it here to avoid weird behaviors
        Player.Position.Z = 0

        if playerManager._lastFloorReached < -1 then
            playerManager._hunger = playerManager._hunger + dt
            if playerManager._hunger >= playerManager._hungerMax then
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
    _moneyCountText = 0,
    _previousMoneyCount = 0,

    init = function()
    end,
    update = function(self, _)
        if uiManager._moneyCountText and gameManager._money ~= uiManager._previousMoneyCount then
            uiManager._moneyCountText.Text = gameManager._money
            uiManager._previousMoneyCount = gameManager._money
            uiManager._moneyCountText.animate()

        end

        if uiManager._HUDScreen then
            if uiManager._hungerBar then
                local hungerRatio = math.min(1, math.max(0, 1 - (playerManager._hunger / playerManager._hungerMax)))
                local maxHeight = gameConfig.theme.ui.hungerBar.height - 8
                uiManager._hungerBar.Height = maxHeight * hungerRatio

                local startHue = gameConfig.theme.ui.hungerBar.colorHSL[1]
                local endHue = 0
                local lerpedHue = startHue * hungerRatio + endHue * (1 - hungerRatio)
                local color = helpers.colors.HSLToRGB(
                    lerpedHue,
                    gameConfig.theme.ui.hungerBar.colorHSL[2],
                    gameConfig.theme.ui.hungerBar.colorHSL[3]
                )
                uiManager._hungerBar.Color = color
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
    createMoneyComponent = function (componentWidth)
        local uiPadding = uitheme.current.padding * 2

        local moneyBloc = ui:createFrame(Color(0, 0, 0, 0))

        local money = ui:createShape(bundle:Shape("shapes/pezh_coin_2"), { spherized = false, doNotFlip = true })
        money.Width = uiManager.ICONS_SIZE
        money.Height = uiManager.ICONS_SIZE
        money:setParent(moneyBloc)

        local moneyText = ui:createText("0", Color(255, 255, 255, 255), "default")
        moneyText:setParent(moneyBloc)
		moneyText.object.Anchor = { 1, 0 }
		moneyText.LocalPosition = Number3(componentWidth - uiPadding * 2, 0, 0)
        moneyText.animation = nil
        uiManager._moneyCountText = moneyText


        moneyText.animate = function()
			ease:cancel(moneyText.animation)
            moneyText.animation = ease:outSine(moneyText.object, 0.15, {
                onDone = function()
                    moneyText.object.Scale = Number3.One
                end,
            })
            moneyText.animation.Scale = Number3(1.4, 1.4, 1)
        end

        return moneyBloc
    end,
    createUpgradeComponents = function(selectedUpgrades, frame)
        local function createCoinIcon(parent)
            local coin = ui:createShape(bundle:Shape("shapes/pezh_coin_2"), { spherized = false, doNotFlip = true })
            coin.Width = 20
            coin.Height = 20
            coin:setParent(parent)
            return coin
        end

        local upgradeFrames = {}
        local refreshUpgrades = nil
        refreshUpgrades = function()
            for _, frame in ipairs(upgradeFrames) do
                frame:remove()
            end
            upgradeFrames = {}

            table.sort(selectedUpgrades, function(a, b)
                return upgrades[a].index > upgrades[b].index
            end)

            for i, upgradeKey in ipairs(selectedUpgrades) do
                local upgrade = upgrades[upgradeKey]
                local currentLevel = playerManager._upgrades[upgradeKey] + 1
                local nextLevel = upgrade.levels[currentLevel]

                local upgradeFrame = ui:createFrame(Color(60, 70, 80))
                upgradeFrame.Width = frame.Width
                upgradeFrame.Height = 65
                upgradeFrame:setParent(frame)
                upgradeFrame.LocalPosition = { 0, 10 + (i - 1) * 75 }
                table.insert(upgradeFrames, upgradeFrame)

                local titleText = ui:createText(upgrade.name, Color.White, "default")
                titleText:setParent(upgradeFrame)
                titleText.LocalPosition = { 10, 30 }
                titleText.FontSize = 10

                local levelText = ui:createText("Level: " .. currentLevel, Color(150, 150, 255), "small")
                levelText:setParent(upgradeFrame)
                levelText.LocalPosition = { 10, 8 }
                levelText.FontSize = 8

                local buyButton = ui:createFrame(Color(0, 0, 0, 0))
                buyButton.Width = 120
                buyButton.Height = 40
                buyButton:setParent(upgradeFrame)
                buyButton.LocalPosition = { upgradeFrame.Width - buyButton.Width - 10, upgradeFrame.Height / 2 - buyButton.Height / 2 }

                if nextLevel then
                    local coinIcon = createCoinIcon(buyButton)
                    coinIcon.LocalPosition = { 5, buyButton.Height / 2 - coinIcon.Height / 2 }

                    local buttonText = ui:createText(tostring(nextLevel.cost), Color.White, "default")
                    buttonText:setParent(buyButton)
                    buttonText.Anchor = { 1, 0.5 }
                    local textPadding = 10
                    buttonText.LocalPosition = { buyButton.Width - textPadding - buttonText.Width, buyButton.Height / 2 - buttonText.Height / 2 }

                    local canAfford = gameManager._money >= nextLevel.cost
                    local buttonColor = canAfford and Color.Green or Color(100, 100, 100)
                    buyButton.Color = buttonColor

                    buyButton.onRelease = function()
                        if canAfford then
                            gameManager._money = gameManager._money - nextLevel.cost
                            playerManager._upgrades[upgradeKey] = currentLevel
                            sfx("coin_1", { Position = buyButton.Position, Pitch = 0.8, Volume = 0.65 })

                            if refreshUpgrades then
                                refreshUpgrades()
                            end
                        end
                    end
                else
                    levelText.Text = "Max"
                end
            end
        end

        refreshUpgrades()
    end,
    showHUD = function()
        local uiPadding = uitheme.current.padding * 2
        local hudBackgroundColor = gameConfig.theme.ui.backgroundColor:Copy()
        hudBackgroundColor.A = 150

        local frame = ui:createFrame(hudBackgroundColor)
        uiManager._HUDScreen = frame
        frame.Width = 95
        frame.Height = 50
        frame.Position = Number2(Screen.Width - frame.Width - uiPadding, uiPadding)

        local moneyBloc = uiManager.createMoneyComponent(frame.Width)
        moneyBloc:setParent(frame)
        moneyBloc.LocalPosition.X = uiPadding
        moneyBloc.LocalPosition.Y = uiPadding

        -- Hunger bar
        local barPadding = 8
        local hungerBarBackground = ui:createFrame(hudBackgroundColor)
        hungerBarBackground:setParent(frame)
        hungerBarBackground.Width = gameConfig.theme.ui.hungerBar.width
        hungerBarBackground.Height = gameConfig.theme.ui.hungerBar.height
        hungerBarBackground.LocalPosition = Number3(frame.Width - hungerBarBackground.Width * 0.5 - uiPadding, Screen.Height * 0.5 - hungerBarBackground.Height * 0.5, 0)
        uiManager._hungerBarBackground = hungerBarBackground

        local hungerBar = ui:createFrame(gameConfig.theme.ui.hungerBar.highColor)
        hungerBar:setParent(hungerBarBackground)
        hungerBar.Width = gameConfig.theme.ui.hungerBar.width - barPadding
        hungerBar.Height = gameConfig.theme.ui.hungerBar.height - barPadding
        hungerBar.LocalPosition = Number3(barPadding * 0.5, barPadding * 0.5, 0)
        uiManager._hungerBar = hungerBar
    end,
    showGameOverScreen = function()
        if uiManager._gameOverScreen then
            uiManager._gameOverScreen:remove()
            uiManager._gameOverScreen = nil
        end

        local uiPadding = uitheme.current.padding

        local frame = ui:createFrame(gameConfig.theme.ui.backgroundColor)
        uiManager._gameOverScreen = frame

        frame.Width = 400
        frame.Height = 450
        frame.parentDidResize = function()
            frame.LocalPosition = { Screen.Width / 2 - frame.Width / 2, Screen.Height / 2 - frame.Height / 2 -
            Screen.SafeArea.Top }
        end
        frame:parentDidResize()

        -- Upgrade button
        local upgradeButton = ui:createButton("Shop")
        upgradeButton.Width = 75
        upgradeButton:setColor(Color.Green, Color.White)
        upgradeButton:setParent(frame)
        upgradeButton.Anchor = { 0, 0 }
        upgradeButton.parentDidResize = function()
            upgradeButton.LocalPosition = { uiPadding, uiPadding }
        end
        upgradeButton:parentDidResize()
        upgradeButton.onRelease = function()
            if uiManager._gameOverScreen.IsHidden then
                return
            end

            uiManager.showShopScreen()
        end

        -- New game button
        local newGameButton = ui:createButton("Try again")
        newGameButton.Width = 305
        newGameButton:setColor(Color.Blue, Color.White)
        newGameButton:setParent(frame)
        newGameButton.Anchor = { 0.5, 0 }
        newGameButton.parentDidResize = function()
            newGameButton.LocalPosition = { upgradeButton.Width + uiPadding * 2, uiPadding }
        end
        newGameButton:parentDidResize()
        newGameButton.onRelease = function()
            if uiManager._gameOverScreen.IsHidden then
                return
            end

            uiManager.hideAllScreens()
            gameManager.startGame()
        end

        local niceLeaderboard = niceLeaderboardModule({
			extraLine = function(score)
				return string.format("%.2f miles", 5)
			end,
		})
		niceLeaderboard.Width = frame.Width - uiPadding * 2
		niceLeaderboard.Height = 390
        niceLeaderboard:setParent(frame)
        niceLeaderboard.LocalPosition = { frame.Width / 2 - niceLeaderboard.Width / 2, frame.Height - uiPadding - niceLeaderboard.Height }
        niceLeaderboard:show()
    end,
    showShopScreen = function()
        if uiManager._gameOverScreen then
            uiManager._gameOverScreen.IsHidden = true
        end

        local uiPadding = uitheme.current.padding
        local frame = ui:createFrame(gameConfig.theme.ui.backgroundColor)

        frame.Width = 400
        frame.Height = 430
        frame.parentDidResize = function()
            frame.LocalPosition = { Screen.Width / 2 - frame.Width / 2, Screen.Height / 2 - frame.Height / 2 -
            Screen.SafeArea.Top }
        end
        frame:parentDidResize()

        local upgradesFrame = ui:createFrame(Color(0, 0, 0, 0))
		upgradesFrame.Width = frame.Width - uiPadding * 2
		upgradesFrame.Height = 395
        upgradesFrame:setParent(frame)
        upgradesFrame.LocalPosition = { uiPadding, uiPadding + 45 }
        upgradesFrame.LocalPosition.Z = -1

        local availableUpgrades = {}
        for key, _ in pairs(upgrades) do
            table.insert(availableUpgrades, key)
        end
        uiManager.createUpgradeComponents(availableUpgrades, upgradesFrame)

        -- Go back button
        local goBackButton = ui:createButton("Go back")
        goBackButton.Width = frame.Width - uiPadding * 2
        goBackButton:setColor(Color.Blue, Color.White)
        goBackButton:setParent(frame)
        goBackButton.Anchor = { 0.5, 0 }
        goBackButton.parentDidResize = function()
            goBackButton.LocalPosition = { frame.Width / 2 - goBackButton.Width / 2, uiPadding }
        end
        goBackButton:parentDidResize()
        goBackButton.onRelease = function()
            frame:remove()
            uiManager._gameOverScreen.IsHidden = false
        end
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
    elseif not playerManager._digging then
        playerManager.startDigging(1)
    end
end
