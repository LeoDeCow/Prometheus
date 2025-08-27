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
Prometheus.Logger.logLevel = Prometheus.Logger.LogLevel.Info;

-- Check if the file exists
local function file_exists(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end

string.split = function(str, sep)
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

-- Help function
local function show_help()
    print(Prometheus.colors(Prometheus.Config.NameAndVersion, "cyan"))
    print("Usage: lua cli.lua [options] <input_file>")
    print()
    print("Options:")
    print("  --preset, -p <name>        Use a predefined obfuscation preset")
    print("                             Available presets: " .. table.concat(util.keys(Prometheus.Presets), ", "))
    print("  --config, -c <file>        Use a custom configuration file")
    print("  --out, -o <file>           Specify output file (default: <input>.obfuscated.lua)")
    print("  --nocolors                 Disable colored output")
    print("  --Lua51                    Target Lua 5.1")
    print("  --LuaU                     Target Roblox LuaU")
    print("  --pretty                   Enable pretty printing")
    print("  --saveerrors               Save error messages to file")
    print("  --help, -h                 Show this help message")
    print("  --version                  Show version information")
    print()
    print("Examples:")
    print("  lua cli.lua --preset Medium script.lua")
    print("  lua cli.lua --config myconfig.lua --out result.lua script.lua")
    print("  lua cli.lua --Lua51 --pretty script.lua")
end

-- Version function
local function show_version()
    print(Prometheus.Config.NameAndVersion)
    print("Revision: " .. Prometheus.Config.Revision)
    print("Author: " .. Prometheus.Config.Author or "levno-710")
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
    if curr:sub(1, 2) == "--" then
        if curr == "--preset" or curr == "-p" then
            if config then
                Prometheus.Logger:warn("The config was set multiple times");
            end

            i = i + 1;
            if i > #arg then
                Prometheus.Logger:error("Missing preset name after --preset");
            end
            
            local preset = Prometheus.Presets[arg[i]];
            if not preset then
                Prometheus.Logger:error(string.format("A Preset with the name \"%s\" was not found!", tostring(arg[i])));
            end

            config = preset;
        elseif curr == "--config" or curr == "-c" then
            i = i + 1;
            if i > #arg then
                Prometheus.Logger:error("Missing config file path after --config");
            end
            
            local filename = tostring(arg[i]);
            if not file_exists(filename) then
                Prometheus.Logger:error(string.format("The config file \"%s\" was not found!", filename));
            end

            local content = table.concat(lines_from(filename), "\n");
            -- Load Config from File with better error handling
            local func, err = loadstring(content);
            if not func then
                Prometheus.Logger:error(string.format("Failed to load config file: %s", err));
            end
            
            -- Sandboxing
            setfenv(func, {});
            local success, result = pcall(func);
            if not success then
                Prometheus.Logger:error(string.format("Failed to execute config file: %s", result));
            end
            config = result;
        elseif curr == "--out" or curr == "-o" then
            i = i + 1;
            if i > #arg then
                Prometheus.Logger:error("Missing output file path after --out");
            end
            
            if(outFile) then
                Prometheus.Logger:warn("The output file was specified multiple times!");
            end
            outFile = arg[i];
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
                local handle = io.open(fileName, "w");
                if handle then
                    handle:write(message);
                    handle:close();
                    print(Prometheus.colors("Error details saved to: " .. fileName, "yellow"));
                end

                os.exit(1);
            end;
        elseif curr == "--help" or curr == "-h" then
            show_help();
            os.exit(0);
        elseif curr == "--version" then
            show_version();
            os.exit(0);
        else
            Prometheus.Logger:warn(string.format("The option \"%s\" is not valid and therefore ignored", curr));
        end
    else
        if sourceFile then
            Prometheus.Logger:error(string.format("Unexpected argument \"%s\"", arg[i]));
        end
        sourceFile = tostring(arg[i]);
    end
    i = i + 1;
end

if not sourceFile then
    Prometheus.Logger:error("No input file was specified! Use --help for usage information.");
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

-- Validate output directory exists
local outputDir = outFile:match("(.*[/%\\])");
if outputDir and not file_exists(outputDir) then
    Prometheus.Logger:error(string.format("Output directory \"%s\" does not exist!", outputDir));
end

local source = table.concat(lines_from(sourceFile), "\n");
if #source == 0 then
    Prometheus.Logger:error("Input file is empty!");
end

local pipeline = Prometheus.Pipeline:fromConfig(config);
local out = pipeline:apply(source, sourceFile);
Prometheus.Logger:info(string.format("Writing output to \"%s\"", outFile));

-- Write Output with error handling
local handle = io.open(outFile, "w");
if not handle then
    Prometheus.Logger:error(string.format("Failed to create output file \"%s\"", outFile));
end

handle:write(out);
handle:close();

Prometheus.Logger:info("Obfuscation completed successfully!");
