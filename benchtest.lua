local records = require("benchrecords")
local controller = require("gameController")
local controllerConfig = require("controllerConfig")
local newScorer = require("guidelineScoreCalc")

local unpack = unpack or table.unpack
local clock = os.clock
local sort = table.sort

local FRAME_BUDGET_SECONDS = 0.016
local DEFAULT_REPLAYS = 100

local function noOp() end

local drewGameOver = false

-- Exercise the renderer boundary without drawing or mutating the matrix.
local function consumeMatrix(matrix)
  local checksum = 0
  for row = 1, #matrix do
    local cells = matrix[row]
    for col = 1, #cells do
      checksum = checksum + cells[col] * (row + col)
    end
  end
  return checksum
end

local benchmarkRenderer = {
  bg = function() drewGameOver = false end,
  bgBlank = function() drewGameOver = true end,
  text = noOp,
  digit = noOp,
  tetromino = noOp,
  ghost = noOp,
  blank = noOp,
  zone = noOp,
  awardTetris = noOp,
  awardTSpin = noOp,
  hold = noOp,
  preview = noOp,
  matrix = consumeMatrix,
}

local function config()
  local copy = {}
  for key, value in pairs(controllerConfig) do
    copy[key] = value
  end
  copy.startLevel = 10
  return copy
end

local function newController()
  local gameConfig = config()
  return controller(gameConfig, newScorer(gameConfig))
end

local function replay(game, observeFrame)
  local frames = 0
  local inputEvents = 0
  local pendingInputTime = 0

  for i = 1, #records do
    local action, arg = unpack(records[i])
    if action == "update" then
      for _ = 1, arg do
        local started = clock()
        game.update()
        game.draw(benchmarkRenderer)
        assert(
          not drewGameOver,
          string.format(
            "benchmark recording reached game over at frame %d",
            frames + 1
          )
        )
        observeFrame(pendingInputTime + clock() - started)
        pendingInputTime = 0
        frames = frames + 1
      end
    else
      local started = clock()
      game[action](arg)
      pendingInputTime = pendingInputTime + clock() - started
      inputEvents = inputEvents + 1
    end
  end

  return frames, inputEvents
end

local function percentile(samples, fraction)
  return samples[math.ceil(#samples * fraction)]
end

local function summarize(samples)
  sort(samples)
  local total = 0
  for i = 1, #samples do
    total = total + samples[i]
  end
  return total / #samples, percentile(samples, 0.99), samples[#samples]
end

return function(replays)
  assert(jit, "benchmark must be run with LuaJIT")

  replays = replays or DEFAULT_REPLAYS
  assert(
    replays >= 1 and replays % 1 == 0,
    "benchmark replay count must be a positive integer"
  )

  math.randomseed(1)
  local coldSamples = {}
  replay(
    newController(),
    function(elapsed) coldSamples[#coldSamples + 1] = elapsed end
  )
  local coldAverage, coldP99, coldWorst = summarize(coldSamples)
  collectgarbage("collect")

  local samples = {}
  local totalFrames = 0
  local totalInputEvents = 0
  local benchmarkStarted = clock()
  for _ = 1, replays do
    math.randomseed(1)
    local frames, inputEvents = replay(
      newController(),
      function(elapsed) samples[#samples + 1] = elapsed end
    )
    totalFrames = totalFrames + frames
    totalInputEvents = totalInputEvents + inputEvents
  end
  local benchmarkElapsed = clock() - benchmarkStarted

  local warmAverage, warmP99, warmWorst = summarize(samples)
  local worst = math.max(coldWorst, warmWorst)

  print(jit.version)
  print("timer: os.clock process CPU time")
  print("frame scope: recorded input since prior frame + update + draw")
  print(
    "renderer: headless; read-only full-matrix traversal; no graphics calls"
  )
  print(string.format("cold sample: %d frames (1 replay)", #coldSamples))
  print(
    string.format("warm sample: %d frames (%d replays)", totalFrames, replays)
  )
  print(string.format("warm input events: %d", totalInputEvents))
  print(
    string.format(
      "recorded input rate: %.2f events/s at 60 Hz",
      totalInputEvents / totalFrames * 60
    )
  )
  print(string.format("warm benchmark elapsed: %.3f s", benchmarkElapsed))
  print(
    string.format(
      "cold frames: average %.3f ms, p99 %.3f ms, maximum %.3f ms",
      coldAverage * 1000,
      coldP99 * 1000,
      coldWorst * 1000
    )
  )
  print(
    string.format(
      "warm frames: average %.3f ms, p99 %.3f ms, maximum %.3f ms",
      warmAverage * 1000,
      warmP99 * 1000,
      warmWorst * 1000
    )
  )
  print(
    "note: maxima use different sample counts; the larger warm sample is "
      .. "more likely to contain a rare outlier"
  )
  print(string.format("frame budget: %.3f ms", FRAME_BUDGET_SECONDS * 1000))

  assert(
    worst < FRAME_BUDGET_SECONDS,
    string.format(
      "FAIL: worst frame %.3f ms exceeded the %.3f ms budget",
      worst * 1000,
      FRAME_BUDGET_SECONDS * 1000
    )
  )
  print("PASS: every measured frame completed within the 16 ms budget")
end
