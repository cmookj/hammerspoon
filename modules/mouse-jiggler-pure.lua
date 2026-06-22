-- === Random Mouse Mover Toggle ===
local moverEnabled = false
local moverTimer = nil

local function showNotification()
	msg = ""
	if moverEnabled then
		msg = "Enabled"
	else
		msg = "Disabled"
	end

	hs.notify.new({ title = "Mouse Jiggler", informativeText = msg, withdrawAfter = 3 }):send()
	-- hs.notify.new({ title = "Mouse Jiggler", informativeText = msg, soundName = "Submarine", withdrawAfter = 3 }):send()
end

-- Create menu bar item
-- local menu = hs.menubar.new()

-- Function to start movement
local function startMover()
	moverEnabled = true
	-- menu:setTitle("🟢") -- active indicator

	-- Move mouse with random delay and random movement
	moverTimer = hs.timer.doEvery(math.random(10, 30), function()
		local screen = hs.screen.mainScreen():frame()
		local x = math.random(screen.x, screen.x + screen.w)
		local y = math.random(screen.y, screen.y + screen.h)

		currentPosition = hs.mouse.absolutePosition()
		local diffX = math.abs(x - currentPosition.x)
		local diffY = math.abs(y - currentPosition.y)
		local diff = math.max(diffX, diffY)

		local dx = (x - currentPosition.x) / diff
		local dy = (y - currentPosition.y) / diff

		local x = currentPosition.x
		local y = currentPosition.y

		for i = 0, diff, 1 do
			x = x + dx
			y = y + dy
			local event = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.mouseMoved, { x = x, y = y })
			event:post()
			hs.timer.usleep(1000)
		end
	end)
end

-- Function to stop movement
local function stopMover()
	moverEnabled = false
	-- menu:setTitle("⚪️") -- inactive indicator

	if moverTimer then
		moverTimer:stop()
		moverTimer = nil
	end
end

-- Toggle function
local function toggleMover()
	if moverEnabled then
		stopMover()
	else
		startMover()
	end
end

hs.hotkey.bind({ "cmd", "alt", "shift" }, ".", function()
	toggleMover()
	showNotification()
end)

-- Configure menu bar icon + click action
-- menu:setTitle("⚪️") -- default OFF
-- menu:setClickCallback(toggleMover)
