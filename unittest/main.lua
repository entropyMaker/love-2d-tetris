local suites = {
  (require("unittest.tetromino")),
  (require("unittest.gameState")),
  (require("unittest.gameController")),
  (require("unittest.controllerConfig")),
  (require("unittest.guidelineScoreCalc")),
}

local function run()
  local funcCnt, caseCnt = 0, 0
  for _, suite in ipairs(suites) do
    for name, func in pairs(suite) do
      local res = func()
      if type(res) == "string" then
        print(name .. " failed: " .. res)
        os.exit(1)
      end
      funcCnt = funcCnt + 1
      caseCnt = caseCnt + res
    end
  end
  print(
    string.format(
      "all tests passed, %d test cases in %d tests",
      caseCnt,
      funcCnt
    )
  )
end

return run
