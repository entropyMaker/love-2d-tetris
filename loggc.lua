-- if requiring this file returns true, everytime gc enters finalize phase
-- (which means a gc cycle is going to finish or lua exit), a log is printed.
-- luajit, lua5.2, lua5.3, lua5.4, lua5.5 are supported

local stderr = require("io").stderr
local date = require("os").date

local newobj
local function gc()
  -- NOTE `collectgarbage` is not allowed to be called in a finalizer,
  -- so do not try to print something like `collectgarbage("count")`
  stderr:write("[" .. date("%F %T") .. "] finalizer is called\n")
  newobj()
end
local mt = { __gc = gc }

local v = tonumber(_VERSION:match("^Lua 5%.(%d)$"))
if v == 2 or v == 3 or v == 4 or v == 5 then
  -- 5.2, 5.3, 5.4, 5.5
  local setmt = setmetatable
  newobj = function() setmt({}, mt) end
else
  local hasffi, ffi = pcall(require, "ffi")
  if not hasffi then return false end
  -- luajit ffi, use a anonynous C struct
  newobj = ffi.metatype("struct {}", mt)
end

newobj()
return true
