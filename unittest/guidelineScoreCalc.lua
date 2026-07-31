local GuidelineScoreCalc = require("guidelineScoreCalc")
local SpinType = require("spin")

local function config(startLevel)
  return {
    lineScore = { 0, 100, 300, 500, 800 },
    linesPerLevel = 10,
    tSpin = { 400, 800, 1200, 1600 },
    tSpinMini = { 100, 200, 400 },
    perfectClear = { 0, 800, 1200, 1800, 2000 },
    b2bPerfectClear = 3200,
    startLevel = startLevel,
  }
end

local function expectInfo(score, wantLevel, wantLines, wantScore)
  local level, lines, points = score.info()
  return level == wantLevel and lines == wantLines and points == wantScore
end

local function backToBackAndCombo()
  local score = GuidelineScoreCalc(config(1))
  score.clear(4, SpinType.NoSpin, false)
  score.clear(0, SpinType.NoSpin, false)
  score.clear(4, SpinType.NoSpin, false)
  score.clear(1, SpinType.NoSpin, false)
  score.clear(4, SpinType.NoSpin, false)
  if not expectInfo(score, 2, 13, 3050) then
    return "back-to-back, combo, or level score was incorrect"
  end
  return 1
end

local function fixedStartingLevelGoal()
  local score = GuidelineScoreCalc(config(5))
  for _ = 1, 12 do
    score.clear(4, SpinType.NoSpin, false)
  end
  local level, lines = score.info()
  if level ~= 5 or lines ~= 48 then
    return "starting at level 5 advanced before 50 cleared lines"
  end

  score.clear(2, SpinType.NoSpin, false)
  level, lines = score.info()
  if level ~= 6 or lines ~= 50 then
    return "starting at level 5 did not advance after 50 cleared lines"
  end
  return 2
end

local function perfectClearScoring()
  local score = GuidelineScoreCalc(config(1))
  score.clear(4, SpinType.NoSpin, true)
  if not expectInfo(score, 1, 4, 2800) then
    return "first Tetris perfect clear score was incorrect"
  end

  score.clear(0, SpinType.NoSpin, false)
  score.clear(4, SpinType.NoSpin, true)
  if not expectInfo(score, 1, 8, 7200) then
    return "back-to-back Tetris perfect clear score was incorrect"
  end
  return 2
end

local function perfectClearLevelMultiplier()
  local score = GuidelineScoreCalc(config(5))
  score.clear(1, SpinType.NoSpin, true)
  if not expectInfo(score, 5, 1, 4500) then
    return "perfect-clear bonus was not multiplied by level"
  end
  return 1
end

return {
  backToBackAndCombo = backToBackAndCombo,
  fixedStartingLevelGoal = fixedStartingLevelGoal,
  perfectClearLevelMultiplier = perfectClearLevelMultiplier,
  perfectClearScoring = perfectClearScoring,
}
