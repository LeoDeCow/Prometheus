-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- pipeline.lua
--
-- This Script Provides a Configurable Obfuscation Pipeline that can obfuscate code using different Modules
-- These Modules can simply be added to the pipeline

local config = require("config");
local Ast    = require("prometheus.ast");
local Enums  = require("prometheus.enums");
local util = require("prometheus.util");
local Parser = require("prometheus.parser");
local Unparser = require("prometheus.unparser");
local logger = require("logger");

local NameGenerators = require("prometheus.namegenerators");

local Steps = require("prometheus.steps");

local lookupify = util.lookupify;
local LuaVersion = Enums.LuaVersion;
local AstKind = Ast.AstKind;

-- On Windows os.clock can be used. On other Systems os.time must be used for benchmarking
local isWindows = package and package.config and type(package.config) == "string" and package.config:sub(1,1) == "\\";
local function gettime()
	if isWindows then
		return os.clock();
	else
		return os.time();
	end
end

local Pipeline = {
	NameGenerators = NameGenerators;
	Steps = Steps;
	DefaultSettings = {
		LuaVersion = LuaVersion.LuaU; -- The Lua Version to use for the Tokenizer, Parser and Unparser
		PrettyPrint = false; -- Note that Pretty Print is currently not producing Pretty results
		Seed = 0; -- The Seed. 0 or below uses the current time as a seed
		VarNamePrefix = ""; -- The Prefix that every variable will start with
		MaxIterations = 1000; -- Maximum iterations for loops to prevent infinite loops
		MemoryLimit = 100 * 1024 * 1024; -- 100MB memory limit for large files
	}
}

-- Validate configuration
local function validateConfig(config)
	if not config then
		return false, "Configuration is required";
	end
	
	if config.LuaVersion and not Enums.Conventions[config.LuaVersion] then
		return false, string.format("Invalid Lua version: %s", config.LuaVersion);
	end
	
	if config.Steps and type(config.Steps) ~= "table" then
		return false, "Steps must be a table";
	end
	
	if config.VarNamePrefix and type(config.VarNamePrefix) ~= "string" then
		return false, "VarNamePrefix must be a string";
	end
	
	return true;
end

function Pipeline:new(settings)
	settings = settings or {};
	
	local luaVersion = settings.luaVersion or settings.LuaVersion or Pipeline.DefaultSettings.LuaVersion;
	local conventions = Enums.Conventions[luaVersion];
	if(not conventions) then
		logger:error("The Lua Version \"" .. luaVersion 
			.. "\" is not recognised by the Tokenizer! Please use one of the following: \"" .. table.concat(util.keys(Enums.Conventions), "\",\"") .. "\"");
	end
	
	local prettyPrint = settings.PrettyPrint or Pipeline.DefaultSettings.PrettyPrint;
	local prefix = settings.VarNamePrefix or Pipeline.DefaultSettings.VarNamePrefix;
	local seed = settings.Seed or 0;
	local maxIterations = settings.MaxIterations or Pipeline.DefaultSettings.MaxIterations;
	local memoryLimit = settings.MemoryLimit or Pipeline.DefaultSettings.MemoryLimit;
	
	local pipeline = {
		LuaVersion = luaVersion;
		PrettyPrint = prettyPrint;
		VarNamePrefix = prefix;
		Seed = seed;
		MaxIterations = maxIterations;
		MemoryLimit = memoryLimit;
		parser = Parser:new({
			LuaVersion = luaVersion;
		});
		unparser = Unparser:new({
			LuaVersion = luaVersion;
			PrettyPrint = prettyPrint;
			Highlight = settings.Highlight;
		});
		namegenerator = Pipeline.NameGenerators.MangledShuffled;
		conventions = conventions;
		steps = {};
		stats = {
			startTime = 0,
			parseTime = 0,
			stepTimes = {},
			renameTime = 0,
			unparseTime = 0,
			totalTime = 0,
			memoryUsage = 0
		};
	}
	
	setmetatable(pipeline, self);
	self.__index = self;
	
	return pipeline;
