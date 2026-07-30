local GameState = require("gameState")

local function generator() return { 1, 2, 3, 4, 5, 6, 7 } end

local function initer() return 2, 4, 1 end

local function perfectClear()
  local state = GameState(generator, initer, 40, 10)
  local matrix = state.matrix()
  matrix[1] = { 0, 0, 0, 0, 1, 1, 1, 1, 1, 1 }

  local gameOver, distance, rows, isPerfectClear = state.lock()
  if gameOver or distance ~= 0 or #rows ~= 1 or rows[1] ~= 1 then
    return "locking the I piece did not complete the expected line"
  end
  if not isPerfectClear then
    return "empty-board line clear was not recognized"
  end

  if not state.clear(rows) then
    return "failed to spawn after the perfect clear"
  end
  matrix = state.matrix()
  for i = 1, #matrix do
    for j = 1, #matrix[i] do
      if matrix[i][j] ~= 0 then
        return "matrix was not empty after perfect clear"
      end
    end
  end
  return 3
end

local function notPerfectClear()
  local state = GameState(generator, initer, 40, 10)
  local matrix = state.matrix()
  matrix[1] = { 0, 0, 0, 0, 1, 1, 1, 1, 1, 1 }
  matrix[2] = { 1, 0, 0, 0, 0, 0, 0, 0, 0, 0 }

  local _, _, rows, isPerfectClear = state.lock()
  if #rows ~= 1 or isPerfectClear then
    return "line clear with a remaining mino was marked as a perfect clear"
  end
  return 1
end

return {
  notPerfectClear = notPerfectClear,
  perfectClear = perfectClear,
}
