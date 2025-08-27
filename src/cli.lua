-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- cli.lua
-- This script contains the Code for the Prometheus CLI

-- Configure package.path for requiring Prometheus
local function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)
	return str:match("(.*[/%\\])")
end
package.path = script_path() .. "?.lua;" .. package.path;
---@diagnostic disable-next-line: different-requires
local Prometheus = require("prometheus");
local Security = require("security");
Prometheus.Logger.logLevel = Prometheus.Logger.LogLevel.Info;

-- Check if the file exists
local function file_exists(file)
    if not Security.validate_filename(file) then
        return false
    end
    
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end

string.split = function(str, sep)
    if not str or type(str) ~= "string" or not sep or type(sep) ~= "string" then
        return {}
    end
    
    local fields = {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

-- get all lines from a file, returns an empty
-- list/table if the file does not exist
local function lines_from(file)
    if not file_exists(file) then return {} end
    local lines = {}
    for line in io.lines(file) do
      lines[#lines + 1] = line
    end
    return lines
  end

-- CLI
local config;
local sourceFile;
local outFile;
local luaVersion;
local prettyPrint;

Prometheus.colors.enabled = true;

-- Parse Arguments
local i = 1;
while i <= #arg do
    local curr = arg[i];
    if not curr or type(curr) ~= "string" then
        i = i + 1;
        goto continue;
    end
    
    if curr:sub(1, 2) == "--" then
        if curr == "--preset" or curr == "--p" then
            if config then
                Prometheus.Logger:warn("The config was set multiple times");
            end

            i = i + 1;
            local preset_name = arg[i];
            if not preset_name or type(preset_name) ~= "string" then
                Prometheus.Logger:error("Invalid preset name provided");
            end
            
            local preset = Prometheus.Presets[preset_name];
            if not preset then
                Prometheus.Logger:error(string.format("A Preset with the name \"%s\" was not found!", tostring(preset_name)));
            end

            config = preset;
        elseif curr == "--config" or curr == "--c" then
            i = i + 1;
            local filename = tostring(arg[i]);
            if not filename or not Security.validate_filename(filename) then
                Prometheus.Logger:error("Invalid config filename provided");
            end
            
            if not file_exists(filename) then
                Prometheus.Logger:error(string.format("The config file \"%s\" was not found!", filename));
            end

            local content = table.concat(lines_from(filename), "\n");
            
            -- Security: Use security module for safer configuration loading
            local func, err = loadstring(content);
            if not func then
                Prometheus.Logger:error(string.format("Failed to load config file: %s", err or "Unknown error"));
            end
            
            -- Create secure sandbox environment using security module
            local sandbox = Security.create_sandbox();
            
            -- Set the function environment to the sandbox
            setfenv(func, sandbox);
            
            -- Execute in protected mode
            local success, result = pcall(func);
            if not success then
                Prometheus.Logger:error(string.format("Failed to execute config file: %s", result or "Unknown error"));
            end
            
            config = result;
        elseif curr == "--out" or curr == "--o" then
            i = i + 1;
            if(outFile) then
                Prometheus.Logger:warn("The output file was specified multiple times!");
            end
            local output_file = arg[i];
            if not output_file or not Security.validate_filename(output_file) then
                Prometheus.Logger:error("Invalid output filename provided");
            end
            outFile = output_file;
        elseif curr == "--nocolors" then
            Prometheus.colors.enabled = false;
        elseif curr == "--Lua51" then
            luaVersion = "Lua51";
        elseif curr == "--LuaU" then
            luaVersion = "LuaU";
        elseif curr == "--pretty" then
            prettyPrint = true;
        elseif curr == "--saveerrors" then
            -- Override error callback
            Prometheus.Logger.errorCallback =  function(...)
                print(Prometheus.colors(Prometheus.Config.NameUpper .. ": " .. ..., "red"))
                
                local args = {...};
                local message = table.concat(args, " ");
                
                local fileName = sourceFile:sub(-4) == ".lua" and sourceFile:sub(0, -5) .. ".error.txt" or sourceFile .. ".error.txt";
                
                -- Security: Use security module for error filename validation
                if not Security.validate_filename(fileName) then
                    fileName = "error.txt"; -- Fallback to safe filename
                end
                
                local handle = io.open(fileName, "w");
                if handle then
                    handle:write(message);
                    handle:close();
                end

                os.exit(1);
            end;
        else
            Prometheus.Logger:warn(string.format("The option \"%s\" is not valid and therefore ignored", curr));
        end
    else
        if sourceFile then
            Prometheus.Logger:error(string.format("Unexpected argument \"%s\"", arg[i]));
        end
        
        -- Security: Use security module for source file validation
        local source_file = tostring(arg[i]);
        if not Security.validate_filename(source_file) then
            Prometheus.Logger:error("Invalid source filename provided");
        end
        sourceFile = source_file;
    end
    i = i + 1;
    ::continue::
end

if not sourceFile then
    Prometheus.Logger:error("No input file was specified!")
end

if not config then
    Prometheus.Logger:warn("No config was specified, falling back to Minify preset");
    config = Prometheus.Presets.Minify;
end

-- Add Option to override Lua Version
config.LuaVersion = luaVersion or config.LuaVersion;
config.PrettyPrint = prettyPrint ~= nil and prettyPrint or config.PrettyPrint;

if not file_exists(sourceFile) then
    Prometheus.Logger:error(string.format("The File \"%s\" was not found!", sourceFile));
end

if not outFile then
    if sourceFile:sub(-4) == ".lua" then
        outFile = sourceFile:sub(0, -5) .. ".obfuscated.lua";
    else
        outFile = sourceFile .. ".obfuscated.lua";
    end
end

-- Security: Use security module for final output file validation
if not Security.validate_filename(outFile) then
    Prometheus.Logger:error("Invalid output filename generated");
end

local source = table.concat(lines_from(sourceFile), "\n");
local pipeline = Prometheus.Pipeline:fromConfig(config);
local out = pipeline:apply(source, sourceFile);
Prometheus.Logger:info(string.format("Writing output to \"%s\"", outFile));

-- Security: Use security module for secure file writing
local success, err = Security.secure_file_write(outFile, out);
if not success then
    Prometheus.Logger:error(string.format("Failed to write output file: %s", err or "Unknown error"));
end
