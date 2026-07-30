_G.unpack = unpack or table.unpack

-- $ lua main.lua unittest
if select(1, ...) == "unittest" then
  return require("unittest.main")()
elseif select(1, ...) == "benchtest" then
  return require("benchtest")
end

local love = require("love")
local GameController = require("gameController")
local images = require("images")
local Draw = require("batchDraws")
local controllerConfig = require("controllerConfig")
require("loggc")

local draw, controller, invalid, keyboardMap, gamepadMap

function love.load(args)
  math.randomseed(os.time())
  local startLevel = tonumber(args[1])
  if type(startLevel) == "number" then
    controllerConfig.startLevel = startLevel
  end

  local stopLevel = tonumber(args[2])
  if type(stopLevel) == "number" then controllerConfig.stopLevel = stopLevel end

  draw = Draw(images, love.graphics)
  local scorer = require("guidelineScoreCalc")(controllerConfig)
  controller = GameController(controllerConfig, scorer)

  local Input = controller.Input
  invalid = Input.Invalid
  keyboardMap = {
    left = Input.Left,
    right = Input.Right,
    up = Input.ClockwiseRotate,
    down = Input.SoftDrop,
    space = Input.HardDrop,
    c = Input.Hold,
    z = Input.AntiClockwiseRotate,
    escape = Input.Pause,
  }

  gamepadMap = {
    dpleft = Input.Left,
    dpright = Input.Right,
    dpup = Input.HardDrop,
    dpdown = Input.SoftDrop,
    a = Input.AntiClockwiseRotate,
    b = Input.ClockwiseRotate,
    leftshoulder = Input.Hold,
    rightshoulder = Input.Hold,
    start = Input.Pause,
  }
end

function love.keypressed(key) controller.keypressed(keyboardMap[key] or invalid) end

function love.keyreleased(key)
  controller.keyreleased(keyboardMap[key] or invalid)
end

function love.gamepadpressed(stick, button)
  if button == "back" then love.event.quit("restart") end
  controller.keypressed(gamepadMap[button] or invalid)
end

function love.gamepadreleased(stick, button)
  controller.keyreleased(gamepadMap[button] or invalid)
end

function love.update(dt) controller.update() end

function love.draw() controller.draw(draw) end
