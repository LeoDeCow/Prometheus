-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- security.lua
-- This file contains security configurations and validation functions

local security = {}

-- Security configuration
security.config = {
    -- Maximum file size allowed (in bytes) - 10MB default
    max_file_size = 10 * 1024 * 1024,
    
    -- Maximum string length for input validation
    max_string_length = 1000,
    
    -- Allowed file extensions
    allowed_extensions = {".lua", ".txt", ".md", ".cfg", ".conf"},
    
    -- Blocked file patterns
    blocked_patterns = {
        "%.%.",
        "//",
        "\\\\",
        "[\0\1-\31]",
        "CON$", "PRN$", "AUX$", "NUL$", "COM%d+$", "LPT%d+$"
    },
    
    -- Safe sandbox functions
    safe_functions = {
        string = string,
        table = table,
        math = math,
        tonumber = tonumber,
        tostring = tostring,
        type = type,
        pairs = pairs,
        ipairs = ipairs,
        next = next,
        select = select,
        unpack = unpack,
    },
    
    -- Blocked functions in sandbox
    blocked_functions = {
        load = true,
        loadstring = true,
        dofile = true,
        require = true,
        package = true,
        os = true,
        io = true,
        debug = true,
        jit = true,
        bit = true,
        ffi = true,
        _G = true,
        _ENV = true,
        getfenv = true,
        setfenv = true,
        getmetatable = true,
        setmetatable = true,
        rawget = true,
        rawset = true,
        rawequal = true,
        rawlen = true,
        collectgarbage = true,
        coroutine = true,
        module = true,
    }
}

-- Validate file path for security
function security.validate_path(path)
    if not path or type(path) ~= "string" then
        return false, "Invalid path type"
    end
    
    -- Check length
    if #path > 260 then -- Windows path limit
        return false, "Path too long"
    end
    
    -- Check for dangerous patterns
    for _, pattern in ipairs(security.config.blocked_patterns) do
        if path:match(pattern) then
            return false, "Path contains dangerous pattern: " .. pattern
        end
    end
    
    -- Check for null bytes and control characters
    if path:match("[\0\1-\31]") then
        return false, "Path contains control characters"
    end
    
    return true
end

-- Validate filename for security
function security.validate_filename(filename)
    local valid, reason = security.validate_path(filename)
    if not valid then
        return false, reason
    end
    
    -- Check file extension
    local has_valid_extension = false
    for _, ext in ipairs(security.config.allowed_extensions) do
        if filename:sub(-#ext) == ext then
            has_valid_extension = true
            break
        end
    end
    
    if not has_valid_extension then
        return false, "File extension not allowed"
    end
    
    return true
end

-- Sanitize input strings
function security.sanitize_string(str)
    if not str or type(str) ~= "string" then
        return ""
    end
    
    -- Remove control characters
    local clean = str:gsub("[\0\1-\31]", "")
    
    -- Limit length
    if #clean > security.config.max_string_length then
        clean = clean:sub(1, security.config.max_string_length) .. "..."
    end
    
    return clean
end

-- Create secure sandbox environment
function security.create_sandbox()
    local sandbox = {}
    
    -- Add safe functions
    for name, func in pairs(security.config.safe_functions) do
        sandbox[name] = func
    end
    
    -- Ensure blocked functions are nil
    for name, _ in pairs(security.config.blocked_functions) do
        sandbox[name] = nil
    end
    
    return sandbox
end

-- Validate file size
function security.validate_file_size(file_path)
    local file = io.open(file_path, "rb")
    if not file then
        return false, "Cannot open file"
    end
    
    local size = file:seek("end")
    file:close()
    
    if size > security.config.max_file_size then
        return false, "File too large: " .. size .. " bytes"
    end
    
    return true
end

-- Secure file read operation
function security.secure_file_read(file_path)
    -- Validate path
    local valid, reason = security.validate_path(file_path)
    if not valid then
        return nil, reason
    end
    
    -- Validate file size
    local size_valid, size_reason = security.validate_file_size(file_path)
    if not size_valid then
        return nil, size_reason
    end
    
    -- Read file safely
    local file = io.open(file_path, "rb")
    if not file then
        return nil, "Cannot open file"
    end
    
    local content = file:read("*a")
    file:close()
    
    return content
end

-- Secure file write operation
function security.secure_file_write(file_path, content)
    -- Validate path
    local valid, reason = security.validate_path(file_path)
    if not valid then
        return false, reason
    end
    
    -- Validate content
    if not content or type(content) ~= "string" then
        return false, "Invalid content type"
    end
    
    -- Check content length
    if #content > security.config.max_file_size then
        return false, "Content too large"
    end
    
    -- Write file safely
    local file = io.open(file_path, "w")
    if not file then
        return false, "Cannot open file for writing"
    end
    
    local success, err = pcall(function()
        file:write(content)
        file:close()
    end)
    
    if not success then
        if file then file:close() end
        return false, "Write failed: " .. (err or "Unknown error")
    end
    
    return true
end

-- Validate command line arguments
function security.validate_cli_arg(arg)
    if not arg or type(arg) ~= "string" then
        return false
    end
    
    -- Only allow safe command line arguments
    local safe_args = {
        "--preset", "--p",
        "--config", "--c", 
        "--out", "--o",
        "--nocolors",
        "--Lua51",
        "--LuaU",
        "--pretty",
        "--saveerrors"
    }
    
    for _, safe_arg in ipairs(safe_args) do
        if arg == safe_arg then
            return true
        end
    end
    
    -- Allow non-flag arguments (filenames)
    if arg:sub(1, 2) ~= "--" then
        return security.validate_filename(arg)
    end
    
    return false
end

return security