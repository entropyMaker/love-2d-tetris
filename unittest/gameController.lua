local GameController = require("gameController")

local function generator() return { 1, 2, 3, 4, 5, 6, 7 } end

local function scorer()
  local clears = 0
  return {
    clear = function() clears = clears + 1 end,
    clearCount = function() return clears end,
    drop = function() end,
    info = function() return 1, 0, 0 end,
    DropType = { Normal = 0, SoftDrop = 1, HardDrop = 2 },
  }
end

local function config(initer, gravity)
  return {
    generator = generator,
    initer = initer,
    levelToGravity = function() return gravity end,
    rowNumber = 40,
    colNumber = 10,
    seenPreview = 3,
    countDAS = 9,
    countARR = 3,
    countClear = 1,
    countLock = 1,
    countLockDelay = 30,
    countPause = 180,
    limitLockDelay = 15,
    stopLevel = math.huge,
  }
end

local function drawRow(controller)
  local activeRow
  local noop = function() end
  controller.draw({
    bg = noop,
    bgBlank = noop,
    text = noop,
    tetromino = function(row)
      if row then activeRow = row end
    end,
    ghost = noop,
    hold = noop,
    preview = noop,
    matrix = noop,
    blank = noop,
    zone = noop,
    awardTetris = noop,
    awardTSpin = noop,
    digit = noop,
  })
  return activeRow
end

local function fractionalGravity()
  local score = scorer()
  local controller =
    GameController(config(function() return 10, 4, 1 end, 0.5), score)

  if drawRow(controller) ~= 10 then return "unexpected initial row" end
  controller.update()
  if drawRow(controller) ~= 10 then
    return "fractional gravity moved too early"
  end
  controller.update()
  if drawRow(controller) ~= 9 then
    return "fractional gravity was not accumulated"
  end
  return 3
end

local function highGravitySoftDrop()
  local score = scorer()
  local controller =
    GameController(config(function() return 30, 4, 1 end, 2), score)

  controller.keypressed(controller.Input.SoftDrop)
  controller.update()
  if drawRow(controller) ~= 28 then
    return "soft drop slowed gravity above one cell per update"
  end
  return 1
end

local function lockResetLimit()
  local score = scorer()
  local controller =
    GameController(config(function() return 3, 4, 1 end, 1), score)
  local Input = controller.Input

  controller.update()
  for i = 1, 15 do
    local key = i % 2 == 1 and Input.Right or Input.Left
    controller.keypressed(key)
    controller.keyreleased(key)
  end

  for _ = 1, 20 do
    controller.update()
  end

  controller.keypressed(Input.Left)
  controller.keyreleased(Input.Left)
  for _ = 1, 9 do
    controller.update()
  end
  if score.clearCount() ~= 0 then return "piece locked before delay expired" end

  controller.update()
  if score.clearCount() ~= 1 then
    return "sixteenth movement incorrectly reset the lock delay"
  end
  return 2
end

return {
  fractionalGravity = fractionalGravity,
  highGravitySoftDrop = highGravitySoftDrop,
  lockResetLimit = lockResetLimit,
}
