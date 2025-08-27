-- Example script to demonstrate Prometheus obfuscator improvements
-- This script shows various Lua features that can be obfuscated

local function fibonacci(n)
    if n <= 1 then
        return n
    end
    return fibonacci(n - 1) + fibonacci(n - 2)
end

local function greet(name, age)
    local message = "Hello, " .. name .. "! You are " .. age .. " years old."
    print(message)
    return message
end

local function calculateArea(width, height)
    local area = width * height
    local perimeter = 2 * (width + height)
    return {
        area = area,
        perimeter = perimeter,
        isSquare = width == height
    }
end

-- String literals that will be encrypted
local secretKey = "my-super-secret-key-12345"
local apiEndpoint = "https://api.example.com/v1/data"
local errorMessage = "An error occurred while processing your request"

-- Numbers that can be converted to expressions
local magicNumber = 42
local maxRetries = 3
local timeout = 5000

-- Arrays and tables
local colors = {"red", "green", "blue", "yellow", "purple"}
local config = {
    debug = true,
    version = "1.0.0",
    features = {
        encryption = true,
        compression = false,
        caching = true
    }
}

-- Main execution
print("=== Prometheus Obfuscator Example ===")

-- Test functions
local result = fibonacci(10)
print("Fibonacci(10) =", result)

greet("Alice", 25)

local rectangle = calculateArea(10, 5)
print("Rectangle area:", rectangle.area)
print("Rectangle perimeter:", rectangle.perimeter)
print("Is square:", rectangle.isSquare)

-- Test array access
for i, color in ipairs(colors) do
    print("Color", i, ":", color)
end

-- Test table access
print("Config version:", config.version)
print("Debug mode:", config.debug)
print("Encryption enabled:", config.features.encryption)

-- Conditional logic
if magicNumber > 40 then
    print("Magic number is greater than 40")
else
    print("Magic number is 40 or less")
end

-- Loop with multiple conditions
for i = 1, maxRetries do
    if i == 1 then
        print("First attempt")
    elseif i == maxRetries then
        print("Final attempt")
    else
        print("Attempt", i)
    end
end

-- Error handling example
local success, error = pcall(function()
    if timeout > 10000 then
        error("Timeout too high")
    end
    print("Operation completed successfully")
end)

if not success then
    print("Error:", error)
end

print("=== Example completed ===")