-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- logger.lua

local logger = {}
local config = require("config");
local colors = require("colors");
local Security = require("security");

logger.LogLevel = {
	Error = 0,
	Warn = 1,
	Log = 2,
	Info = 2,
	Debug = 3,
}

logger.logLevel = logger.LogLevel.Log;

logger.debugCallback = function(...)
	local sanitized = Security.sanitize_string(...)
	print(colors(config.NameUpper .. ": " ..  sanitized, "grey"));
end;
function logger:debug(...)
	if self.logLevel >= self.LogLevel.Debug then
		self.debugCallback(...);
	end
end

logger.logCallback = function(...)
	local sanitized = Security.sanitize_string(...)
	print(colors(config.NameUpper .. ": ", "magenta") .. sanitized);
end;
function logger:log(...)
	if self.logLevel >= self.LogLevel.Log then
		self.logCallback(...);
	end
end

function logger:info(...)
	if self.logLevel >= self.LogLevel.Log then
		self.logCallback(...);
	end
end

logger.warnCallback = function(...)
	local sanitized = Security.sanitize_string(...)
	print(colors(config.NameUpper .. ": " .. sanitized, "yellow"));
end;
function logger:warn(...)
	if self.logLevel >= self.LogLevel.Warn then
		self.warnCallback(...);
	end
end

logger.errorCallback = function(...)
	local sanitized = Security.sanitize_string(...)
	print(colors(config.NameUpper .. ": " .. sanitized, "red"))
	error(sanitized);
end;
function logger:error(...)
	self.errorCallback(...);
	error(config.NameUpper .. ": logger.errorCallback did not throw an Error!");
end


return logger;