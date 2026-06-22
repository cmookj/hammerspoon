--------------------------------------------------
-- Advanced Battery Monitor
--------------------------------------------------
local batteryMonitor = {}
batteryMonitor.active = false
batteryMonitor.timer = nil
batteryMonitor.nextThreshold = nil
batteryMonitor.wasCharging = nil

batteryMonitor.criticalTriggered = false
batteryMonitor.persistentAlert = nil
batteryMonitor.sleepTriggered = false

batteryMonitor.menubar = nil

--------------------------------------------------
-- Configuration
--------------------------------------------------
local CHECK_INTERVAL = 60
local CRITICAL_LEVEL = 10
local PERSISTENT_LEVEL = 5
local SLEEP_LEVEL = 3
local CRITICAL_RESET_LEVEL = 15

--------------------------------------------------
-- Helpers
--------------------------------------------------
local function systemHasBattery()
	return hs.battery.capacity() ~= nil
end

local function batteryLevel()
	return math.floor(hs.battery.percentage())
end

local function computeNextThreshold(level)
	local t = math.floor(level / 10) * 10
	if t == level then
		t = t - 10
	end
	return t
end

--------------------------------------------------
-- Notification
--------------------------------------------------
local function notify(title, text, sound)
	hs.notify
		.new({
			title = title,
			informativeText = text,
			soundName = sound or "default",
		})
		:send()
end

--------------------------------------------------
-- Minimal Vertical Indicator
--------------------------------------------------
local function batteryColor(level)
	if level > 50 then
		return { green = 1, red = 0, blue = 0, alpha = 1 }
	elseif level > 20 then
		return { red = 1, green = 0.8, blue = 0, alpha = 1 }
	elseif level > 10 then
		return { red = 1, green = 0.5, blue = 0, alpha = 1 }
	else
		return { red = 1, green = 0, blue = 0, alpha = 1 }
	end
end

local function updateMenubar(level)
	if not batteryMonitor.menubar then
		batteryMonitor.menubar = hs.menubar.new()
	end

	local height = 16
	local width = 3

	local canvas = hs.canvas.new({ x = 0, y = 0, w = width, h = height })

	canvas[1] = {
		type = "rectangle",
		action = "fill",
		fillColor = { white = 0.2, alpha = 0.3 },
		frame = { x = 0, y = 0, w = width, h = height },
	}

	local fillHeight = math.floor((level / 100) * height)

	canvas[2] = {
		type = "rectangle",
		action = "fill",
		fillColor = batteryColor(level),
		frame = { x = 0, y = height - fillHeight, w = width, h = fillHeight },
	}

	batteryMonitor.menubar:setIcon(canvas:imageFromCanvas())
end

--------------------------------------------------
-- Start
--------------------------------------------------
function batteryMonitor:start()
	if not systemHasBattery() then
		notify("Battery Monitor", "This system does not have a battery.")
		return
	end

	self.active = true

	local level = batteryLevel()
	self.wasCharging = hs.battery.isCharging()

	notify("Battery Monitor Activated", "Battery: " .. level .. "%")

	if not self.wasCharging then
		self.nextThreshold = computeNextThreshold(level)
	end

	updateMenubar(level)

	self.timer = hs.timer.doEvery(CHECK_INTERVAL, function()
		local level = batteryLevel()
		local charging = hs.battery.isCharging()

		updateMenubar(level)

		--------------------------------------------------
		-- Reset on charging
		--------------------------------------------------
		if charging then
			self.nextThreshold = nil
			if level >= CRITICAL_RESET_LEVEL then
				self.criticalTriggered = false
				self.sleepTriggered = false
			end
			if self.persistentAlert then
				self.persistentAlert:withdraw()
				self.persistentAlert = nil
			end
		end

		--------------------------------------------------
		-- Charging → Discharging transition
		--------------------------------------------------
		if self.wasCharging and not charging then
			self.nextThreshold = computeNextThreshold(level)
		end

		--------------------------------------------------
		-- 10% Notifications
		--------------------------------------------------
		if not charging and self.nextThreshold then
			if level <= self.nextThreshold then
				notify("Battery Level", self.nextThreshold .. "% remaining")
				self.nextThreshold = self.nextThreshold - 10
			end
		end

		--------------------------------------------------
		-- Critical 10%
		--------------------------------------------------
		if not charging and level <= CRITICAL_LEVEL and not self.criticalTriggered then
			notify("⚠ Low Battery Critical", level .. "% remaining!", "Funk")

			self.criticalTriggered = true
		end

		--------------------------------------------------
		-- Persistent 5%
		--------------------------------------------------
		if not charging and level <= PERSISTENT_LEVEL and not self.persistentAlert then
			self.persistentAlert = hs.notify.new({
				title = "🚨 Battery Danger",
				informativeText = level .. "% remaining!",
				autoWithdraw = false,
				soundName = "Funk",
			})

			self.persistentAlert:send()
		end

		if self.persistentAlert and level > 8 then
			self.persistentAlert:withdraw()
			self.persistentAlert = nil
		end

		--------------------------------------------------
		-- Auto Sleep at 3%
		--------------------------------------------------
		if not charging and level <= SLEEP_LEVEL and not self.sleepTriggered then
			notify("Sleeping System", "Battery critically low (" .. level .. "%)", "Funk")

			self.sleepTriggered = true
			hs.timer.doAfter(5, function()
				hs.caffeinate.systemSleep()
			end)
		end

		self.wasCharging = charging
	end)
end

--------------------------------------------------
-- Stop
--------------------------------------------------
function batteryMonitor:stop()
	if self.timer then
		self.timer:stop()
		self.timer = nil
	end

	if self.menubar then
		self.menubar:delete()
		self.menubar = nil
	end

	if self.persistentAlert then
		self.persistentAlert:withdraw()
		self.persistentAlert = nil
	end

	self.active = false
	notify("Battery Monitor", "Deactivated")
end

--------------------------------------------------
-- Toggle Hotkey
--------------------------------------------------
hs.hotkey.bind({ "cmd", "alt", "shift" }, "B", function()
	if batteryMonitor.active then
		batteryMonitor:stop()
	else
		batteryMonitor:start()
	end
end)
