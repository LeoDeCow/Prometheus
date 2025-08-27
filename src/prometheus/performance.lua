-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- performance.lua
-- This file provides performance monitoring utilities

local logger = require("logger");
local config = require("config");

local Performance = {};

-- Performance timer
local function getTime()
	if package and package.config and type(package.config) == "string" and package.config:sub(1,1) == "\\" then
		return os.clock(); -- Windows
	else
		return os.time(); -- Unix-like systems
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

-- Performance profiler
Performance.Profiler = {
	startTime = 0,
	endTime = 0,
	memoryStart = 0,
	memoryEnd = 0,
	checkpoints = {},
	enabled = config.EnableProfiling,
};

function Performance.Profiler:start()
	if not self.enabled then return; end
	
	self.startTime = getTime();
	self.memoryStart = getMemoryUsage();
	self.checkpoints = {};
	
	logger:debug("Performance profiling started");
end

function Performance.Profiler:checkpoint(name)
	if not self.enabled then return; end
	
	local currentTime = getTime();
	local currentMemory = getMemoryUsage();
	
	table.insert(self.checkpoints, {
		name = name,
		time = currentTime,
		memory = currentMemory,
		timestamp = os.time(),
	});
	
	logger:debug(string.format("Checkpoint '%s': %.3fs, %d bytes", 
		name, currentTime - self.startTime, currentMemory));
end

function Performance.Profiler:stop()
	if not self.enabled then return; end
	
	self.endTime = getTime();
	self.memoryEnd = getMemoryUsage();
	
	logger:debug("Performance profiling stopped");
end

function Performance.Profiler:getResults()
	if not self.enabled then return nil; end
	
	local totalTime = self.endTime - self.startTime;
	local totalMemory = self.memoryEnd - self.memoryStart;
	
	local results = {
		totalTime = totalTime,
		totalMemory = totalMemory,
		peakMemory = self.memoryEnd,
		checkpoints = self.checkpoints,
		startTime = self.startTime,
		endTime = self.endTime,
	};
	
	return results;
end

function Performance.Profiler:printResults()
	if not self.enabled then return; end
	
	local results = self:getResults();
	if not results then return; end
	
	print("=== Performance Report ===");
	print(string.format("Total Time: %.3f seconds", results.totalTime));
	print(string.format("Memory Usage: %d bytes (%.2f MB)", 
		results.totalMemory, results.totalMemory / (1024 * 1024)));
	print(string.format("Peak Memory: %d bytes (%.2f MB)", 
		results.peakMemory, results.peakMemory / (1024 * 1024)));
	
	if #results.checkpoints > 0 then
		print("\nCheckpoints:");
		for i, checkpoint in ipairs(results.checkpoints) do
			local timeDiff = checkpoint.time - self.startTime;
			print(string.format("  %s: %.3fs, %d bytes", 
				checkpoint.name, timeDiff, checkpoint.memory));
		end
	end
	
	print("========================");
end

-- Performance monitor for individual operations
Performance.Monitor = {};

function Performance.Monitor:new(name)
	local monitor = {
		name = name,
		startTime = 0,
		endTime = 0,
		memoryStart = 0,
		memoryEnd = 0,
		enabled = config.EnableProfiling,
	};
	
	setmetatable(monitor, self);
	self.__index = self;
	
	return monitor;
end

function Performance.Monitor:start()
	if not self.enabled then return; end
	
	self.startTime = getTime();
	self.memoryStart = getMemoryUsage();
	
	logger:debug(string.format("Monitor '%s' started", self.name));
end

function Performance.Monitor:stop()
	if not self.enabled then return; end
	
	self.endTime = getTime();
	self.memoryEnd = getMemoryUsage();
	
	local duration = self.endTime - self.startTime;
	local memoryUsed = self.memoryEnd - self.memoryStart;
	
	logger:debug(string.format("Monitor '%s' stopped: %.3fs, %d bytes", 
		self.name, duration, memoryUsed));
	
	return {
		duration = duration,
		memoryUsed = memoryUsed,
		peakMemory = self.memoryEnd,
	};
end

-- Performance decorator for functions
function Performance.timed(name, func)
	return function(...)
		local monitor = Performance.Monitor:new(name);
		monitor:start();
		
		local success, result = pcall(func, ...);
		
		monitor:stop();
		
		if not success then
			error(result);
		end
		
		return result;
	end;
