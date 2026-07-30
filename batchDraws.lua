local tetromino = require("tetromino")
local SpinType = require("spin")
local _ = require("lodash")

return function(config, graphics)
  -- tetromino may appear above the whole matrix, 3 is a safe bound
  local batchRowNumber = config.rowNumber + 3
  local tetrominoInd = batchRowNumber * config.colNumber

  local images = {}
  local minoBatch
  local ghostBatch
  local digitBatches = {}
  local minoQuads = {}

  local lastMatrix = _.fill(_.fill(0, config.colNumber), batchRowNumber)
  local lastPreview = {}
  local lastHold, lastRow, lastCol, lastDir, lastShape = 0, 0, 0, 0, 0

  local function minoArgs(row, col)
    local step = config.step
    return config.x + col * step, config.y - row * step, 0, config.scale
  end

  do
    graphics.setNewFont(config.fontSize)
    local newImage, newQuad = graphics.newImage, graphics.newQuad
    local mino = newImage(config.minosPath)
    -- 4 is number of mino in one tetromino, 2 is 1 hold + 1 tetromino
    local minoSize = batchRowNumber * config.colNumber
      + 4 * (2 + config.seenPreview)
    minoBatch = graphics.newSpriteBatch(mino, minoSize)
    for i = 1, minoSize do
      minoBatch:add(0, 0, 0, 0)
    end

    ghostBatch = graphics.newSpriteBatch(mino, 4)
    for i = 1, ghostBatch:getBufferSize() do
      ghostBatch:add(0, 0, 0, 0)
    end

    images.bg = graphics.newImage(config.bgPath)
    images.bgBlank = graphics.newImage(config.bgBlankPath)
    images.tetris = graphics.newImage(config.tetrisPath)
    images.tSpin = graphics.newImage(config.tSpinPath)
    images.tSpinMini = graphics.newImage(config.tSpinMiniPath)

    local minosHeight = mino:getHeight()
    local minoWidth = mino:getWidth() / 7
    for i = 1, #tetromino.representStr(0) do
      minoQuads[i] =
        newQuad((i - 1) * minoWidth, 0, minoWidth, minosHeight, mino)
    end

    for i = 1, #config.digits do
      local b = graphics.newSpriteBatch(mino, #config.digits[i] / 2, "static")
      local q = minoQuads[i]
      for j = 2, #config.digits[i], 2 do
        b:add(q, minoArgs(config.digits[i][j - 1], config.digits[i][j]))
      end
      digitBatches[i] = b
    end

    -- only keep the fields that will be used in methods
    config = _.pick(
      config,
      {
        "holdPos",
        "previewPos",
        "x",
        "y",
        "step",
        "scale",
        "textX",
        "textY",
        "awardX",
        "awardY",
      }
    )
  end

  local function blankPos(r, c, x, y, step)
    x = x - 1 + c * step
    y = y - 1 - r * step
    local x1, y1 = x + step, y + step
    return x, y, x1, y, x1, y1, x, y1
  end

  local function tetro(batch, row, col, dir, shape, ind)
    local set = batch.set
    if shape and shape > 0 then
      local r1, c1, r2, c2, r3, c3, r4, c4 =
        tetromino.getPos(row, col, dir, shape)
      local q = minoQuads[shape]
      set(batch, ind + 1, q, minoArgs(r1, c1))
      set(batch, ind + 2, q, minoArgs(r2, c2))
      set(batch, ind + 3, q, minoArgs(r3, c3))
      set(batch, ind + 4, q, minoArgs(r4, c4))
    else
      set(batch, ind + 1, 0, 0, 0, 0)
      set(batch, ind + 2, 0, 0, 0, 0)
      set(batch, ind + 3, 0, 0, 0, 0)
      set(batch, ind + 4, 0, 0, 0, 0)
    end
    return batch
  end

  -- public methods
  local function text(level, lines, score)
    local x, y, gprint = config.textX, config.textY, graphics.print

    gprint("Level: ", x, y)
    gprint(level, x + 60, y)
    gprint("Lines: ", x, y + 30)
    gprint(lines, x + 60, y + 30)
    gprint("Score: ", x, y + 60)
    gprint(score, x + 60, y + 60)
  end

  local function bg() graphics.draw(images.bg) end

  local function bgBlank() graphics.draw(images.bgBlank) end

  local function awardTetris()
    graphics.draw(images.tetris, config.awardX, config.awardY, 0, config.scale)
  end

  local function awardTSpin(spin)
    local s = spin == SpinType.TSpin and "tSpin"
      or (spin == SpinType.TSpinMini and "tSpinMini" or "")
    if s == "" then return end
    graphics.draw(images[s], config.awardX, config.awardY, 0, config.scale)
  end

  local function blank(row, col, dir, shape)
    local r1, c1, r2, c2, r3, c3, r4, c4 =
      tetromino.getPos(row, col, dir, shape)
    local x, y, step = config.x, config.y, config.step
    local polygon = graphics.polygon
    polygon("fill", blankPos(r1, c1, x, y, step))
    polygon("fill", blankPos(r2, c2, x, y, step))
    polygon("fill", blankPos(r3, c3, x, y, step))
    polygon("fill", blankPos(r4, c4, x, y, step))
  end

  local function zone(headRow, lastRow, lastCol)
    local x, y, step = config.x - 1, config.y - 1, config.step
    local y1 = y - (headRow - 1) * step
    x = x + step
    y = y - lastRow * step
    local x1 = x + lastCol * step
    graphics.polygon("fill", x, y, x1, y, x1, y1, x, y1)
  end

  local function digit(d, alpha)
    local batch = digitBatches[d]
    if not batch then error(d .. " cannot be displayed") end

    local r, g, b, a = graphics.getColor()
    graphics.setColor(1, 1, 1, alpha)
    graphics.draw(batch)
    graphics.setColor(r, g, b, a)
  end

  local function ghost(row, col, dir, shape, alpha)
    local r, g, b, a = graphics.getColor()
    graphics.setColor(1, 1, 1, alpha)
    graphics.draw(tetro(ghostBatch, row, col, dir, shape, 0))
    graphics.setColor(r, g, b, a)
  end

  local function hold(shape)
    if shape == lastHold then return end
    lastHold = shape
    local row, col = config.holdPos(tetromino.representStr(shape))
    tetro(minoBatch, row, col, 1, shape, minoBatch:getBufferSize() - 4)
  end

  local function preview(i, shape)
    if shape == lastPreview[i] then return end
    lastPreview[i] = shape
    local row, col = config.previewPos(i, tetromino.representStr(shape))
    tetro(minoBatch, row, col, 1, shape, tetrominoInd + i * 4)
  end

  local function mainTetromino(row, col, dir, shape)
    if
      row == lastRow
      and col == lastCol
      and dir == lastDir
      and shape == lastShape
    then
      return
    end

    lastRow, lastCol, lastDir, lastShape = row, col, dir, shape
    tetro(minoBatch, row, col, dir, shape, tetrominoInd)
  end

  local function matrix(mat)
    if mat == lastMatrix then return graphics.draw(minoBatch) end

    local colNumber = #mat[1]
    local set = minoBatch.set
    for i = 1, batchRowNumber do
      local row, lastRow = mat[i], lastMatrix[i]
      if row ~= lastRow then
        for j = 1, colNumber do
          local v = row[j]
          if v == lastRow[j] then
            -- do nothing
          elseif v > 0 then
            set(
              minoBatch,
              j + (i - 1) * colNumber,
              minoQuads[v],
              minoArgs(i, j)
            )
          else
            set(minoBatch, j + (i - 1) * colNumber, 0, 0, 0, 0)
          end
        end
      end
    end
    lastMatrix = mat
    graphics.draw(minoBatch)
  end

  return {
    text = text,
    bg = bg,
    bgBlank = bgBlank,
    awardTetris = awardTetris,
    awardTSpin = awardTSpin,
    blank = blank,
    zone = zone,
    digit = digit,
    ghost = ghost,
    hold = hold,
    preview = preview,
    tetromino = mainTetromino,
    matrix = matrix,
  }
end
