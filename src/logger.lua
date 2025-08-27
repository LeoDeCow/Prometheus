-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- logger.lua

local logger = {}
local config = require("config");
local colors = require("colors");

logger.LogLevel = {
	Error = 0,
	Warn = 1,
	Log = 2,
	Info = 2,
	Debug = 3,
	Trace = 4,
}

logger.logLevel = logger.LogLevel.Log;

-- Format timestamp
local function getTimestamp()
	return os.date("%H:%M:%S");
end

-- Format log message with timestamp and level
local function formatMessage(level, ...)
	local args = {...};
	local message = table.concat(args, " ");
	local timestamp = getTimestamp();
	local levelStr = string.upper(level);
	
	return string.format("[%s] %s: %s", timestamp, levelStr, message);
end

logger.debugCallback = function(...)
	print(colors(formatMessage("debug", ...), "grey"));
end;
function logger:debug(...)
	if self.logLevel >= self.LogLevel.Debug then
		self.debugCallback(...);
	end
end

logger.traceCallback = function(...)
	print(colors(formatMessage("trace", ...), "darkgrey"));
end;
function logger:trace(...)
	if self.logLevel >= self.LogLevel.Trace then
		self.traceCallback(...);
	end
end

logger.logCallback = function(...)
	print(colors(config.NameUpper .. ": ", "magenta") .. ...);
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
	print(colors(formatMessage("warn", ...), "yellow"));
end;
function logger:warn(...)
	if self.logLevel >= self.LogLevel.Warn then
		self.warnCallback(...);
	end
end

logger.errorCallback = function(...)
	print(colors(formatMessage("error", ...), "red"));
	error(...);
end;
function logger:error(...)
	self.errorCallback(...);
	error(config.NameUpper .. ": logger.errorCallback did not throw an Error!");
end

-- Set log level by string
function logger:setLogLevel(level)
	if type(level) == "string" then
		level = string.lower(level);
		if level == "error" then
			self.logLevel = self.LogLevel.Error;
		elseif level == "warn" or level == "warning" then
			self.logLevel = self.LogLevel.Warn;
		elseif level == "log" or level == "info" then
			self.logLevel = self.LogLevel.Log;
		elseif level == "debug" then
			self.logLevel = self.LogLevel.Debug;
		elseif level == "trace" then
			self.logLevel = self.LogLevel.Trace;
		else
			self:warn(string.format("Unknown log level: %s, using 'log'", level));
			self.logLevel = self.LogLevel.Log;
		end
	elseif type(level) == "number" then
		self.logLevel = level;
	else
		self:warn("Invalid log level type, using 'log'");
		self.logLevel = self.LogLevel.Log;
	end
end

-- Get current log level as string
function logger:getLogLevel()
	for name, level in pairs(self.LogLevel) do
		if level == self.logLevel then
			return string.lower(name);
		end
	end
	return "unknown";
end

-- Log with custom level
function logger:logLevel(level, ...)
	if self.logLevel >= level then
		local args = {...};
		local message = table.concat(args, " ");
		print(colors(formatMessage("custom", message), "white"));
	end
end

-- Progress logging
function logger:progress(current, total, message)
	if self.logLevel >= self.LogLevel.Log then
		local percentage = math.floor((current / total) * 100);
		local progressBar = "";
		local barLength = 20;
		local filled = math.floor((percentage / 100) * barLength);
		
		for i = 1, barLength do
			if i <= filled then
				progressBar = progressBar .. "█";
			else
				progressBar = progressBar .. "░";
			end
		end
		
		local progressMessage = string.format("%s [%s] %d%%", message or "Progress", progressBar, percentage);
		print(colors(progressMessage, "cyan"));
	end
end

return logger;