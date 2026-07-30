local _ = require("lodash")
local tetromino = require("tetromino")

local function initer(shape)
  local col = tetromino.representStr(shape) == "I" and 7 or 6
  return 21, col, 1
end

local s = tetromino.representStr(0)
local mrandom = math.random

local function bagGen()
  local res = { s:byte(0, -1) }
  for i = 1, #s do
    res[i] = i
  end

  for i = #res, 2, -1 do
    local j = mrandom(i)
    if j < i then
      res[j], res[i] = res[i], res[j]
    end
  end
  return res
end

local levelToDropCountdown = {
  60,
  47,
  37,
  28,
  21,
  16,
  11,
  8,
  6,
  4,
  3,
  2,
  -1,
  -1,
  -2,
  -4,
  -7,
  -11,
  -20,
}

local function guideline(level)
  if level > #levelToDropCountdown then level = 19 end
  return levelToDropCountdown[level]
end

--[[ a GameConfig object contains these fields: <br>
  generator: function to produce tetromino queue table <br>
  initer: function to get init row, col, dir for a shape <br>
  seenPreview: integer <br>

  countDAS: positive integer <br>
  countARR: positive integer <br>
  countClear: positive integer <br>
  countLock: positive integer <br>
  countLockDelay: positive integer <br>
  countPause: positive integer

  lineScore: a 5-elements array <br>
  linesPerLevel: an integer >= 4, how many lines increases one level <br>
  tSpin: a 4-elements array. tSpin[i+1] means score base for i-cleared <br>
  tSpinMini: a 3-elements array. tSpin[i+1] means score base for i-cleared <br>
  levelToDropCountdown: a function from level to drop countdown
]]
return {
  generator = bagGen,
  initer = initer,
  levelToDropCountdown = guideline,
  rowNumber = 40, -- need to sync with images rowNumber
  colNumber = 10, -- need to sync with images colNumber
  seenPreview = 3,

  countDAS = 9,
  countARR = 3,
  countClear = 15,
  countLock = 10,
  countLockDelay = 30,
  countPause = 180,
  limitLockDelay = 20,

  lineScore = { 0, 100, 300, 500, 800 },
  linesPerLevel = 10,
  tSpin = { 400, 800, 1200, 1600 },
  tSpinMini = { 100, 200, 400 },
  startLevel = 1,
  stopLevel = math.huge,
}
