local canvas = require("hs.canvas")

local sysMonitorMenubar = hs.menubar.new()
local sysMonitorCanvas = nil

local sysMemSizeInfo = hs.execute("sysctl hw.memsize")
local totalPhysicalMemoryBytes = tonumber(string.match(sysMemSizeInfo, "hw.memsize: %s*(%d+)"))
local totalMemoryMB = totalPhysicalMemoryBytes / 1024 / 1024
local pageSizeKB = 16

local imageHeight = 18
local barWidth = 2
local memBarWidth = 3
local gpuBarWidth = 3
local interBarSpace = 1

local function clickCallback()
	local name = "Activity Monitor"
	hs.application.launchOrFocus(name)
	hs.appfinder.appFromName(name):activate()
end

function update(data)
	local usages
	local numberOfCores = data.n
	-- local numberOfCores = data.n / 2 -- only "real" cores for SMT processors
	local imageWidth = barWidth * numberOfCores + interBarSpace * (numberOfCores + 1) + memBarWidth + gpuBarWidth

	if sysMonitorCanvas == nil then
		-- init canvas only once
		sysMonitorCanvas = canvas.new({
			x = 0,
			y = 0,
			h = imageHeight,
			w = imageWidth,
		})
	end

	-- Get memory stats
	local vmStat = hs.execute("vm_stat")

	local freePages = tonumber(string.match(vmStat, "Pages free:%s*(%d+)"))
	local inactivePages = tonumber(string.match(vmStat, "Pages inactive:%s*(%d+)"))
	local speculativePages = tonumber(string.match(vmStat, "Pages speculative:%s*(%d+)"))
	local wiredPages = tonumber(string.match(vmStat, "Pages wired down:%s*(%d+)"))
	local activePages = tonumber(string.match(vmStat, "Pages active:%s*(%d+)"))
	local compressorOccupiedPages = tonumber(string.match(vmStat, "Pages occupied by compressor:%s*(%d+)"))

	local totalFreeMemoryKB = (freePages + inactivePages + speculativePages) * pageSizeKB
	local totalUsedMemoryKB = (activePages + wiredPages + compressorOccupiedPages) * pageSizeKB

	local totalFreeMemoryMB = totalFreeMemoryKB / 1024
	local totalUsedMemoryMB = totalUsedMemoryKB / 1024

	local usedPercentage = (totalUsedMemoryMB / totalMemoryMB) * 100

	-- GPU stats
	-- local gpuStat =
	-- 	hs.execute("sudo /usr/bin/powermetrics --samplers gpu_power -i 100 -n 1")
	-- local gpuUsage = tonumber(string.match(gpuStat, "GPU HW active residency:%s*(%d+)"))
    local gpuUsage = 0

	-- Make visual meter

	-- CPU Cores
	for i = 1, numberOfCores do
		-- local dataPoint = ((i - 1) * 2) + 1 -- odd cores are the real ones (only for SMT processors)
		local dataPoint = i
		local barHeight = math.max(imageHeight * (data[dataPoint].active / 100), 1)

		sysMonitorCanvas[i] = {
			action = "fill",
			type = "rectangle",
			frame = {
				x = (i - 1) * (barWidth + interBarSpace),
				y = imageHeight - barHeight,
				h = barHeight,
				w = barWidth,
			},
		}
	end

	-- GPU
	local gpuBarHeight = math.max(imageHeight * gpuUsage / 100, 1)
	sysMonitorCanvas[numberOfCores + 1] = {
		action = "fill",
		type = "rectangle",
		frame = {
			x = numberOfCores * (barWidth + interBarSpace),
			y = imageHeight - gpuBarHeight,
			h = gpuBarHeight,
			w = gpuBarWidth,
		},
	}

	-- Memory
	local memBarHeight = math.max(imageHeight * usedPercentage / 100, 1)
	sysMonitorCanvas[numberOfCores + 2] = {
		action = "fill",
		type = "rectangle",
		frame = {
			x = numberOfCores * (barWidth + interBarSpace) + interBarSpace + gpuBarWidth,
			y = imageHeight - memBarHeight,
			h = memBarHeight,
			w = memBarWidth,
		},
	}

	-- if #sysMonitorCanvas == numberOfCores then
	-- add border only once:
	sysMonitorCanvas[numberOfCores + 3] = {
		action = "stroke",
		type = "rectangle",
		strokeColor = { alpha = 0.2 },
		frame = { x = 0, y = 0, w = imageWidth, h = imageHeight },
		roundedRectRadii = { xRadius = 3, yRadius = 3 },
	}
	-- end

	sysMonitorMenubar:setClickCallback(clickCallback)
	sysMonitorMenubar:setIcon(sysMonitorCanvas:imageFromCanvas())
end

function query()
	hs.host.cpuUsage(1, update)
end
query()
cpuUsageTimer = hs.timer.doEvery(1, query)
