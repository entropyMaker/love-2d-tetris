local testTetromino = require("unittest.tetromino")

local function run()
  local funcCnt, caseCnt = 0, 0
  for name, func in pairs(testTetromino) do
    local res = func()
    if type(res) == "string" then
      print(name .. " failed: " .. res)
      os.exit(1)
    end
    funcCnt = funcCnt + 1
    caseCnt = caseCnt + res
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
