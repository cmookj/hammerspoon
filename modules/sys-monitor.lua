--------------------------------------------------------------------------------
-- Unified Monitor
--------------------------------------------------------------------------------
local update -- Forward declaration

local unified = {}
unified.menubar = hs.menubar.new()

--------------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------------
local IMAGE_HEIGHT = 16
local SHOW_BATT = false
local BAT_WIDTH = 2
local BAT_SPACING = 1
local CPU_BAR_WIDTH = 1
local CPU_SPACING = 1
local MEM_BAR_WIDTH = 2
local INTER_SPACING = 2
local MARGIN = 1

local CLR_BLACK = { red = 0., green = 0., blue = 0., alpha = 1. }
local CLR_WHITE = { red = 1., green = 1., blue = 1., alpha = 1. }
local CLR_BG = { red = 0., green = 0., blue = 0., alpha = 0.8 }

local CLR_NOMINAL = { red = 34. / 255., green = 197. / 255., blue = 94. / 255., alpha = 1.0 }
local CLR_MODERATE = { red = 234. / 255., green = 179. / 255., blue = 8. / 255., alpha = 1.0 }
local CLR_HEAVY = { red = 249. / 255., green = 115. / 255., blue = 22. / 255., alpha = 1.0 }
local CLR_CRITICAL = { red = 220. / 255., green = 38. / 255., blue = 39. / 255., alpha = 1.0 }

--------------------------------------------------------------------------------
-- INTERNAL STATE
--------------------------------------------------------------------------------

local currentCoreCount = 0
local cachedMemPercent = 0
local memoryPressureLevel = 1
local lastCPUData = nil

unified.canvas = nil
unified.cpuBars = {}
unified.cpuPeakBars = {}
unified.cpuLoads = {}
unified.cpuPeaks = {}

unified.batteryFillIndex = nil
unified.memBarIndex = nil
unified.pulsePhase = 0

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function systemHasBattery()
	return hs.battery.capacity() ~= nil
end

local function cpuHeatColor(load)
	if load < 30 then
		return CLR_NOMINAL
	elseif load < 60 then
		return CLR_MODERATE
	elseif load < 90 then
		return CLR_HEAVY
	else
		return CLR_CRITICAL
	end
end

local function memoryColor(percent)
	if percent < 70 then
		return CLR_NOMINAL
	elseif percent < 80 then
		return CLR_MODERATE
	elseif percent < 90 then
		return CLR_HEAVY
	else
		return CLR_CRITICAL
	end
end

local function batteryColor(level, charging)
	local base
	if level > 80 then
		base = CLR_NOMINAL
	elseif level > 30 then
		base = CLR_MODERATE
	elseif level > 10 then
		base = CLR_HEAVY
	else
		base = CLR_CRITICAL
	end
	base.alpha = charging and (0.5 + 0.5 * math.abs(math.sin(unified.pulsePhase))) or 1
	return base
end

local function batteryLevel()
	return math.floor(hs.battery.percentage() or 0)
end

--------------------------------------------------------------------------------
-- MEMORY POLLING (optimized)
--------------------------------------------------------------------------------

local totalMemoryMB = tonumber(string.match(hs.execute("sysctl hw.memsize"), "(%d+)")) / 1024 / 1024

local pageSizeKB = 16

local function pollMemory()
	local vm = hs.execute("vm_stat")

	local active = tonumber(string.match(vm, "Pages active:%s*(%d+)")) or 0
	local wired = tonumber(string.match(vm, "Pages wired down:%s*(%d+)")) or 0
	local compressed = tonumber(string.match(vm, "Pages occupied by compressor:%s*(%d+)")) or 0

	local usedKB = (active + wired + compressed) * pageSizeKB
	cachedMemPercent = ((usedKB / 1024) / totalMemoryMB) * 100

	memoryPressureLevel = hs.execute("sysctl kern.memorystatus_vm_pressure_level")
end

hs.timer.doEvery(5, pollMemory)
pollMemory()

--------------------------------------------------------------------------------
-- BUILD CANVAS
--------------------------------------------------------------------------------

