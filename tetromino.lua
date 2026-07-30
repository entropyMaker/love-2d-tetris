local SpinType = require("spin")

local unpack = unpack or table.unpack

local IWallKick = {
  {
    { 0, -2, 0, 1, -1, -2, 2, 1 }, -- dir: 1
    { 0, -1, 0, 2, 2, -1, -1, 2 }, -- dir: 2
    { 0, 2, 0, -1, 1, 2, -2, -1 }, -- dir: 3
    { 0, 1, 0, -2, -2, 1, 1, -2 }, -- dir: 4
  }, -- clockwise
  {
    { 0, -1, 0, 2, 2, -1, -1, 2 },
    { 0, 2, 0, -1, 1, 2, -2, -1 },
    { 0, 1, 0, -2, -2, 1, 1, -2 },
    { 0, -2, 0, 1, -1, -2, 2, 1 },
  }, -- anticlockwise
}

-- wall kick table of T, also used by J, L, S, Z
local TWallKick = {
  {
    { 0, -1, 1, -1, -2, 0, -2, -1 },
    { 0, 1, -1, 1, 2, 0, 2, 1 },
    { 0, 1, 1, 1, -2, 0, -2, 1 },
    { 0, -1, -1, -1, 2, 0, 2, -1 },
  }, -- clockwise
  {
    { 0, 1, 1, 1, -2, 0, -2, 1 },
    { 0, 1, -1, 1, 2, 0, 2, 1 },
    { 0, -1, 1, -1, -2, 0, -2, -1 },
    { 0, -1, -1, -1, 2, 0, 2, -1 },
  }, -- anticlockwise
}

local posOfO = { 0, 0, 0, 1, 1, 1, 1, 0 }

local dirToRelPos = {
  {
    { 1, 0, 1, 1, 1, 2, 1, 3 },
    { 3, 1, 2, 1, 1, 1, 0, 1 },
    { 2, 0, 2, 1, 2, 2, 2, 3 },
    { 0, 2, 1, 2, 2, 2, 3, 2 },
  },
  {
    { 0, 2, 1, 2, 1, 1, 1, 0 },
    { 0, 0, 0, 1, 1, 1, 2, 1 },
    { 2, 0, 1, 0, 1, 1, 1, 2 },
    { 2, 2, 2, 1, 1, 1, 0, 1 },
  },
  {
    { 0, 0, 1, 0, 1, 1, 1, 2 },
    { 2, 0, 2, 1, 1, 1, 0, 1 },
    { 2, 2, 1, 2, 1, 1, 1, 0 },
    { 0, 2, 0, 1, 1, 1, 2, 1 },
  },
  { posOfO, posOfO, posOfO, posOfO },
  {
    { 0, 0, 0, 1, 1, 1, 1, 2 },
    { 2, 0, 1, 0, 1, 1, 0, 1 },
    { 2, 2, 2, 1, 1, 1, 1, 0 },
    { 0, 2, 1, 2, 1, 1, 2, 1 },
  },
  {
    { 0, 1, 1, 2, 1, 1, 1, 0 },
    { 1, 0, 0, 1, 1, 1, 2, 1 },
    { 2, 1, 1, 0, 1, 1, 1, 2 },
    { 1, 2, 2, 1, 1, 1, 0, 1 },
  },
  {
    { 0, 2, 0, 1, 1, 1, 1, 0 },
    { 0, 0, 1, 0, 1, 1, 2, 1 },
    { 2, 0, 2, 1, 1, 1, 1, 2 },
    { 2, 2, 1, 2, 1, 1, 0, 1 },
  },
}

local tSpinPos = { 0, 2, 0, 0, 2, 0, 2, 2 }

local function getPos(row, col, dir, shape)
  local r1, c1, r2, c2, r3, c3, r4, c4 = unpack(dirToRelPos[shape][dir])
  return row - r1,
    col - c1,
    row - r2,
    col - c2,
    row - r3,
    col - c3,
    row - r4,
    col - c4
end

local function occupied(matrix, r, c)
  if c <= 0 or r <= 0 or #matrix < r then return true end

  local row = matrix[r]
  return #row < c or row[c] ~= 0
end

local function conflict(matrix, r1, c1, r2, c2, r3, c3, r4, c4)
  return occupied(matrix, r1, c1)
    or occupied(matrix, r2, c2)
    or occupied(matrix, r3, c3)
    or occupied(matrix, r4, c4)
end

local function matchAny(testRow, testCol, r1, c1, r2, c2, r3, c3, r4, c4)
  return (testRow == r1 and testCol == c1)
    or (testRow == r2 and testCol == c2)
    or (testRow == r3 and testCol == c3)
    or (testRow == r4 and testCol == c4)
end

