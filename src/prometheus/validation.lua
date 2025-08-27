-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- validation.lua
-- This file provides validation utilities for the Prometheus obfuscator

local logger = require("logger");
local config = require("config");

local Validation = {};

-- File validation
function Validation.validateFile(filePath, options)
	options = options or {};
	
	if not filePath or type(filePath) ~= "string" then
		return false, "File path must be a non-empty string";
	end
	
	if #filePath == 0 then
		return false, "File path cannot be empty";
	end
	
	-- Check if file exists
	local file = io.open(filePath, "rb");
	if not file then
		return false, string.format("File '%s' does not exist or is not readable", filePath);
	end
	
	-- Check file size
	local size = file:seek("end");
	file:close();
	
	if size > config.MaxFileSize then
		return false, string.format("File '%s' is too large (%d bytes, max: %d bytes)", 
			filePath, size, config.MaxFileSize);
	end
	
	if size == 0 and not config.AllowEmptyFiles then
		return false, string.format("File '%s' is empty", filePath);
	end
	
	return true;
end

-- Code validation
function Validation.validateCode(code, options)
	options = options or {};
	
	if not code or type(code) ~= "string" then
		return false, "Code must be a non-empty string";
	end
	
	if #code == 0 then
		return false, "Code cannot be empty";
	end
	
	if #code > config.MaxStringLength then
		return false, string.format("Code is too long (%d characters, max: %d)", 
			#code, config.MaxStringLength);
	end
	
	-- Check for suspicious patterns
	local suspiciousPatterns = {
		"os%.execute",
		"io%.popen",
		"loadstring",
		"dofile",
		"loadfile",
		"require%(\"os\"%)",
		"require%(\"io\"%)",
	};
	
	if options.checkSecurity then
		for _, pattern in ipairs(suspiciousPatterns) do
			if code:match(pattern) then
				logger:warn(string.format("Code contains potentially dangerous pattern: %s", pattern));
			end
		end
	end
	
	return true;
end

-- Configuration validation
function Validation.validateConfig(config, options)
	options = options or {};
	
	if not config or type(config) ~= "table" then
		return false, "Configuration must be a table";
	end
	
	-- Validate Lua version
	if config.LuaVersion then
		local validVersions = {"Lua51", "LuaU"};
		local isValid = false;
		for _, version in ipairs(validVersions) do
			if config.LuaVersion == version then
				isValid = true;
				break;
			end
		end
		if not isValid then
			return false, string.format("Invalid Lua version: %s (valid: %s)", 
				config.LuaVersion, table.concat(validVersions, ", "));
		end
	end
	
	-- Validate steps
	if config.Steps then
		if type(config.Steps) ~= "table" then
			return false, "Steps must be a table";
		end
		
		for i, step in ipairs(config.Steps) do
			if type(step) ~= "table" then
				return false, string.format("Step %d must be a table", i);
			end
			
			if not step.Name or type(step.Name) ~= "string" then
				return false, string.format("Step %d must have a valid Name", i);
			end
			
			if step.Settings and type(step.Settings) ~= "table" then
				return false, string.format("Step %d settings must be a table", i);
			end
		end
	end
	
	-- Validate other settings
	if config.Seed and type(config.Seed) ~= "number" then
		return false, "Seed must be a number";
	end
	
	if config.VarNamePrefix and type(config.VarNamePrefix) ~= "string" then
		return false, "VarNamePrefix must be a string";
	end
	
	if config.PrettyPrint and type(config.PrettyPrint) ~= "boolean" then
		return false, "PrettyPrint must be a boolean";
	end
	
	return true;
end

-- Output path validation
function Validation.validateOutputPath(outputPath, inputPath)
	if not outputPath or type(outputPath) ~= "string" then
		return false, "Output path must be a non-empty string";
	end
	
	if #outputPath == 0 then
		return false, "Output path cannot be empty";
	end
	
	-- Check if output directory exists
	local outputDir = outputPath:match("(.*[/%\\])");
	if outputDir then
		local dir = io.open(outputDir, "r");
		if not dir then
			return false, string.format("Output directory '%s' does not exist", outputDir);
		end
		dir:close();
	end
	
	-- Check if output file is writable
	local testFile = io.open(outputPath, "w");
	if not testFile then
		return false, string.format("Cannot write to output file '%s'", outputPath);
	end
	testFile:close();
	
	-- Remove test file if it was created
	os.remove(outputPath);
	
	return true;
end

-- Preset validation
function Validation.validatePreset(presetName, availablePresets)
	if not presetName or type(presetName) ~= "string" then
		return false, "Preset name must be a non-empty string";
	end
	
	if not availablePresets[presetName] then
		local validPresets = {};
		for name, _ in pairs(availablePresets) do
			table.insert(validPresets, name);
		end
		return false, string.format("Invalid preset '%s' (valid: %s)", 
			presetName, table.concat(validPresets, ", "));
	end
	
	return true;
end

-- Memory usage validation
function Validation.checkMemoryUsage(currentUsage, limit)
	limit = limit or config.DefaultMemoryLimit;
	
	if currentUsage > limit then
		return false, string.format("Memory usage exceeded limit (%d bytes > %d bytes)", 
			currentUsage, limit);
	end
	
	if currentUsage > limit * 0.8 then
		logger:warn(string.format("Memory usage is high (%d bytes, %d%% of limit)", 
			currentUsage, math.floor((currentUsage / limit) * 100)));
	end
	
	return true;
end

-- Performance validation
function Validation.validatePerformance(startTime, maxDuration)
	maxDuration = maxDuration or 300; -- 5 minutes default
	
	local currentTime = os.time();
	local elapsed = currentTime - startTime;
	
	if elapsed > maxDuration then
		return false, string.format("Operation took too long (%d seconds > %d seconds)", 
			elapsed, maxDuration);
	end
	
	return true;
end

-- String sanitization
function Validation.sanitizeString(str, maxLength)
	maxLength = maxLength or config.MaxStringLength;
	
	if not str or type(str) ~= "string" then
		return "";
	end
	
	if #str > maxLength then
		return str:sub(1, maxLength);
	end
	
	-- Remove null bytes and other problematic characters
	str = str:gsub("%z", ""); -- Remove null bytes
	str = str:gsub("[\1-\8\11\12\14-\31]", ""); -- Remove control characters except tab, newline, form feed
	
	return str;
end

-- Error collection and reporting
Validation.ErrorCollector = {
	errors = {},
	warnings = {},
	maxErrors = config.MaxErrorCount,
	maxWarnings = config.MaxErrorCount * 2,
};

function Validation.ErrorCollector:addError(message, context)
	if #self.errors >= self.maxErrors then
		return false, "Maximum error count reached";
	end
	
	table.insert(self.errors, {
		message = message,
		context = context,
		timestamp = os.time(),
	});
	
	return true;
end

function Validation.ErrorCollector:addWarning(message, context)
	if #self.warnings >= self.maxWarnings then
		return false, "Maximum warning count reached";
	end
	
	table.insert(self.warnings, {
		message = message,
		context = context,
		timestamp = os.time(),
	});
	
	return true;
end

function Validation.ErrorCollector:getErrors()
	return self.errors;
end

function Validation.ErrorCollector:getWarnings()
	return self.warnings;
end

function Validation.ErrorCollector:clear()
	self.errors = {};
	self.warnings = {};
end

function Validation.ErrorCollector:hasErrors()
	return #self.errors > 0;
end

function Validation.ErrorCollector:hasWarnings()
	return #self.warnings > 0;
end

return Validation;