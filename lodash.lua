local function fill(val, n1, n2)
  local t = {}
  if n2 == nil then
    for i = 1, n1 do
      t[i] = val
    end
    return t
  end

  for i = 1, n1 do
    local row = {}
    t[i] = row
    for j = 1, n2 do
      row[j] = val
    end
  end
  return t
end

local function pick(source, fields)
  local res = {}
  for i = 1, #fields do
    res[fields[i]] = source[fields[i]]
  end
  return setmetatable(res, getmetatable(source))
end

local E = setmetatable(
  {},
  { __newindex = function() error("this is a frozen table") end }
)

return {
  fill = fill,
  pick = pick,
  E = E,
}
