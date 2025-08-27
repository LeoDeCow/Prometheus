#!/usr/bin/env lua

-- Security Test Script for Prometheus Obfuscator
-- This script tests the security measures implemented

print("Testing Prometheus Obfuscator Security Measures...")
print("=" .. string.rep("=", 50))

-- Test 1: Path Validation
print("\n1. Testing Path Validation...")
local Security = require("src.security")

-- Test valid paths
local valid_paths = {
    "test.lua",
    "folder/file.lua",
    "C:\\Users\\test\\file.lua",
    "simple-name.txt",
    "file_with_underscores.md"
}

for _, path in ipairs(valid_paths) do
    local valid, reason = Security.validate_path(path)
    if valid then
        print("✓ Valid path: " .. path)
    else
        print("✗ Invalid path: " .. path .. " - " .. (reason or "Unknown"))
    end
end

-- Test invalid paths
local invalid_paths = {
    "..\\..\\..\\etc\\passwd",  -- Path traversal
    "file//with//slashes.lua",  -- Double slashes
    "file\\\\with\\\\backslashes.lua",  -- Double backslashes
    "file\0with\0nulls.lua",   -- Null bytes
    "CON.lua",                  -- Windows reserved name
    "PRN.txt",                  -- Windows reserved name
    "AUX.cfg",                  -- Windows reserved name
    "NUL.md"                    -- Windows reserved name
}

for _, path in ipairs(invalid_paths) do
    local valid, reason = Security.validate_path(path)
    if not valid then
        print("✓ Blocked dangerous path: " .. path .. " - " .. (reason or "Blocked"))
    else
        print("✗ ALLOWED dangerous path: " .. path .. " - SECURITY ISSUE!")
    end
end

-- Test 2: Filename Validation
print("\n2. Testing Filename Validation...")

-- Test valid filenames
local valid_filenames = {
    "test.lua",
    "config.txt",
    "readme.md",
    "settings.cfg",
    "file.conf"
}

for _, filename in ipairs(valid_filenames) do
    local valid, reason = Security.validate_filename(filename)
    if valid then
        print("✓ Valid filename: " .. filename)
    else
        print("✗ Invalid filename: " .. filename .. " - " .. (reason or "Unknown"))
    end
end

-- Test invalid filenames
local invalid_filenames = {
    "test.exe",     -- Unallowed extension
    "file.bat",     -- Unallowed extension
    "script.sh",    -- Unallowed extension
    "test",         -- No extension
    "test.lua.txt"  -- Multiple extensions
}

for _, filename in ipairs(invalid_filenames) do
    local valid, reason = Security.validate_filename(filename)
    if not valid then
        print("✓ Blocked invalid filename: " .. filename .. " - " .. (reason or "Blocked"))
    else
        print("✗ ALLOWED invalid filename: " .. filename .. " - SECURITY ISSUE!")
    end
end

-- Test 3: String Sanitization
print("\n3. Testing String Sanitization...")

local test_strings = {
    "Normal string",
    "String with \0null\0bytes",
    "String with \1\2\3control\4\5\6chars",
    string.rep("A", 2000),  -- Very long string
    "String with special chars: !@#$%^&*()"
}

for _, str in ipairs(test_strings) do
    local sanitized = Security.sanitize_string(str)
    local original_length = #str
    local sanitized_length = #sanitized
    
    print(string.format("Original: %d chars, Sanitized: %d chars", original_length, sanitized_length))
    if sanitized_length <= 1000 then
        print("✓ Length properly limited")
    else
        print("✗ Length not properly limited - SECURITY ISSUE!")
    end
    
    if sanitized:match("[\0\1-\31]") then
        print("✗ Control characters not removed - SECURITY ISSUE!")
    else
        print("✓ Control characters properly removed")
    end
end

-- Test 4: Sandbox Creation
print("\n4. Testing Sandbox Creation...")

local sandbox = Security.create_sandbox()

-- Test safe functions are available
local safe_functions = {"string", "table", "math", "tonumber", "tostring", "type"}
for _, func_name in ipairs(safe_functions) do
    if sandbox[func_name] then
        print("✓ Safe function available: " .. func_name)
    else
        print("✗ Safe function not available: " .. func_name .. " - SECURITY ISSUE!")
    end
end

-- Test dangerous functions are blocked
local dangerous_functions = {"load", "loadstring", "dofile", "require", "os", "io", "debug", "_G"}
for _, func_name in ipairs(dangerous_functions) do
    if not sandbox[func_name] then
        print("✓ Dangerous function blocked: " .. func_name)
    else
        print("✗ Dangerous function NOT blocked: " .. func_name .. " - SECURITY ISSUE!")
    end
end

-- Test 5: CLI Argument Validation
print("\n5. Testing CLI Argument Validation...")

-- Test valid CLI arguments
local valid_cli_args = {
    "--preset", "--p",
    "--config", "--c",
    "--out", "--o",
    "--nocolors",
    "--Lua51",
    "--LuaU",
    "--pretty",
    "--saveerrors",
    "test.lua"  -- Filename argument
}

for _, arg in ipairs(valid_cli_args) do
    local valid = Security.validate_cli_arg(arg)
    if valid then
        print("✓ Valid CLI argument: " .. arg)
    else
        print("✗ Invalid CLI argument: " .. arg .. " - SECURITY ISSUE!")
    end
end

-- Test invalid CLI arguments
local invalid_cli_args = {
    "--malicious",
    "--inject",
    "..\\..\\..\\etc\\passwd",
    "file\0with\0nulls.lua",
    "CON.lua"
}

for _, arg in ipairs(invalid_cli_args) do
    local valid = Security.validate_cli_arg(arg)
    if not valid then
        print("✓ Blocked invalid CLI argument: " .. arg)
    else
        print("✗ ALLOWED invalid CLI argument: " .. arg .. " - SECURITY ISSUE!")
    end
end

print("\n" .. "=" .. string.rep("=", 50))
print("Security testing completed!")
print("Review the results above to ensure all security measures are working correctly.")