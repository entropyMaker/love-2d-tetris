local tetromino = require("tetromino")
local _ = require("lodash")

local function empty()
  local row = _.fill(0, 10)
  return _.fill(row, 40)
end

local function setPiece(matrix, val, ...)
  local positions = { ... }
  for i = 1, #positions, 2 do
    matrix[positions[i]][positions[i + 1]] = val
  end
end

local function fromPos()
  local e = empty()
  local tests = {
    { pos = { 1, 1, 1, 2, 1, 3, 1, 4 }, matrix = e, str = "I" },
    { pos = { 11, 5, 12, 5, 13, 5, 14, 5 }, matrix = e, str = "I" },
    { pos = { 2, 3, 2, 4, 3, 4, 4, 4 }, matrix = e, str = "J" },
    { pos = { 7, 5, 7, 4, 8, 4, 9, 4 }, matrix = e, str = "L" },
    { pos = { 15, 7, 16, 8, 15, 8, 16, 7 }, matrix = e, str = "O" },
    { pos = { 13, 2, 14, 4, 13, 3, 14, 3 }, matrix = e, str = "S" },
    { pos = { 18, 9, 17, 9, 18, 8, 18, 10 }, matrix = e, str = "T" },
    { pos = { 5, 1, 7, 2, 6, 2, 6, 1 }, matrix = e, str = "Z" },
    { pos = { 1, 1 }, matrix = e, str = "" },
    { pos = { 1, 1, 10, 8, 20, 2, 15, 2 }, matrix = e, str = "" },
  }

  for i, test in ipairs(tests) do
    local pass
    local row, col, dir, shape =
      tetromino.fromPos(test.matrix, nil, unpack(test.pos))
    if shape == nil then
      pass = test.str == ""
    else
      pass = tetromino.representStr(shape) == test.str
    end

    if not pass then
      return "Tetromino fromPos unit test failed at case " .. i
    end
  end
  return #tests
end

local function matches(a, b)
  if #a ~= #b then return false end

  for i = 1, #a, 2 do
    local miss = true
    for j = 1, #b, 2 do
      if a[i] == b[j] and a[i + 1] == b[j + 1] then
        miss = false
        break
      end
    end
    if miss then return false end
  end
  return true
end

