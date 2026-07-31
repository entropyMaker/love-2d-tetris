local tetromino = require("tetromino")
local SpinType = require("spin")
local _ = require("lodash")

local unpack = unpack or table.unpack
local sort = table.sort

local function dec(t, i)
  local v = t[#t - i]
  i = i + 1
  if v then return i, v end
end

local function checkClear(matrix, rowInd, clearRows)
  local row = matrix[rowInd]
  for i = 1, #row do
    if row[i] == 0 then return clearRows end
  end
  if clearRows == nil then return { rowInd } end

  for i = 1, #clearRows do
    if clearRows[i] == rowInd then return clearRows end
  end
  clearRows[#clearRows + 1] = rowInd
  return clearRows
end

-- generator is a function that create a shape table,
--  which contains at least 7 elements
-- initer is a function that return init row, col, dir for a tetris shape
-- rowNumber and colNumber is integer for the matrix's row number and col number
return function(generator, initer, rowNumber, colNumber)
  -- for upcoming tetrominos
  local queue
  -- current tetromino's row
  local row
  -- current tetromino's col
  local col
  -- current tetromino's direction
  local dir
  -- current tetromino's shape
  local shape
  -- game matrix
  local matrix
  -- record the recent SpinType
  local spin = SpinType.NoSpin
  -- if hold is permit
  local holdable = true
  -- shape of holding tetromino
  local holding = 0

  do
    local bag1, bag2 = generator(), generator()
    shape = bag1[1]
    for i = 2, #bag1 do
      bag2[#bag2 + 1] = bag1[i]
    end
    queue = bag2
    row, col, dir = initer(shape)
    matrix = _.fill(_.fill(0, colNumber), rowNumber)
  end

  local function resetSpin() spin = SpinType.NoSpin end

  local function conflict()
    return tetromino.conflict(matrix, tetromino.getPos(row, col, dir, shape))
  end

  local function newTetromino(holdFirst)
    if holdFirst then
      shape, holding = holding, shape
    else
      shape = 0
    end

    if shape == 0 then
      local i = #queue
      shape = queue[i]
      queue[i] = nil
      if i <= 7 then
        local newqueue = generator()
        local k = #newqueue
        for j = 1, i - 1 do
          newqueue[k + j] = queue[j]
        end
        queue = newqueue
      end
    end

    row, col, dir = initer(shape)
    if conflict() then return false end

    holdable = not holdFirst
    resetSpin()
    return true
  end

  -- returns gameOver: bool, down: int, clearRows: table, perfectClear: bool
  -- this function also update GameState's matrix and tetromino
  local function lock()
    local ghostRow = tetromino.ghost(matrix, row, col, dir, shape)
    local bound = #matrix / 2
    local r1, c1, r2, c2, r3, c3, r4, c4 =
      tetromino.getPos(ghostRow, col, dir, shape)
    if r1 > bound and r2 > bound and r3 > bound and r4 > bound then
      return true, 0, _.E, false
    end

    if row ~= ghostRow then resetSpin() end
    local distance = row - ghostRow
    row = ghostRow

    matrix = tetromino.lock(matrix, r1, c1, r2, c2, r3, c3, r4, c4, shape)

    local clearRows = checkClear(matrix, r1)
    clearRows = checkClear(matrix, r2, clearRows)
    clearRows = checkClear(matrix, r3, clearRows)
    clearRows = checkClear(matrix, r4, clearRows)
    if clearRows then sort(clearRows) end

    local perfectClear = clearRows ~= nil
    if perfectClear then
      local cleared = {}
      for i = 1, #clearRows do
        cleared[clearRows[i]] = true
      end
      for i = 1, #matrix do
        if not cleared[i] then
          for j = 1, #matrix[i] do
            if matrix[i][j] ~= 0 then
              perfectClear = false
              break
            end
          end
        end
        if not perfectClear then break end
      end
    end

    return false, distance, clearRows or _.E, perfectClear
  end

  -- returns false if game is over, true otherwise
  -- it update matrix and reset a new tetromino if game is not over
  -- rows should be return value of previous call of `lock`
  local function clear(rows)
    if not rows or #rows == 0 then return newTetromino(false) end

    local newMatrix = { unpack(matrix) }
    local offset = 2

    for i = rows[1] + 1, #newMatrix do
      if i == rows[offset] then
        offset = offset + 1
      else
        local target = i - offset + 1
        if newMatrix[target] == newMatrix[i] then break end
        newMatrix[target] = newMatrix[i]
      end
    end

    matrix = newMatrix
    return newTetromino(false)
  end

  -- clockwise: bool
  -- returns true if rotated, false otherwise
  local function rotate(clockwise)
    local spinNew, rowNew, colNew, dirNew =
      tetromino.rotate(matrix, clockwise, row, col, dir, shape)
    if spinNew == SpinType.NoSpin then return false end

    row, col, dir, spin = rowNew, colNew, dirNew, spinNew
    return true
  end

  -- toLeft: bool
  -- returns true if moved, false otherwise
  local function horizMove(toLeft)
    local originalCol = col
    col = col + (toLeft and -1 or 1)
    if conflict() then
      col = originalCol
      return false
    else
      resetSpin()
      return true
    end
  end

  -- distance: positive integer to move down,
  -- returns actually moved distance
  local function downMove(distance)
    if distance <= 0 then return 0 end

    distance = row - tetromino.down(matrix, distance, row, col, dir, shape)
    if distance > 0 then resetSpin() end
    row = row - distance
    return distance
  end

  -- return iterator to see upcoming tetromino preview,
  -- it ensured at least 7 elements are available.
  -- use it like this for index, element in state.preview() do end
  local function preview() return dec, queue, 0 end

  -- returns true if user is permitted to hold current tetromino
  local function isHoldable() return holdable end

  -- when a tetromino is locked, use to check if last operation is t spin
  local function recentSpin() return spin end

  -- returns the ghost tetromino is how many rows down to current tetromino
  local function ghostDown()
    return row - tetromino.ghost(matrix, row, col, dir, shape)
  end

  -- hold current tetromino, must be called when isHoldable returns true,
  -- returns false if game is over after holding, true otherwise
  local function hold()
    assert(isHoldable(), "hold() must be called when isHoldable() returns true")
    return newTetromino(true)
  end

  -- returns row, col, dir, shape of current tetromino
  local function t() return row, col, dir, shape end

  -- returns tetris matrix
  local function m() return matrix end

  -- returns holding tetromino shape, or 0 if not holding any
  local function h() return holding end

  return {
    -- state viewing methods
    preview = preview,
    isHoldable = isHoldable,
    ghostDown = ghostDown,
    recentSpin = recentSpin,
    tetromino = t,
    matrix = m,
    holding = h,

    -- manipulating methods
    lock = lock,
    clear = clear,
    rotate = rotate,
    horizMove = horizMove,
    downMove = downMove,
    hold = hold,
  }
end
