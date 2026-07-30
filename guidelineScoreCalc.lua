local SpinType = require("spin")

local DropType = {
  Normal = 0,
  SoftDrop = 1,
  HardDrop = 2,
}

return function(config)
  local level = config.startLevel
  local lines = 0
  local score = 0
  local inB2B = false
  local combo = 0

  local function clear(lineCount, spin, perfectClear)
    local scoreArr
    if spin == SpinType.TSpin then
      scoreArr = config.tSpin
    elseif spin == SpinType.TSpinMini then
      scoreArr = config.tSpinMini
    else
      scoreArr = config.lineScore
    end

    if lineCount == 0 then
      combo = 0
      score = score + scoreArr[1] * level
      return
    end

    local isDifficult = spin == SpinType.TSpin
      or spin == SpinType.TSpinMini
      or lineCount == 4
    local basicScore = scoreArr[lineCount + 1] * level
    local b2bScore = (inB2B and isDifficult) and basicScore / 2 or 0
    local comboScore = combo * 50 * level
    local perfectClearScore = 0
    if perfectClear then
      perfectClearScore = lineCount == 4 and inB2B and config.b2bPerfectClear
        or config.perfectClear[lineCount + 1]
    end
    score = score + basicScore + b2bScore + comboScore + perfectClearScore
    combo = combo + 1
    inB2B = isDifficult

    lines = lines + lineCount
    local linesPerLevel = config.linesPerLevel
    local fixedGoalLevel = math.floor(lines / linesPerLevel) + 1
    if fixedGoalLevel > level then level = fixedGoalLevel end
  end

  local function drop(distance, dropType)
    if distance == 0 or dropType == 0 then return end
    score = score + distance * dropType
  end

  -- return level, lines, score
  local function info() return level, lines, score end

  return {
    drop = drop,
    clear = clear,
    info = info,
    DropType = DropType,
  }
end