end

-- Memory usage tracker
Performance.MemoryTracker = {
	usage = {},
	maxUsage = 0,
	enabled = config.EnableStatistics,
};

function Performance.MemoryTracker:track()
	if not self.enabled then return; end
	
	local currentUsage = getMemoryUsage();
	table.insert(self.usage, {
		usage = currentUsage,
		timestamp = os.time(),
	});
	
	if currentUsage > self.maxUsage then
		self.maxUsage = currentUsage;
	end
end

function Performance.MemoryTracker:getStats()
	if not self.enabled then return nil; end
	
	local totalUsage = 0;
	local count = #self.usage;
	
	for _, entry in ipairs(self.usage) do
		totalUsage = totalUsage + entry.usage;
	end
	
	return {
		averageUsage = count > 0 and totalUsage / count or 0,
		maxUsage = self.maxUsage,
		minUsage = count > 0 and math.min(unpack(self.usage)) or 0,
		totalSamples = count,
	};
end

function Performance.MemoryTracker:reset()
	self.usage = {};
	self.maxUsage = 0;
end

-- Performance optimization utilities
Performance.Optimizer = {};

-- Batch processing for large datasets
function Performance.Optimizer.batchProcess(items, processor, batchSize)
	batchSize = batchSize or 1000;
	local results = {};
	
	for i = 1, #items, batchSize do
		local batch = {};
		local endIndex = math.min(i + batchSize - 1, #items);
		
		for j = i, endIndex do
			table.insert(batch, items[j]);
		end
		
		local batchResults = processor(batch);
		for _, result in ipairs(batchResults) do
			table.insert(results, result);
		end
		
		-- Force garbage collection between batches
		if collectgarbage then
			collectgarbage("collect");
		end
	end
	
	return results;
end

-- Memory-efficient string processing
function Performance.Optimizer.processStringInChunks(str, chunkSize, processor)
	chunkSize = chunkSize or 8192; -- 8KB chunks
	local result = "";
	
	for i = 1, #str, chunkSize do
		local chunk = str:sub(i, i + chunkSize - 1);
		local processedChunk = processor(chunk);
		result = result .. processedChunk;
		
		-- Force garbage collection every few chunks
		if i % (chunkSize * 4) == 0 and collectgarbage then
			collectgarbage("collect");
		end
	end
	
	return result;
end

-- Cache management
Performance.Cache = {
	data = {},
	maxSize = 1000,
	enabled = true,
};

function Performance.Cache:get(key)
	if not self.enabled then return nil; end
	return self.data[key];
end

function Performance.Cache:set(key, value)
	if not self.enabled then return; end
	
	-- Simple LRU eviction
	if #self.data >= self.maxSize then
		local oldestKey = next(self.data);
		self.data[oldestKey] = nil;
	end
	
	self.data[key] = value;
end

function Performance.Cache:clear()
	self.data = {};
end

function Performance.Cache:getStats()
	return {
		size = #self.data,
		maxSize = self.maxSize,
		usage = (#self.data / self.maxSize) * 100,
	};
end

-- Performance reporting
function Performance.generateReport()
	local report = {
		timestamp = os.time(),
		profiler = Performance.Profiler:getResults(),
		memory = Performance.MemoryTracker:getStats(),
		cache = Performance.Cache:getStats(),
	};
	
	return report;
end

function Performance.printReport()
	local report = Performance.generateReport();
	
	print("=== Performance Report ===");
	print(string.format("Generated: %s", os.date("%Y-%m-%d %H:%M:%S", report.timestamp)));
	
	if report.profiler then
		print(string.format("Total Time: %.3f seconds", report.profiler.totalTime));
		print(string.format("Peak Memory: %d bytes (%.2f MB)", 
			report.profiler.peakMemory, report.profiler.peakMemory / (1024 * 1024)));
	end
	
	if report.memory then
		print(string.format("Average Memory: %d bytes (%.2f MB)", 
			report.memory.averageUsage, report.memory.averageUsage / (1024 * 1024)));
		print(string.format("Memory Samples: %d", report.memory.totalSamples));
	end
	
	if report.cache then
		print(string.format("Cache Usage: %d/%d (%.1f%%)", 
			report.cache.size, report.cache.maxSize, report.cache.usage));
	end
	
	print("========================");
end

return Performance;