end

function Pipeline:fromConfig(config)
	local valid, err = validateConfig(config);
	if not valid then
		logger:error("Invalid configuration: " .. err);
	end
	
	config = config or {};
	local pipeline = Pipeline:new({
		LuaVersion    = config.LuaVersion or LuaVersion.Lua51;
		PrettyPrint   = config.PrettyPrint or false;
		VarNamePrefix = config.VarNamePrefix or "";
		Seed          = config.Seed or 0;
		MaxIterations = config.MaxIterations or Pipeline.DefaultSettings.MaxIterations;
		MemoryLimit   = config.MemoryLimit or Pipeline.DefaultSettings.MemoryLimit;
	});

	pipeline:setNameGenerator(config.NameGenerator or "MangledShuffled")

	-- Add all Steps defined in Config
	local steps = config.Steps or {};
	for i, step in ipairs(steps) do
		if type(step.Name) ~= "string" then
			logger:error("Step.Name must be a String");
		end
		local constructor = pipeline.Steps[step.Name];
		if not constructor then
			logger:error(string.format("The Step \"%s\" was not found!", step.Name));
		end
		
		-- Validate step settings
		if step.Settings and type(step.Settings) ~= "table" then
			logger:error(string.format("Step \"%s\" settings must be a table", step.Name));
		end
		
		pipeline:addStep(constructor:new(step.Settings or {}));
	end

	return pipeline;
end

function Pipeline:addStep(step)
	if not step or type(step) ~= "table" then
		logger:error("Step must be a valid step object");
	end
	
	if not step.apply or type(step.apply) ~= "function" then
		logger:error("Step must have an apply method");
	end
	
	table.insert(self.steps, step);
end

function Pipeline:resetSteps()
	self.steps = {};
end

function Pipeline:getSteps()
	return self.steps;
end

function Pipeline:setOption(name, value)
	if(Pipeline.DefaultSettings[name] ~= nil) then
		self[name] = value;
	else
		logger:error(string.format("\"%s\" is not a valid setting", name));
	end
end

function Pipeline:setLuaVersion(luaVersion)
	local conventions = Enums.Conventions[luaVersion];
	if(not conventions) then
		logger:error("The Lua Version \"" .. luaVersion 
			.. "\" is not recognised by the Tokenizer! Please use one of the following: \"" .. table.concat(util.keys(Enums.Conventions), "\",\"") .. "\"");
	end
	
	self.parser = Parser:new({
		luaVersion = luaVersion;
	});
	self.unparser = Unparser:new({
		luaVersion = luaVersion;
	});
	self.conventions = conventions;
	self.LuaVersion = luaVersion;
end

function Pipeline:getLuaVersion()
	return self.LuaVersion;
end

function Pipeline:setNameGenerator(nameGenerator)
	if(type(nameGenerator) == "string") then
		nameGenerator = Pipeline.NameGenerators[nameGenerator];
	end
	
	if(type(nameGenerator) == "function" or type(nameGenerator) == "table") then
		self.namegenerator = nameGenerator;
		return;
	else
		logger:error("The Argument to Pipeline:setNameGenerator must be a valid NameGenerator function or function name e.g: \"mangled\"")
	end
end

-- Memory usage monitoring
local function getMemoryUsage()
	if collectgarbage then
		collectgarbage("collect");
		return collectgarbage("count") * 1024; -- Convert KB to bytes
	end
	return 0;
end

