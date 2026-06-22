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

--
-- Mouse highlight similar to fireworks
--
local mouse_highlight = nil
local mouse_highlight_timer = nil
local mouse_highlight_radius_max = 1000
local mouse_highlight_radius_min = 200
local mouse_alpha_max = 10
local mouse_alpha_min = 0
local mouse_alpha = mouse_alpha_max
local mouse_alpha_increment = -1
local highlight_color = { 0.6, 0.6, 1.0 }

local function random_color()
	highlight_color[1] = math.random(0, 255) / 255.
	highlight_color[2] = math.random(0, 255) / 255.
	highlight_color[3] = math.random(0, 255) / 255.
end

local function remove_highlight_and_timer()
	if mouse_highlight then
		mouse_highlight:delete()
		mouse_highlight = nil
		if mouse_highlight_timer then
			mouse_highlight_timer:stop()
		end
		mouse_highlight_timer = nil
	end
end

local function update_highlight()
	mouse_alpha = mouse_alpha + mouse_alpha_increment
	mouse_highlight:hide()

	if mouse_alpha == mouse_alpha_min then
		remove_highlight_and_timer()
		return
	end

	mouse_highlight:setStrokeColor({
		["red"] = highlight_color[1],
		["green"] = highlight_color[2],
		["blue"] = highlight_color[3],
		["alpha"] = mouse_alpha / mouse_alpha_max,
	})
	mouse_highlight:setFillColor({
		["red"] = highlight_color[1],
		["green"] = highlight_color[2],
		["blue"] = highlight_color[3],
		["alpha"] = mouse_alpha / mouse_alpha_max,
	})
	mouse_highlight:setFill(true)
	mouse_highlight:setStrokeWidth(0)
	mouse_highlight:show()

	-- Set a timer to delete the circle after 0.1 seconds
	mouse_highlight_timer = hs.timer.doAfter(0.1, function()
		update_highlight()
	end)
end

local function highlight_mouse()
	-- Delete an existing highlight if it exsits
	remove_highlight_and_timer()

	random_color()

	-- Get the current coordinates of the mouse pointer
	mouse_point = hs.mouse.absolutePosition()
	-- Prepare a big red circle around the mouse pointer
	local mouse_radius = math.random(mouse_highlight_radius_min, mouse_highlight_radius_max)
	mouse_highlight = hs.drawing.circle(
		hs.geometry.rect(mouse_point.x - mouse_radius, mouse_point.y - mouse_radius, 2 * mouse_radius, 2 * mouse_radius)
	)
	mouse_alpha = mouse_alpha_max
	update_highlight()
end

local dim_main_display = false
local previous_brightness = hs.brightness.get()
local previous_brightness_ext = 0.3
local dimmed_brightness = 50
local studio = hs.screen.find("Studio Display")

local function dim_studio_display()
	if studio then
		previous_brightness_ext = studio:getBrightness()
		print("Studio Display brightness = " .. tostring(previous_brightness_ext))
		studio:setBrightness(0)
	end
end

local function gradually_dim_display()
	local current_brightness = hs.brightness.get()
	if current_brightness <= dimmed_brightness then
		return
	end

	local step = math.floor((current_brightness - dimmed_brightness) / 10.)
	for i = current_brightness, dimmed_brightness, -step do
		hs.brightness.set(i)
		hs.timer.usleep(100000)
	end
end

local function keep_dimmed()
	hs.brightness.set(dimmed_brightness)
end

local function keep_studio_display_dimmed()
	if studio then
		studio:setBrightness(0)
	end
end

-- Function to start movement
local function startMover()
	moverEnabled = true
	showNotification()

	-- Move mouse randomly at every 3 secs
	moverTimer = hs.timer.doEvery(3, function()
		local screen = hs.screen.mainScreen():frame()
		local x = math.random(screen.x, screen.x + screen.w)
		local y = math.random(screen.y, screen.y + screen.h)
		mouse_highlight_radius_max = math.floor(screen.w * 1. / 3.)
		mouse_highlight_radius_min = math.floor(screen.w * 1. / 6.)

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
            keep_studio_display_dimmed()
            if dim_main_display then
                keep_dimmed()
            end
			hs.timer.usleep(10)
		end

		highlight_mouse()
	end)
end

-- Function to stop movement
local function stopMover()
	moverEnabled = false
	showNotification()

	if moverTimer then
		moverTimer:stop()
		moverTimer = nil

		remove_highlight_and_timer()
	end
end

local function get_display_names()
	for _, screen in ipairs(hs.screen.allScreens()) do
		print(screen:name())
	end
end

-- Toggle function
local function toggleMover()
	if moverEnabled then
		stopMover()
        if dim_main_display then
		    hs.brightness.set(previous_brightness)
        end
		studio:setBrightness(previous_brightness_ext)
	else
		-- get_display_names()
		startMover()
        dim_studio_display()
        if dim_main_display then
            gradually_dim_display()
        end
	end
end

hs.hotkey.bind({ "cmd", "alt", "shift" }, ".", function()
	toggleMover()
end)
