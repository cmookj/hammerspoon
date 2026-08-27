-- Local variables for this module
local interval = 30
local initial_mouse_position = nil

local screen = hs.screen.mainScreen():frame()
local fireworks_radius_max = math.floor(screen.w * 1. / 3.)
local fireworks_radius_min = math.floor(screen.w * 1. / 6.)

local amplitude_x = 10
local amplitude_y = 10

-- Random Mouse Mover Toggle
local mover_enabled = false
local mover_timer = nil

local function show_notification()
	msg = ""
	if mover_enabled then
		msg = "Enabled"
	else
		msg = "Disabled"
	end

	hs.notify.new({ title = "Mouse Jiggler", informativeText = msg, withdrawAfter = 3 }):send()
	-- hs.notify.new({ title = "Mouse Jiggler", informativeText = msg, soundName = "Submarine", withdrawAfter = 3 }):send()
end

--
-- Fireworks similar to fireworks
--
local fireworks = nil
local fireworks_timer = nil
local fireworks_radius_max = 1000
local fireworks_radius_min = 200
local fireworks_alpha_max = 10
local fireworks_alpha_min = 0
local fireworks_alpha = fireworks_alpha_max
local fireworks_alpha_increment = -1
local fireworks_color = { 0.6, 0.6, 1.0 }

local function random_color()
	fireworks_color[1] = math.random(0, 255) / 255.
	fireworks_color[2] = math.random(0, 255) / 255.
	fireworks_color[3] = math.random(0, 255) / 255.
end

local function remove_fireworks_and_timer()
	if fireworks then
		fireworks:delete()
		fireworks = nil
		if fireworks_timer then
			fireworks_timer:stop()
		end
		fireworks_timer = nil
	end
end

local function update_fireworks()
	fireworks_alpha = fireworks_alpha + fireworks_alpha_increment
	fireworks:hide()

	if fireworks_alpha == fireworks_alpha_min then
		remove_fireworks_and_timer()
		return
	end

	fireworks:setStrokeColor({
		["red"] = fireworks_color[1],
		["green"] = fireworks_color[2],
		["blue"] = fireworks_color[3],
		["alpha"] = fireworks_alpha / fireworks_alpha_max,
	})
	fireworks:setFillColor({
		["red"] = fireworks_color[1],
		["green"] = fireworks_color[2],
		["blue"] = fireworks_color[3],
		["alpha"] = fireworks_alpha / fireworks_alpha_max,
	})
	fireworks:setFill(true)
	fireworks:setStrokeWidth(0)
	fireworks:show()

	-- Set a timer to delete the circle after 0.1 seconds
	fireworks_timer = hs.timer.doAfter(0.1, function()
		update_fireworks()
	end)
end

local function fire_fireworks(x, y)
	-- Delete an existing fireworks if it exsits
	remove_fireworks_and_timer()

	random_color()

	-- Prepare a big circle around the position
	local fireworks_radius = math.random(fireworks_radius_min, fireworks_radius_max)
	fireworks = hs.drawing.circle(
		hs.geometry.rect(x - fireworks_radius, y - fireworks_radius, 2 * fireworks_radius, 2 * fireworks_radius)
	)
	fireworks_alpha = fireworks_alpha_max

	update_fireworks()
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
local function start_mover()
	mover_enabled = true
	show_notification()

    initial_mouse_position = hs.mouse.absolutePosition()
    initial_mouse_position.x = math.floor(initial_mouse_position.x)
    initial_mouse_position.y = math.floor(initial_mouse_position.y)

	-- Move mouse randomly at every `interval` secs
	mover_timer = hs.timer.doEvery(interval, function()
		local x = math.random(initial_mouse_position.x - amplitude_x, initial_mouse_position.x + amplitude_x)
		local y = math.random(initial_mouse_position.y - amplitude_y, initial_mouse_position.y + amplitude_y)

        local event = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.mouseMoved, { x = x, y = y })
        event:post()
        keep_studio_display_dimmed()
        if dim_main_display then
            keep_dimmed()
        end

        -- Randomly choose fireworks position
		local fireworks_x = math.random(screen.x, screen.x + screen.w)
		local fireworks_y = math.random(screen.y, screen.y + screen.h)
		fire_fireworks(fireworks_x, fireworks_y)
	end)
end

-- Function to stop movement
local function stop_mover()
	mover_enabled = false
	show_notification()

	if mover_timer then
		mover_timer:stop()
		mover_timer = nil

		remove_fireworks_and_timer()
	end
end

local function get_display_names()
	for _, screen in ipairs(hs.screen.allScreens()) do
		print(screen:name())
	end
end

-- Toggle function
local function toggle_mover()
	if mover_enabled then
		stop_mover()
        if dim_main_display then
		    hs.brightness.set(previous_brightness)
        end
		studio:setBrightness(previous_brightness_ext)
	else
		-- get_display_names()
		start_mover()
        dim_studio_display()
        if dim_main_display then
            gradually_dim_display()
        end
	end
end

hs.hotkey.bind({ "cmd", "alt", "shift" }, ".", function()
	toggle_mover()
end)