local function buildCanvas(coreCount)
	local cpuWidth = coreCount * CPU_BAR_WIDTH + (coreCount - 1) * CPU_SPACING
	local totalWidth = cpuWidth + INTER_SPACING + MEM_BAR_WIDTH + 2 * MARGIN
	if systemHasBattery() and SHOW_BATT then
		totalWidth = totalWidth + BAT_WIDTH + BAT_SPACING + 2 * MARGIN
	end

	unified.canvas = hs.canvas.new({
		x = 0,
		y = 0,
		w = totalWidth,
		h = IMAGE_HEIGHT,
	})

	-- Background
	unified.canvas:appendElements({
		type = "rectangle",
		action = "fill",
		fillColor = CLR_BG,
		frame = { x = 0, y = 0, w = totalWidth, h = IMAGE_HEIGHT },
	})

	unified.cpuBars = {}
	unified.cpuPeakBars = {}
	unified.cpuLoads = {}
	unified.cpuPeaks = {}

	local x = MARGIN

	-- Battery background
	if systemHasBattery() and SHOW_BATT then
		unified.canvas:appendElements({
			type = "rectangle",
			action = "fill",
			fillColor = { red = 0.2, green = 0.2, blue = 0.2, alpha = 0.3 },
			frame = { x = x, y = 0, w = BAT_WIDTH, h = IMAGE_HEIGHT },
		})

		unified.batteryFillIndex = #unified.canvas + 1
		unified.canvas:appendElements({
			type = "rectangle",
			action = "fill",
			fillColor = { red = 0.2, green = 0.2, blue = 0.2, alpha = 0.3 },
			frame = { x = x, y = 0, w = BAT_WIDTH, h = IMAGE_HEIGHT },
		})

        unified.canvas:appendElements({
            type = "rectangle",
            action = "fill",
            fillColor = { red = 1, green = 1, blue = 1, alpha = 0.9 },
            frame = { x = x + BAT_WIDTH + MARGIN, y = 0, w = BAT_SPACING, h = IMAGE_HEIGHT },
        })

		x = x + BAT_WIDTH + BAT_SPACING + 2 * MARGIN
	end

	-- CPU bars
	for i = 1, coreCount do
		local bottom = #unified.canvas + 1
		unified.canvas:appendElements({
			type = "rectangle",
			action = "fill",
			fillColor = { red = 0.2, green = 0.2, blue = 0.2, alpha = 0.3 },
			frame = { x = x, y = IMAGE_HEIGHT - 1, w = CPU_BAR_WIDTH, h = 1 },
		})

		local peak = #unified.canvas + 1
		unified.canvas:appendElements({
			type = "rectangle",
			action = "fill",
			fillColor = { red = 1, green = 1, blue = 1, alpha = 0.9 },
			frame = { x = x, y = IMAGE_HEIGHT - 1, w = CPU_BAR_WIDTH, h = 1 },
		})

		unified.cpuBars[i] = bottom
		unified.cpuPeakBars[i] = peak
		unified.cpuLoads[i] = 1
		unified.cpuPeaks[i] = 1

		x = x + CPU_BAR_WIDTH
		if i < coreCount then
			x = x + CPU_SPACING
		end
	end

	x = x + INTER_SPACING

	unified.memBarIndex = #unified.canvas + 1
	unified.canvas:appendElements({
		type = "rectangle",
		action = "fill",
		fillColor = { red = 0.2, green = 0.2, blue = 0.2, alpha = 0.3 },
		frame = { x = x, y = IMAGE_HEIGHT - 1, w = MEM_BAR_WIDTH, h = 1 },
	})

	unified.menubar:setIcon(unified.canvas:imageFromCanvas(), false)
end

--------------------------------------------------------------------------------
-- CPU UPDATE
--------------------------------------------------------------------------------

local function updateCPU(cpuData)
	if #cpuData ~= currentCoreCount then
		currentCoreCount = #cpuData
		buildCanvas(currentCoreCount)
		return
	end

	for i = 1, #cpuData do
		local load = cpuData[i].active

		-- Update current core's load
		unified.cpuLoads[i] = load

		-- Update current core's peak
		if load > unified.cpuPeaks[i] then
			unified.cpuPeaks[i] = load
		else
			unified.cpuPeaks[i] = math.max(load, unified.cpuPeaks[i] - 10)
		end

		-- Update bars
		local bottom = unified.cpuBars[i]
		local peak = unified.cpuPeakBars[i]

		local h = math.max(IMAGE_HEIGHT * load / 100, 1)
		unified.canvas[bottom].frame =
			{ x = unified.canvas[bottom].frame.x, y = IMAGE_HEIGHT - h, w = CPU_BAR_WIDTH, h = h }
		unified.canvas[bottom].fillColor = cpuHeatColor(load)

		local peakH = math.max(IMAGE_HEIGHT * unified.cpuPeaks[i] / 100, 1)
		unified.canvas[peak].frame =
			{ x = unified.canvas[peak].frame.x, y = IMAGE_HEIGHT - peakH, w = CPU_BAR_WIDTH, h = 1 }
		unified.canvas[peak].fillColor = cpuHeatColor(unified.cpuPeaks[i])
	end
end

--------------------------------------------------------------------------------
-- MAIN UPDATE
--------------------------------------------------------------------------------

function update(cpuData)
	if not cpuData then
		return
	end

	lastCPUData = cpuData

	if not unified.canvas then
		currentCoreCount = #cpuData
		buildCanvas(currentCoreCount)
	end

	unified.pulsePhase = unified.pulsePhase + math.pi / 4

	updateCPU(cpuData)

	-- Battery
	if systemHasBattery() and SHOW_BATT then
		local level = batteryLevel()
		local h = math.max((level / 100) * IMAGE_HEIGHT, 1)

		unified.canvas[unified.batteryFillIndex].frame = { x = MARGIN, y = IMAGE_HEIGHT - h, w = BAT_WIDTH, h = h }
		unified.canvas[unified.batteryFillIndex].fillColor = batteryColor(level, hs.battery.isCharging())
	end

	-- Memory
	local memH = math.max(IMAGE_HEIGHT * cachedMemPercent / 100, 1)
	unified.canvas[unified.memBarIndex].frame =
		{ x = unified.canvas[unified.memBarIndex].frame.x, y = IMAGE_HEIGHT - memH, w = MEM_BAR_WIDTH, h = memH }
	local fillColor = CLR_NOMINAL

	if memoryPressureLevel == 2 then
		fillColor = CLR_HEAVY
	elseif memoryPressureLevel == 4 then
		fillColor = CLR_CRITICAL
	end

	unified.canvas[unified.memBarIndex].fillColor = fillColor

	unified.menubar:setIcon(unified.canvas:imageFromCanvas(), false)
end

--------------------------------------------------------------------------------
-- CLICK
--------------------------------------------------------------------------------
unified.menubar:setClickCallback(function(mods)
	hs.application.launchOrFocus("Activity Monitor")
end)

--------------------------------------------------------------------------------
-- CPU LOOP
--------------------------------------------------------------------------------
local function cpuLoop()
	hs.host.cpuUsage(1, function(cpuData)
		update(cpuData)
		cpuLoop()
	end)
end

cpuLoop()
