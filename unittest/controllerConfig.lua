local config = require("controllerConfig")

local function close(a, b, tolerance)
  return math.abs(a - b) < (tolerance or 0.000001)
end

local function gravityCurve()
  if not close(config.levelToGravity(1), 1 / 60) then
    return "level 1 gravity was not one cell per 60 updates"
  end
  if not close(config.levelToGravity(12), 0.59, 0.001) then
    return "level 12 gravity did not follow the Guideline formula"
  end
  if config.levelToGravity(19) ~= 20 or config.levelToGravity(100) ~= 20 then
    return "gravity was not capped at 20G"
  end
  return 4
end

return {
  gravityCurve = gravityCurve,
}