local function ghost()
  local e = empty()
  local tests = {
    { pos = { 13, 2, 13, 3, 13, 4, 13, 5 }, matrix = e, want = 12 },
    { pos = { 5, 6, 6, 6, 7, 6, 8, 6 }, matrix = e, want = 4 },
    { pos = { 2, 3, 2, 4, 3, 4, 4, 4 }, matrix = e, want = 1 },
    { pos = { 1, 4, 1, 5, 1, 6, 2, 6 }, matrix = e, want = 0 },
    { pos = { 11, 9, 11, 10, 12, 9, 12, 10 }, matrix = e, want = 10 },
    { pos = { 20, 3, 21, 3, 21, 2, 22, 2 }, matrix = e, want = 19 },
    { pos = { 14, 10, 15, 10, 16, 10, 15, 9 }, matrix = e, want = 13 },
    { pos = { 21, 10, 20, 10, 20, 9, 19, 9 }, matrix = e, want = 18 },
  }

  local m
  --[[
    OOOOOOOOOI
    OOOOOOOOOI
    OOOOOOOOOI
    OOOOOOOOO(I/G)
    OOOOOOOOOG
    OOOOOOOOOG
    OOOOOOOOOG
    XXXXXXXXXX
    XXXXXXXXXX
  ]]
  m = _.fill(0, 40, 10)
  for i = 1, 2 do
    m[i] = _.fill(1, 10)
  end
  tests[#tests + 1] =
    { pos = { 6, 10, 7, 10, 8, 10, 9, 10 }, matrix = m, want = 3 }

  --[[
    OOOOOOOJJJ
    OOOOOOOOOJ
    OOOOOOOOOO
    OOOOOOOGGG
    XXXXXXXXXG
    XXXXXXXXXO
  ]]
  m = _.fill(0, 40, 10)
  for i = 1, 2 do
    for j = 1, 9 do
      m[i][j] = 3
    end
  end
  tests[#tests + 1] =
    { pos = { 5, 10, 6, 10, 6, 9, 6, 8 }, matrix = m, want = 3 }

  --[[
    OOOOOOOOOO
    OOOOLLOOOO
    OOOOOLOOOO
    OOOOOLOOOO
    OOOOOOOOOO
    OOOOGGOOOO
    XXXXXGXXXX
    XXXXOGOXXX
    XXXXXOXXXX
  ]]
  m = _.fill(0, 40, 10)
  m[1], m[2], m[3] = _.fill(7, 10), _.fill(6, 10), _.fill(5, 10)
  setPiece(m, 0, 3, 6, 1, 6, 2, 5, 2, 6, 2, 7)
  tests[#tests + 1] = { pos = { 8, 5, 8, 6, 7, 6, 6, 6 }, matrix = m, want = 4 }

  --[[
    DDOOOOOOOO
    DDOOOOOOOO
    OOOOOOOOOO
    ...
    OOOOOOOOOO
    GGXXXXXXXX
    GGOXXXXXXX
    XOXXXXXXXX
  ]]
  m = _.fill(0, 40, 10)
  for i = 1, 3 do
    m[i] = _.fill(5, 10)
  end
  setPiece(m, 0, 1, 2, 2, 1, 2, 2, 2, 3, 3, 1, 3, 2)
  tests[#tests + 1] =
    { pos = { 14, 1, 14, 2, 15, 1, 15, 2 }, matrix = m, want = 12 }

  --[[
    OOOOOOOOOO
    OSSOOOOOOO
    SSOOOOOOOO
    ...
    OOOOOOOOOO
    OGGOOOOOOO
    GGXXXXXXXX
    OOOXXXXXXX
    XOXXXXXXXX
    XXOXXXXXXX
  ]]
  m = _.fill(0, 40, 10)
  for i = 1, 4 do
    m[i] = _.fill(5, 10)
  end
  setPiece(m, 0, 1, 3, 2, 2, 3, 1, 3, 2, 3, 3, 4, 1, 4, 2)
  tests[#tests + 1] =
    { pos = { 12, 1, 12, 2, 13, 2, 13, 3 }, matrix = m, want = 8 }

  --[[
    OOOOOOOOTO
    OOOOOOOOTT
    OOOOOOOOTO
    ...
    OOOOOOOOOO
    OOXOXOXXGO
    XXXXXXXOGG
    XXXXXXXXGX
    XXXXXXXXOX
  ]]
  m = _.fill(0, 40, 10)
  for i = 1, 4 do
    m[i] = _.fill(3, 10)
  end
  setPiece(
    m,
    0,
    1,
    9,
    2,
    9,
    3,
    8,
    3,
    9,
    3,
    10,
    4,
    9,
    4,
    1,
    4,
    2,
    4,
    4,
    4,
    6,
    4,
    9,
    4,
    10
  )
  tests[#tests + 1] =
    { pos = { 20, 9, 19, 9, 19, 10, 18, 9 }, matrix = m, want = 16 }

  --[[
    OOOOOOOOOZ
    OOOOOOOOZZ
    OOOOOOOOZO
    ...
    OOOOOOOOOO
    OOXOXOXXOG
    XXXXXXXOGG
    XXXXXXXXGX
    XXXXXXXXOX
  ]]
  m = _.fill(0, 40, 10)
  for i = 1, 4 do
    m[i] = _.fill(3, 10)
  end
  setPiece(
    m,
    0,
    1,
    9,
    2,
    9,
    3,
    8,
    3,
    9,
    3,
    10,
    4,
    9,
    4,
    1,
    4,
    2,
    4,
    4,
    4,
    6,
    4,
    9,
    4,
    10
  )
  tests[#tests + 1] =
    { pos = { 13, 10, 12, 10, 12, 9, 11, 9 }, matrix = m, want = 9 }

  for i, test in ipairs(tests) do
    local row, col, dir, shape =
      tetromino.fromPos(test.matrix, nil, unpack(test.pos))
    local newRow = tetromino.ghost(test.matrix, row, col, dir, shape)
    if row - newRow ~= test.want then
      return "Tetromino ghost unit test failed at case " .. i
    end
  end
  return #tests
end

local function rotate()
  local function message(i, want, get)
    return string.format(
      "Tetromino rotate unit test failed at case %d, want %s, get %s",
      i,
      table.concat(want, ","),
      get and table.concat(get, ",") or "nil"
    )
  end

  local e = empty()
  local tests = { -- basic rotation for 'I'
    {
      pos = { 8, 1, 8, 2, 8, 3, 8, 4 },
      dir = 1,
      matrix = e,
      clockwise = true,
      want = { 6, 3, 7, 3, 8, 3, 9, 3 },
    },
    {
      pos = { 6, 3, 7, 3, 8, 3, 9, 3 },
      dir = 2,
      matrix = e,
      clockwise = true,
      want = { 7, 1, 7, 2, 7, 3, 7, 4 },
    },
    {
      pos = { 7, 1, 7, 2, 7, 3, 7, 4 },
      dir = 3,
      matrix = e,
      clockwise = true,
      want = { 6, 2, 7, 2, 8, 2, 9, 2 },
    },
    {
      pos = { 6, 2, 7, 2, 8, 2, 9, 2 },
      dir = 4,
      matrix = e,
      clockwise = true,
      want = { 8, 1, 8, 2, 8, 3, 8, 4 },
    },
    {
      pos = { 8, 1, 8, 2, 8, 3, 8, 4 },
      dir = 1,
      matrix = e,
      clockwise = false,
      want = { 6, 2, 7, 2, 8, 2, 9, 2 },
    },
    {
      pos = { 6, 3, 7, 3, 8, 3, 9, 3 },
      dir = 2,
      matrix = e,
      clockwise = false,
      want = { 8, 1, 8, 2, 8, 3, 8, 4 },
    },
    {
      pos = { 7, 1, 7, 2, 7, 3, 7, 4 },
      dir = 3,
      matrix = e,
      clockwise = false,
      want = { 6, 3, 7, 3, 8, 3, 9, 3 },
    },
    {
      pos = { 6, 2, 7, 2, 8, 2, 9, 2 },
      dir = 4,
      matrix = e,
      clockwise = false,
      want = { 7, 1, 7, 2, 7, 3, 7, 4 },
    }, -- basic rotation for 'J'
    {
      pos = { 2, 8, 3, 8, 2, 9, 2, 10 },
      dir = 1,
      matrix = e,
      clockwise = true,
      want = { 1, 9, 2, 9, 3, 9, 3, 10 },
    },
    {
      pos = { 1, 9, 2, 9, 3, 9, 3, 10 },
      dir = 2,
      matrix = e,
      clockwise = true,
      want = { 1, 10, 2, 10, 2, 9, 2, 8 },
    },
    {
      pos = { 1, 10, 2, 10, 2, 9, 2, 8 },
      dir = 3,
      matrix = e,
      clockwise = true,
      want = { 1, 8, 1, 9, 2, 9, 3, 9 },
    },
    {
      pos = { 1, 8, 1, 9, 2, 9, 3, 9 },
      dir = 4,
      matrix = e,
      clockwise = true,
      want = { 2, 8, 3, 8, 2, 9, 2, 10 },
    },
    {
      pos = { 2, 8, 3, 8, 2, 9, 2, 10 },
      dir = 1,
      matrix = e,
      clockwise = false,
      want = { 1, 8, 1, 9, 2, 9, 3, 9 },
    },
    {
      pos = { 1, 9, 2, 9, 3, 9, 3, 10 },
      dir = 2,
      matrix = e,
      clockwise = false,
      want = { 2, 8, 3, 8, 2, 9, 2, 10 },
    },
    {
      pos = { 1, 10, 2, 10, 2, 9, 2, 8 },
      dir = 3,
      matrix = e,
      clockwise = false,
      want = { 1, 9, 2, 9, 3, 9, 3, 10 },
    },
    {
      pos = { 1, 8, 1, 9, 2, 9, 3, 9 },
      dir = 4,
      matrix = e,
      clockwise = false,
      want = { 1, 10, 2, 10, 2, 9, 2, 8 },
    }, -- basic rotation for 'L'
    {
      pos = { 20, 4, 20, 5, 20, 6, 21, 6 },
      dir = 1,
      matrix = e,
      clockwise = true,
      want = { 19, 5, 19, 6, 20, 5, 21, 5 },
    },
    {
      pos = { 19, 5, 19, 6, 20, 5, 21, 5 },
      dir = 2,
      matrix = e,
      clockwise = true,
      want = { 19, 4, 20, 4, 20, 5, 20, 6 },
    },
    {
      pos = { 19, 4, 20, 4, 20, 5, 20, 6 },
      dir = 3,
      matrix = e,
      clockwise = true,
      want = { 21, 4, 21, 5, 20, 5, 19, 5 },
    },
    {
      pos = { 21, 4, 21, 5, 20, 5, 19, 5 },
      dir = 4,
      matrix = e,
      clockwise = true,
      want = { 20, 4, 20, 5, 20, 6, 21, 6 },
    },
    {
      pos = { 20, 4, 20, 5, 20, 6, 21, 6 },
      dir = 1,
      matrix = e,
      clockwise = false,
      want = { 21, 4, 21, 5, 20, 5, 19, 5 },
    },
    {
      pos = { 19, 5, 19, 6, 20, 5, 21, 5 },
      dir = 2,
      matrix = e,
      clockwise = false,
      want = { 20, 4, 20, 5, 20, 6, 21, 6 },
    },
    {
      pos = { 19, 4, 20, 4, 20, 5, 20, 6 },
      dir = 3,
      matrix = e,
      clockwise = false,
      want = { 19, 5, 19, 6, 20, 5, 21, 5 },
    },
    {
      pos = { 21, 4, 21, 5, 20, 5, 19, 5 },
      dir = 4,
      matrix = e,
      clockwise = false,
      want = { 19, 4, 20, 4, 20, 5, 20, 6 },
    }, -- basic rotation for 'S'
    {
      pos = { 14, 8, 14, 9, 15, 9, 15, 10 },
      dir = 1,
      matrix = e,
      clockwise = true,
      want = { 14, 9, 15, 9, 14, 10, 13, 10 },
    },
    {
      pos = { 14, 9, 15, 9, 14, 10, 13, 10 },
      dir = 2,
      matrix = e,
      clockwise = true,
      want = { 13, 8, 13, 9, 14, 9, 14, 10 },
    },
    {
      pos = { 13, 8, 13, 9, 14, 9, 14, 10 },
      dir = 3,
      matrix = e,
      clockwise = true,
      want = { 15, 8, 14, 8, 14, 9, 13, 9 },
    },
    {
      pos = { 15, 8, 14, 8, 14, 9, 13, 9 },
      dir = 4,
      matrix = e,
      clockwise = true,
      want = { 14, 8, 14, 9, 15, 9, 15, 10 },
    },
    {
      pos = { 14, 8, 14, 9, 15, 9, 15, 10 },
      dir = 1,
      matrix = e,
      clockwise = false,
      want = { 15, 8, 14, 8, 14, 9, 13, 9 },
    },
    {
      pos = { 14, 9, 15, 9, 14, 10, 13, 10 },
      dir = 2,
      matrix = e,
      clockwise = false,
      want = { 14, 8, 14, 9, 15, 9, 15, 10 },
    },
    {
      pos = { 13, 8, 13, 9, 14, 9, 14, 10 },
      dir = 3,
      matrix = e,
      clockwise = false,
      want = { 14, 9, 15, 9, 14, 10, 13, 10 },
    },
    {
      pos = { 15, 8, 14, 8, 14, 9, 13, 9 },
      dir = 4,
      matrix = e,
      clockwise = false,
      want = { 13, 8, 13, 9, 14, 9, 14, 10 },
    }, -- basic rotation for 'T'
    {
      pos = { 2, 2, 2, 3, 2, 4, 3, 3 },
      dir = 1,
      matrix = e,
      clockwise = true,
      want = { 1, 3, 2, 3, 3, 3, 2, 4 },
    },
    {
      pos = { 1, 3, 2, 3, 3, 3, 2, 4 },
      dir = 2,
      matrix = e,
      clockwise = true,
      want = { 2, 2, 2, 3, 2, 4, 1, 3 },
    },
    {
      pos = { 2, 2, 2, 3, 2, 4, 1, 3 },
      dir = 3,
      matrix = e,
      clockwise = true,
      want = { 1, 3, 2, 3, 3, 3, 2, 2 },
    },
    {
      pos = { 1, 3, 2, 3, 3, 3, 2, 2 },
      dir = 4,
      matrix = e,
      clockwise = true,
      want = { 2, 2, 2, 3, 2, 4, 3, 3 },
    },
    {
      pos = { 2, 2, 2, 3, 2, 4, 3, 3 },
      dir = 1,
      matrix = e,
      clockwise = false,
      want = { 1, 3, 2, 3, 3, 3, 2, 2 },
    },
    {
      pos = { 1, 3, 2, 3, 3, 3, 2, 4 },
      dir = 2,
      matrix = e,
      clockwise = false,
      want = { 2, 2, 2, 3, 2, 4, 3, 3 },
    },
    {
      pos = { 2, 2, 2, 3, 2, 4, 1, 3 },
      dir = 3,
      matrix = e,
      clockwise = false,
      want = { 1, 3, 2, 3, 3, 3, 2, 4 },
    },
    {
      pos = { 1, 3, 2, 3, 3, 3, 2, 2 },
      dir = 4,
      matrix = e,
      clockwise = false,
      want = { 2, 2, 2, 3, 2, 4, 1, 3 },
    }, -- basic rotation for 'Z'
    {
      pos = { 7, 4, 7, 5, 6, 5, 6, 6 },
      dir = 1,
      matrix = e,
      clockwise = true,
      want = { 7, 6, 6, 6, 6, 5, 5, 5 },
    },
    {
      pos = { 7, 6, 6, 6, 6, 5, 5, 5 },
      dir = 2,
      matrix = e,
      clockwise = true,
      want = { 6, 4, 6, 5, 5, 5, 5, 6 },
    },
    {
      pos = { 6, 4, 6, 5, 5, 5, 5, 6 },
      dir = 3,
      matrix = e,
      clockwise = true,
      want = { 7, 5, 6, 5, 6, 4, 5, 4 },
    },
    {
      pos = { 7, 5, 6, 5, 6, 4, 5, 4 },
      dir = 4,
      matrix = e,
      clockwise = true,
      want = { 7, 4, 7, 5, 6, 5, 6, 6 },
    },
    {
      pos = { 7, 4, 7, 5, 6, 5, 6, 6 },
      dir = 1,
      matrix = e,
      clockwise = false,
      want = { 7, 5, 6, 5, 6, 4, 5, 4 },
    },
    {
      pos = { 7, 6, 6, 6, 6, 5, 5, 5 },
      dir = 2,
      matrix = e,
      clockwise = false,
      want = { 7, 4, 7, 5, 6, 5, 6, 6 },
    },
    {
      pos = { 6, 4, 6, 5, 5, 5, 5, 6 },
      dir = 3,
      matrix = e,
      clockwise = false,
      want = { 7, 6, 6, 6, 6, 5, 5, 5 },
    },
    {
      pos = { 7, 5, 6, 5, 6, 4, 5, 4 },
      dir = 4,
      matrix = e,
      clockwise = false,
      want = { 6, 4, 6, 5, 5, 5, 5, 6 },
    },
  }

  local m

  --[[
    IOOOOOOOOO
    IiiiOOOOOO
    IXXXXXXXXX
    IXXXXXXXXX
    OXXXXXXXXX
    OXXXXXXXXX
    OXXXXXXXXX
  ]]
  m = _.fill(0, 40, 10)
  for i = 1, 5 do
    m[i] = _.fill(1, 10)
    m[i][1] = 0
  end
  tests[#tests + 1] = {
    pos = { 6, 1, 6, 2, 6, 3, 6, 4 },
    dir = 1,
    matrix = m,
    clockwise = true,
    want = { 4, 1, 5, 1, 6, 1, 7, 1 },
  }

  --[[
    OOOOOOOOOI
    OOOOOOiiiI
    XXXXXXXXXI
    XXXXXXXXXI
    XXXXXXXXXO
    XXXXXXXXXO
    XXXXXXXXXO
  ]]
  m = _.fill(0, 40, 10)
  for i = 1, 5 do
    m[i] = _.fill(1, 10)
    m[i][10] = 0
  end
  m[7][1] = 1
  tests[#tests + 1] = {
    pos = { 6, 7, 6, 8, 6, 9, 6, 10 },
    dir = 1,
    matrix = m,
    clockwise = true,
    want = { 4, 10, 5, 10, 6, 10, 7, 10 },
  }

  --[[
    XOOOOOOOOO
    IiiiOOOOOX
    IXXXXXXXXX
    IXXXXXXXXX
    IXXXXXXXXX
    OXXXXXXXXX
    OXXXXXXXXX
  ]]
  m = _.fill(0, 40, 10)
  for i = 1, 5 do
    m[i] = _.fill(1, 10)
    m[i][1] = 0
  end
  m[7][1] = 1
  tests[#tests + 1] = {
    pos = { 6, 1, 6, 2, 6, 3, 6, 4 },
    dir = 1,
    matrix = m,
    clockwise = true,
    want = { 3, 1, 4, 1, 5, 1, 6, 1 },
  }

  --[[
    OOOIOOOOOO
    OOOIOOOOOO
    OOOIOOOOOO
    iiiIOOOOOO
    XXXXXXXXXX
    XXXXXXXXXX
    XXXXXXXXXX
    XXXXXXXXXX
  ]]
  m = _.fill(0, 40, 10)
  for i = 1, 4 do
    m[i] = _.fill(1, 10)
  end
  m[7][1] = 1
  tests[#tests + 1] = {
    pos = { 5, 1, 5, 2, 5, 3, 5, 4 },
    dir = 1,
    matrix = m,
    clockwise = true,
    want = { 5, 4, 6, 4, 7, 4, 8, 4 },
  }

  --[[
    OOOOOOOOOi
    OOOOOOOOOi
    OOOOOOIIII
    OOOOOOOOOi
  ]]
  tests[#tests + 1] = {
    pos = { 1, 10, 2, 10, 3, 10, 4, 10 },
    dir = 2,
    matrix = e,
    clockwise = true,
    want = { 2, 7, 2, 8, 2, 9, 2, 10 },
  }

  --[[
    iOOOOOOOOO
    iOOOOOOOOO
    IIIIOOOOOO
    iOOOOOOOOO
  ]]
  tests[#tests + 1] = {
    pos = { 1, 1, 2, 1, 3, 1, 4, 1 },
    dir = 2,
    matrix = e,
    clockwise = true,
    want = { 2, 1, 2, 2, 2, 3, 2, 4 },
  }

  --[[
    OOOOOOIIII
    OOOOOOOOOi
    XXXXXXXXXi
    XXXXXXXXXi
  ]]
  m = _.fill(0, 40, 10)
  for i = 1, 2 do
    m[i] = _.fill(1, 10)
    m[i][10] = 0
  end
  tests[#tests + 1] = {
    pos = { 1, 10, 2, 10, 3, 10, 4, 10 },
    dir = 2,
    matrix = m,
    clockwise = true,
    want = { 4, 7, 4, 8, 4, 9, 4, 10 },
  }

  --[[
    OOOOOOOOOO
    iOOOOOOOOO
    iXXXXXXXXX
    iXXXXXXXXX
    IIIIOOXXXX
  ]]
  m = _.fill(0, 40, 10)
  for i = 2, 3 do
    m[i] = _.fill(1, 10)
    m[i][1] = 0
  end
  m[1] = { 0, 0, 0, 0, 0, 0, 2, 2, 2, 2 }
  tests[#tests + 1] = {
    pos = { 1, 1, 2, 1, 3, 1, 4, 1 },
    dir = 2,
    matrix = m,
    clockwise = true,
    want = { 1, 1, 1, 2, 1, 3, 1, 4 },
  }

  --[[
    OOOOOOOOOI
    OOOOOOOOOI
    OOOOOOOOOI
    OOOOOOiiiI
    XXXXXXXXOX
  ]]
  m = _.fill(0, 40, 10)
  m[1] = _.fill(1, 10)
  m[1][9] = 0
  tests[#tests + 1] = {
    pos = { 2, 7, 2, 8, 2, 9, 2, 10 },
    dir = 3,
    matrix = m,
    clockwise = true,
    want = { 2, 10, 3, 10, 4, 10, 5, 10 },
  }

  --[[
    OOOOOOOOOO
    OOOOOOIIII
    XXXXXXXXXi
    XXXXXXXXXi
    XXXXXXXXXi
  ]]
  m = _.fill(0, 40, 10)
  for i = 1, 3 do
    m[i] = _.fill(1, 10)
    m[i][10] = 0
  end
  tests[#tests + 1] = {
    pos = { 1, 10, 2, 10, 3, 10, 4, 10 },
    dir = 4,
    matrix = m,
    clockwise = true,
    want = { 4, 7, 4, 8, 4, 9, 4, 10 },
  }

  --[[
    OOOOOOOOOI
    OOOOOOiiiI
    XXXXXXXXXI
    XXXXXXXXXI
    XXXXXXXXXO
  ]]
  m = _.fill(0, 40, 10)
  for i = 1, 3 do
    m[i] = _.fill(1, 10)
    m[i][10] = 0
  end
  tests[#tests + 1] = {
    pos = { 4, 7, 4, 8, 4, 9, 4, 10 },
    dir = 1,
    matrix = m,
    clockwise = false,
    want = { 2, 10, 3, 10, 4, 10, 5, 10 },
  }

  --[[
    OOOOOOOOOi
    XXXXXXXXXi
    XXXXXXXXXi
    XXXXXXIIII
  ]]
  m = _.fill(0, 40, 10)
  m[1] = { 1, 1, 1, 1, 1, 1, 0, 0, 0, 0 }
  for i = 2, 3 do
    m[i] = _.fill(1, 10)
    m[i][10] = 0
  end
  tests[#tests + 1] = {
    pos = { 1, 10, 2, 10, 3, 10, 4, 10 },
    dir = 2,
    matrix = m,
    clockwise = false,
    want = { 1, 10, 1, 9, 1, 8, 1, 7 },
  }

  --[[
    OIOOOOOOOO
    OIOOOOOOOO
    OIOOOOOOOO
    OIiiiOOOOO
    XXXXXXXXXX
  ]]
  m = _.fill(0, 40, 10)
  m[1] = _.fill(1, 10)
  tests[#tests + 1] = {
    pos = { 2, 2, 2, 3, 2, 4, 2, 5 },
    dir = 3,
    matrix = m,
    clockwise = false,
    want = { 2, 2, 3, 2, 4, 2, 5, 2 },
  }

  --[[
    iOOOOOOOOO
    iOOOOOOOOO
    IIIIOOOOOO
    iOOOOOOOOO
  ]]
  tests[#tests + 1] = {
    pos = { 1, 1, 2, 1, 3, 1, 4, 1 },
    dir = 4,
    matrix = e,
    clockwise = false,
    want = { 2, 1, 2, 2, 2, 3, 2, 4 },
  }

  for i, test in ipairs(tests) do
    local row, col, dir, shape =
      tetromino.fromPos(test.matrix, test.dir, unpack(test.pos))
    if not shape then message(i, test.want, nil) end
    local spin, newRow, newCol, newDir =
      tetromino.rotate(test.matrix, test.clockwise, row, col, dir, shape)
    local get = { tetromino.getPos(newRow, newCol, newDir, shape) }
    if not matches(test.want, get) then return message(i, test.want, get) end
  end
  return #tests
end

return {
  fromPos = fromPos,
  ghost = ghost,
  rotate = rotate,
}