function Pipeline:apply(code, filename)
	self.stats.startTime = gettime();
	filename = filename or "Anonymous Script";
	
	-- Validate input
	if not code or type(code) ~= "string" then
		logger:error("Code must be a non-empty string");
	end
	
	if #code == 0 then
		logger:error("Code cannot be empty");
	end
	
	logger:info(string.format("Applying Obfuscation Pipeline to %s ...", filename));
	
	-- Seed the Random Generator
	if(self.Seed > 0) then
		math.randomseed(self.Seed);
	else
		math.randomseed(os.time())
	end
	
	-- Monitor memory usage
	self.stats.memoryUsage = getMemoryUsage();
	
	logger:info("Parsing ...");
	local parserStartTime = gettime();

	local sourceLen = string.len(code);
	local ast = self.parser:parse(code);

	self.stats.parseTime = gettime() - parserStartTime;
	logger:info(string.format("Parsing Done in %.2f seconds", self.stats.parseTime));
	
	-- User Defined Steps with better error handling
	for i, step in ipairs(self.steps) do
		local stepStartTime = gettime();
		local stepName = step.Name or "Unnamed";
		logger:info(string.format("Applying Step \"%s\" ...", stepName));
		
		-- Check memory usage
		local currentMemory = getMemoryUsage();
		if currentMemory > self.MemoryLimit then
			logger:error(string.format("Memory limit exceeded (%d bytes) during step \"%s\"", currentMemory, stepName));
		end
		
		local success, newAst = pcall(function()
			return step:apply(ast, self);
		end);
		
		if not success then
			logger:error(string.format("Step \"%s\" failed: %s", stepName, newAst));
		end
		
		if type(newAst) == "table" then
			ast = newAst;
		end
		
		self.stats.stepTimes[stepName] = gettime() - stepStartTime;
		logger:info(string.format("Step \"%s\" Done in %.2f seconds", stepName, self.stats.stepTimes[stepName]));
	end
	
	-- Rename Variables Step
	self:renameVariables(ast);
	
	code = self:unparse(ast);
	
	self.stats.totalTime = gettime() - self.stats.startTime;
	logger:info(string.format("Obfuscation Done in %.2f seconds", self.stats.totalTime));
	
	logger:info(string.format("Generated Code size is %.2f%% of the Source Code size", (string.len(code) / sourceLen)*100))
	
	-- Final memory check
	self.stats.memoryUsage = getMemoryUsage();
	if self.stats.memoryUsage > self.MemoryLimit then
		logger:warn(string.format("Final memory usage (%d bytes) exceeds limit (%d bytes)", self.stats.memoryUsage, self.MemoryLimit));
	end
	
	return code;
end

function Pipeline:unparse(ast)
	local startTime = gettime();
	logger:info("Generating Code ...");
	
	local unparsed = self.unparser:unparse(ast);
	
	self.stats.unparseTime = gettime() - startTime;
	logger:info(string.format("Code Generation Done in %.2f seconds", self.stats.unparseTime));
	
	return unparsed;
end

function Pipeline:renameVariables(ast)
	local startTime = gettime();
	logger:info("Renaming Variables ...");
	
	local generatorFunction = self.namegenerator or Pipeline.NameGenerators.mangled;
	if(type(generatorFunction) == "table") then
		if (type(generatorFunction.prepare) == "function") then
			generatorFunction.prepare(ast);
		end
		generatorFunction = generatorFunction.generateName;
	end
	
	if not self.unparser:isValidIdentifier(self.VarNamePrefix) and #self.VarNamePrefix ~= 0 then
		logger:error(string.format("The Prefix \"%s\" is not a valid Identifier in %s", self.VarNamePrefix, self.LuaVersion));
	end

	local globalScope = ast.globalScope;
	globalScope:renameVariables({
		Keywords = self.conventions.Keywords;
		generateName = generatorFunction;
		prefix = self.VarNamePrefix;
	});
	
	self.stats.renameTime = gettime() - startTime;
	logger:info(string.format("Renaming Done in %.2f seconds", self.stats.renameTime));
end

-- Get pipeline statistics
function Pipeline:getStats()
	return self.stats;
end

-- Reset pipeline statistics
function Pipeline:resetStats()
	self.stats = {
		startTime = 0,
		parseTime = 0,
		stepTimes = {},
		renameTime = 0,
		unparseTime = 0,
		totalTime = 0,
		memoryUsage = 0
	};
end

return Pipeline;