local function matches(row, col, dir, shape, r1, c1, r2, c2, r3, c3, r4, c4)
  local tr1, tc1, tr2, tc2, tr3, tc3, tr4, tc4 = getPos(row, col, dir, shape)
  return matchAny(tr1, tc1, r1, c1, r2, c2, r3, c3, r4, c4)
    and matchAny(tr2, tc2, r1, c1, r2, c2, r3, c3, r4, c4)
    and matchAny(tr3, tc3, r1, c1, r2, c2, r3, c3, r4, c4)
    and matchAny(tr4, tc4, r1, c1, r2, c2, r3, c3, r4, c4)
end

local function lockOne(matrix, newMatrix, row, col, shape)
  local t = newMatrix[row]
  if t == matrix[row] then
    t = { unpack(t) }
    newMatrix[row] = t
  end
  t[col] = shape
end

local function lock(matrix, r1, c1, r2, c2, r3, c3, r4, c4, shape)
  local newMatrix = { unpack(matrix) }
  lockOne(matrix, newMatrix, r1, c1, shape)
  lockOne(matrix, newMatrix, r2, c2, shape)
  lockOne(matrix, newMatrix, r3, c3, shape)
  lockOne(matrix, newMatrix, r4, c4, shape)
  return newMatrix
end

local function representStr(shape)
  local s = "IJLOSTZ"
  return shape > 0 and s:sub(shape, shape) or s
end

local function checkSpin(row, col, dir, s, matrix)
  if s ~= "T" then return SpinType.NormalSpin end

  local front, back = 0, 0
  local i = dir * 2 - 1
  local p = tSpinPos
  if occupied(matrix, row - p[i], col - p[i + 1]) then front = front + 1 end
  i = i + 2 > #p and 1 or i + 2
  if occupied(matrix, row - p[i], col - p[i + 1]) then front = front + 1 end
  if front == 0 then return SpinType.NormalSpin end

  i = i + 2 > #p and 1 or i + 2
  if occupied(matrix, row - p[i], col - p[i + 1]) then back = back + 1 end
  i = i + 2 > #p and 1 or i + 2
  if occupied(matrix, row - p[i], col - p[i + 1]) then back = back + 1 end

  if front == 2 and back > 0 then return SpinType.TSpin end
  if front > 0 and back == 2 then return SpinType.TSpinMini end
  return SpinType.NormalSpin
end

local function rotate(matrix, clockwise, row, col, dir, shape)
  local newDir = clockwise and (dir < 4 and dir + 1 or 1)
    or (dir > 1 and dir - 1 or 4)
  local r1, c1, r2, c2, r3, c3, r4, c4 = getPos(row, col, newDir, shape)
  local s = representStr(shape)
  if not conflict(matrix, r1, c1, r2, c2, r3, c3, r4, c4) then
    return checkSpin(row, col, newDir, s, matrix), row, col, newDir
  end

  local wk = (s == "I" and IWallKick or TWallKick)[clockwise and 1 or 2][dir]
  for i = 1, #wk, 2 do
    local rowOffset, colOffset = wk[i], wk[i + 1]
    if
      not conflict(
        matrix,
        r1 + rowOffset,
        c1 + colOffset,
        r2 + rowOffset,
        c2 + colOffset,
        r3 + rowOffset,
        c3 + colOffset,
        r4 + rowOffset,
        c4 + colOffset
      )
    then
      row = row + rowOffset
      col = col + colOffset
      return checkSpin(row, col, newDir, s, matrix), row, col, newDir
    end
  end

  -- all wallkick test failed, no spin happend
  return SpinType.NoSpin, row, col, dir
end

-- go down at most `distance`, returns the row after went down
local function down(matrix, distance, row, col, dir, shape)
  local r1, c1, r2, c2, r3, c3, r4, c4 = getPos(row, col, dir, shape)
  local i = 0
  repeat
    i = i + 1
    r1, r2, r3, r4 = r1 - 1, r2 - 1, r3 - 1, r4 - 1
  until i > distance or conflict(matrix, r1, c1, r2, c2, r3, c3, r4, c4)
  return row - i + 1
end

local function ghost(matrix, row, col, dir, shape)
  return down(matrix, row + row, row, col, dir, shape)
end

-- CAUTION: THIS FUNCTION IS NOT EFFICIENT, ONLY FOR TESTING. <br>
local function fromPos(matrix, dir, r1, c1, r2, c2, r3, c3, r4, c4)
  local colCnt = #matrix[1] + 3
  for s = 1, 10 do
    if representStr(s) == "" then break end
    for row = 1, #matrix do
      for col = 1, colCnt do
        if dir then
          if matches(row, col, dir, s, r1, c1, r2, c2, r3, c3, r4, c4) then
            return row, col, dir, s
          end
        else
          for d = 1, 4 do
            if matches(row, col, d, s, r1, c1, r2, c2, r3, c3, r4, c4) then
              return row, col, d, s
            end
          end
        end
      end
    end
  end
end

return {
  conflict = conflict,
  down = down,
  fromPos = fromPos,
  getPos = getPos,
  ghost = ghost,
  lock = lock,
  representStr = representStr,
  rotate = rotate,
}
