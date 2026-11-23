-- Spider navigation test fixture.

local myVariableName = "camelCase"
local HTTPResponseCode = 200
local snake_case_value = "snake_case"

local function calculateTotalPrice(itemCount, unitPrice)
  local totalAmount = itemCount * unitPrice
  return totalAmount
end

-- Punctuation navigation.
local result = string.find("example123", "%d") and calculateTotalPrice(2, 50)

return {
  myVariableName = myVariableName,
  HTTPResponseCode = HTTPResponseCode,
  snake_case_value = snake_case_value,
  result = result,
}
