local GameState = require("gameState")

local StateEnum = {
  Moving = 1,
  LockDelaying = 2,
  Locking = 3,
  Over = 4,
  Pausing = 5,
}

local Input = {
  Invalid = 0,
  SoftDrop = 1,
  HardDrop = 2,
  Left = 3,
  Right = 4,
  ClockwiseRotate = 5,
  AntiClockwiseRotate = 6,
  Hold = 7,
  Pause = 8,
}

return function(config, scorer)
  local state = GameState(
    config.generator,
    config.initer,
    config.rowNumber,
    config.colNumber
  )
  local enum = StateEnum.Moving
  -- LockDelaying: countdown to lock
  -- Locking: countdown to finish locking
  local countdown = 0
  -- Accumulated fractional cells for the fixed 60 Hz gravity calculation.
  local gravityProgress = 0
  -- horizontal moving direction, -1 is to left, 1 is to right, 0 means NA
  local horizDirection = 0
  -- countdown for horizontal moving
  local horizCountdown = 0
  -- pressing key as a set, only record SoftDrop, Left and Right
  local pressing = {}
  -- Number of move/rotation resets used after the piece first lands.
  local lockResets = 0
  local hasLanded = false
  -- clear rows of last lock, only meaningful when enum == StateEnum.Locking
  local clearRows = {}
  -- if < 0 means keep pausing, otherwise is the time to stop pausing
  local pauseCountdown = 0
  -- enum before pause
  local enumBeforePause = enum

  -- private methods
  local modf = math.modf

  local function enterPause()
    pauseCountdown = -1
    enumBeforePause = enum
    enum = StateEnum.Pausing
  end

  local function horiz(key, moved)
    local pre = horizDirection
    if key == Input.Left or key == Input.Right then
      pressing[key] = true
      horizDirection = key == Input.Left and -1 or 1
    end
    horizCountdown = (moved and horizDirection ~= pre) and config.countDAS
      or config.countARR
  end

  local function lock()
    local gameOver, down, rows, perfectClear = state.lock()
    enum = gameOver and StateEnum.Over or StateEnum.Locking
    scorer.clear(#rows, state.recentSpin(), perfectClear)
    scorer.drop(down, scorer.DropType.HardDrop)
    countdown = #rows > 0 and config.countClear or config.countLock
    clearRows = rows
  end

  local function checkLockDelay(resetRequested)
    local pre = enum
    local ghostDown = state.ghostDown()
    local reset = false
    if ghostDown > 0 then
      enum = StateEnum.Moving
      if pre ~= enum then
        gravityProgress = 0
        if resetRequested and lockResets < config.limitLockDelay then
          lockResets = lockResets + 1
          countdown = config.countLockDelay
          reset = true
        end
      end
    elseif pre ~= StateEnum.LockDelaying then
      enum = StateEnum.LockDelaying
      if not hasLanded then
        hasLanded = true
        countdown = config.countLockDelay
        reset = true
      end
    elseif resetRequested and lockResets < config.limitLockDelay then
      lockResets = lockResets + 1
      countdown = config.countLockDelay
      reset = true
    end
    return enum == StateEnum.Moving or reset
  end

  local function newTetromino()
    lockResets = 0
    hasLanded = false
    gravityProgress = 0
    enum = StateEnum.Moving
    checkLockDelay(false)
    horizCountdown = horizDirection == 0 and 0 or config.countARR
  end

  -- public methods
  local function keypressed(key)
    if enum == StateEnum.Over then return end

    if enum == StateEnum.Pausing then
      if key == Input.SoftDrop then
        pressing[key] = true
      elseif key == Input.Left or key == Input.Right then
        horiz(key, false)
      elseif key == Input.Pause and pauseCountdown < 0 then
        pauseCountdown = config.countPause
      end
      return
    end

    if enum == StateEnum.Locking then
      if key == Input.SoftDrop then
        pressing[key] = true
      elseif key == Input.Left or key == Input.Right then
        horiz(key, false)
      elseif key == Input.Pause then
        enterPause()
      end
      return
    end

    -- now enum is either LockDelaying or Moving
    local moved = false
    if key == Input.SoftDrop then
      pressing[key] = true
    elseif key == Input.Left or key == Input.Right then
      moved = state.horizMove(key == Input.Left)
      horiz(key, moved)
    elseif key == Input.HardDrop then
      lock()
    elseif key == Input.Pause then
      enterPause()
    elseif key == Input.ClockwiseRotate or key == Input.AntiClockwiseRotate then
      moved = state.rotate(key == Input.ClockwiseRotate)
    elseif key == Input.Hold then
      if state.isHoldable() then
        if state.hold() then
          newTetromino()
        else
          enum = StateEnum.Over
        end
      end
    end

    if moved then checkLockDelay(true) end
  end

  local function keyreleased(key)
    if key == Input.SoftDrop then
      pressing[key] = false
    elseif key == Input.Left or key == Input.Right then
      pressing[key] = false
      local opp = key == Input.Left and Input.Right or Input.Left
      if pressing[opp] then
        horizDirection = opp == Input.Left and -1 or 1
        horizCountdown = config.countARR
      else
        horizDirection = 0
      end
    end
  end

  local function update()
    local level = scorer.info()
    if level >= config.stopLevel then enum = StateEnum.Over end

    if enum == StateEnum.Over then return end

    if enum == StateEnum.Pausing then
      if pauseCountdown == 0 then
        enum = enumBeforePause
      else
        pauseCountdown = pauseCountdown - 1
      end
      return
    end

    if enum == StateEnum.Locking then
      if countdown > 0 then
        countdown = countdown - 1
      elseif state.clear(clearRows) then
        newTetromino()
      else
        enum = StateEnum.Over
      end
      return
    end

    if enum == StateEnum.LockDelaying then
      if horizDirection ~= 0 and horizCountdown == 0 then
        local moved = state.horizMove(horizDirection == -1)
        horiz(Input.Invalid, moved)
        if moved then
          if checkLockDelay(true) then return end
        end
      else
        horizCountdown = horizCountdown - 1
      end

      countdown = countdown - 1
      if countdown <= 0 then lock() end
      return
    end

    -- now enum == StateEnum.Moving
    local horizMoved = false
    if horizDirection ~= 0 and horizCountdown == 0 then
      horizMoved = state.horizMove(horizDirection == -1)
      horiz(Input.Invalid, horizMoved)
    else
      horizCountdown = horizCountdown - 1
    end

    gravityProgress = gravityProgress + config.levelToGravity(level)
    local distance = math.floor(gravityProgress)
    gravityProgress = gravityProgress - distance
    if pressing[Input.SoftDrop] and distance < 1 then distance = 1 end

    distance = state.downMove(distance)
    local DropType = scorer.DropType
    scorer.drop(
      distance,
      pressing[Input.SoftDrop] and DropType.SoftDrop or DropType.Normal
    )
    if horizMoved or distance > 0 then checkLockDelay(horizMoved) end
  end

  -- Renderer protocol (duck typed):
  --   bg()
  --   bgBlank()
  --   text(level, lines, score)
  --   digit(value, alpha)
  --   tetromino([row, col, dir, shape])
  --   ghost(row, col, dir, shape, alpha)
  --   blank(row, col, dir, shape)
  --   zone(firstRow, lastRow, progress)
  --   awardTetris()
  --   awardTSpin(spin)
  --   hold(shape)
  --   preview(index, shape)
  --   matrix(matrix) -- matrix is read-only to the renderer
  local function draw(renderer)
    if enum == StateEnum.Over then
      renderer.bgBlank()
      renderer.text(scorer.info())
      return
    end

    renderer.bg()
    renderer.text(scorer.info())
    if enum == StateEnum.Pausing then
      if pauseCountdown > 0 then
        local i, f = modf((pauseCountdown - 1) * 3 / config.countPause)
        renderer.digit(i + 1, f)
      end
      return
    end

    if enum == StateEnum.Locking then
      local rows = #clearRows
      renderer.tetromino()
      if rows == 0 then
        renderer.blank(state.tetromino())
      else
        local colNum = config.colNumber
        local progress = (1 - countdown / config.countClear) * (colNum + 1)
        if progress > colNum then progress = colNum end
        local head = clearRows[1]
        local last = head
        for i = 2, #clearRows + 1 do
          if last + 1 == clearRows[i] then
            last = last + 1
          else
            renderer.zone(head, last, progress)
            head = clearRows[i]
            last = head
          end
        end

        if rows == 4 then
          renderer.awardTetris()
        else
          renderer.awardTSpin(state.recentSpin())
        end
      end
    else
      local row, col, dir, shape = state.tetromino()
      if enum == StateEnum.Moving then
        renderer.tetromino(row, col, dir, shape)
        renderer.ghost(row - state.ghostDown(), col, dir, shape, 0.2)
      else
        renderer.tetromino()
        local i, f = modf((countdown - 1) / config.countLockDelay)
        renderer.ghost(row, col, dir, shape, f / 2 + 0.5)
      end
    end

    renderer.hold(state.holding())
    local preview = config.seenPreview
    for i, pre in state.preview() do
      if i > preview then break end
      renderer.preview(i, pre)
    end

    renderer.matrix(state.matrix())
  end

  return {
    keypressed = keypressed,
    keyreleased = keyreleased,
    update = update,
    draw = draw,
    Input = Input,
  }
end
