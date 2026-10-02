local screen = hs.screen.mainScreen():frame()
--------------------------------------------------------------------------------
-- Fireworks
--------------------------------------------------------------------------------
local FireWorks = {}

FireWorks.radius_max = math.floor(screen.w * 1. / 2.)
FireWorks.radius_min = math.floor(screen.w * 1. / 4.)

FireWorks.x = 0
FireWorks.y = 0

FireWorks.fireworks = nil
FireWorks.timer = nil
FireWorks.alpha_max = 10
FireWorks.alpha_min = 0
FireWorks.alpha = alpha_max
FireWorks.alpha_increment = -1
FireWorks.color = { 0.6, 0.6, 1.0 }

function FireWorks.random_color()
	FireWorks.color[1] = math.random(0, 255) / 255.
	FireWorks.color[2] = math.random(0, 255) / 255.
	FireWorks.color[3] = math.random(0, 255) / 255.
end

function FireWorks.stop()
    if FireWorks.timer then
        FireWorks.timer:stop()
    end
    if FireWorks.fireworks then
        FireWorks.fireworks:delete()
        FireWorks.fireworks = nil
    end
end

function FireWorks.update()
	FireWorks.alpha = FireWorks.alpha + FireWorks.alpha_increment

	FireWorks.fireworks:hide()

	if FireWorks.alpha == FireWorks.alpha_min then
		FireWorks:stop()
		return
	end

	FireWorks.fireworks:setStrokeColor({
		["red"] = FireWorks.color[1],
		["green"] = FireWorks.color[2],
		["blue"] = FireWorks.color[3],
		["alpha"] = FireWorks.alpha / FireWorks.alpha_max,
	})
	FireWorks.fireworks:setFillColor({
		["red"] = FireWorks.color[1],
		["green"] = FireWorks.color[2],
		["blue"] = FireWorks.color[3],
		["alpha"] = FireWorks.alpha / FireWorks.alpha_max,
	})
	FireWorks.fireworks:setFill(true)
	FireWorks.fireworks:setStrokeWidth(0)
	FireWorks.fireworks:show()

	-- Set a timer to delete the circle after 0.1 seconds
	FireWorks.timer = hs.timer.doAfter(0.1, function()
		FireWorks:update()
	end)
end

function FireWorks.fire()
	-- Delete an existing fireworks if it exsits
	FireWorks:stop()

	FireWorks:random_color()

    -- Randomly choose fireworks position
    FireWorks.x = math.random(screen.x, screen.x + screen.w)
    FireWorks.y = math.random(screen.y, screen.y + screen.h)

	-- Prepare a big circle around the position
	local radius = math.random(FireWorks.radius_min, FireWorks.radius_max)

	FireWorks.fireworks = hs.drawing.circle(
		hs.geometry.rect(FireWorks.x - radius, FireWorks.y - radius, 2 * radius, 2 * radius)
	)
	FireWorks.alpha = FireWorks.alpha_max

	FireWorks:update()
end

--------------------------------------------------------------------------------
--  Jiggler
--------------------------------------------------------------------------------
local Jiggler = {}

-- variables for Jiggler
Jiggler.fireworks = nil
Jiggler.interval = 30
Jiggler.amplitude_x = 10
Jiggler.amplitude_y = 10
Jiggler.mover_enabled = false
Jiggler.mover_timer = nil

-- Screen dimming
Jiggler.dim_main_display = false
Jiggler.previous_brightness = hs.brightness.get()
Jiggler.previous_brightness_ext = 0.3
Jiggler.dimmed_brightness = 50
Jiggler.studio = hs.screen.find("Studio Display")

function Jiggler.show_notification()
	msg = ""
	if Jiggler.mover_enabled then
		msg = "Enabled"
	else
		msg = "Disabled"
	end

	hs.notify.new({ title = "Mouse Jiggler", informativeText = msg, withdrawAfter = 3 }):send()
end

function Jiggler.remove_fireworks()
	if Jiggler.fireworks then
        Jiggler.fireworks:stop()
		Jiggler.fireworks = nil
		Jiggler.timer = nil
	end
end

-- Function to stop movement
function Jiggler.stop_mover()
	Jiggler.mover_enabled = false
	Jiggler:show_notification()

	if Jiggler.mover_timer then
		Jiggler.mover_timer:stop()
		Jiggler.mover_timer = nil

		Jiggler:remove_fireworks()
	end
end

function Jiggler.get_display_names()
	for _, screen in ipairs(hs.screen.allScreens()) do
		print(screen:name())
	end
end

-- Toggle function
function Jiggler.toggle_mover()
	if Jiggler.mover_enabled then
		Jiggler:stop_mover()
        if Jiggler.dim_main_display then
		    hs.brightness.set(Jiggler.previous_brightness)
        end
		Jiggler.studio:setBrightness(Jiggler.previous_brightness_ext)
	else
		Jiggler:start_mover()
        Jiggler:dim_studio_display()
        if Jiggler.dim_main_display then
            Jiggler:gradually_dim_display()
        end
	end
end

function Jiggler.dim_studio_display()
	if Jiggler.studio then
		Jiggler.previous_brightness_ext = Jiggler.studio:getBrightness()
		-- hs.printf("Studio Display brightness = %f", Jiggler.previous_brightness_ext)
		Jiggler.studio:setBrightness(0)
	end
end

function Jiggler.gradually_dim_display()
	local current_brightness = hs.brightness.get()
	if current_brightness <= Jiggler.dimmed_brightness then
		return
	end

	local step = math.floor((current_brightness - Jiggler.dimmed_brightness) / 10.)
	for i = current_brightness, Jiggler.dimmed_brightness, -step do
		hs.brightness.set(i)
		hs.timer.usleep(100000)
	end
end

function Jiggler.keep_dimmed()
	hs.brightness.set(Jiggler.dimmed_brightness)
end

function Jiggler.keep_studio_display_dimmed()
	if Jiggler.studio then
		Jiggler.studio:setBrightness(0)
	end
end

function Jiggler.get_current_mouse_position()
    local current_mouse_position = hs.mouse.absolutePosition()
    current_mouse_position.x = math.floor(current_mouse_position.x)
    current_mouse_position.y = math.floor(current_mouse_position.y)

    return current_mouse_position
end

-- Function to start movement
function Jiggler.start_mover()
	Jiggler.mover_enabled = true
	Jiggler:show_notification()
    Jiggler.fireworks = FireWorks

	-- Move mouse randomly at every `interval` secs
	Jiggler.mover_timer = hs.timer.doEvery(Jiggler.interval, function()
        Jiggler:jiggle()
	end)
end

-- One shot movement
function Jiggler.jiggle()
    Jiggler.fireworks = FireWorks

    local current_pos = Jiggler:get_current_mouse_position()
    local x = math.random(current_pos.x - Jiggler.amplitude_x, current_pos.x + Jiggler.amplitude_x)
    local y = math.random(current_pos.y - Jiggler.amplitude_y, current_pos.y + Jiggler.amplitude_y)

    local event = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.mouseMoved, { x = x, y = y })
    event:post()
    Jiggler:keep_studio_display_dimmed()
    if Jiggler.dim_main_display then
        Jiggler:keep_dimmed()
    end

    -- Fireworks
    Jiggler.fireworks:fire()

    -- Move back
    hs.timer.usleep(1000000)
    local event = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.mouseMoved, { x = current_pos.x, y = current_pos.y })
    event:post()

    Jiggler.fireworks = nil
end

--------------------------------------------------------------------------------
--  IdleWatcher
--------------------------------------------------------------------------------
local IdleWatcher = {}

-- Configuration
local idleThreshold = 60      -- seconds of inactivity before "screensaver" mode starts
local checkInterval = 5       -- how often to check for idleness (seconds)
local periodicInterval = 10   -- how often the periodic function runs while idle (seconds)

-- State
local lastActivity = hs.timer.secondsSinceEpoch()
local isIdle = false
local idleTimer, periodicTimer, eventTap
local enabled = false

-- Your periodic work goes here
local function periodicFunction()
    Jiggler:jiggle()
  -- hs.alert.show("Still idle...", 1)
  -- e.g. move a window, dim a light, take a snapshot, etc.
end

local function startIdle()
  if isIdle then return end
  isIdle = true
  hs.printf("idlewatch: entering idle mode")
  periodicFunction() -- run once immediately
  periodicTimer = hs.timer.doEvery(periodicInterval, periodicFunction)
end

local function stopIdle()
  if not isIdle then return end
  isIdle = false
  hs.printf("idlewatch: activity detected, leaving idle mode")
  if periodicTimer then
    periodicTimer:stop()
    periodicTimer = nil
  end
end

function IdleWatcher.start()
  IdleWatcher.stop()
  lastActivity = hs.timer.secondsSinceEpoch()

  local types = hs.eventtap.event.types
  eventTap = hs.eventtap.new({
    types.keyDown,
    types.flagsChanged,
    types.mouseMoved,
    types.leftMouseDown,
    types.rightMouseDown,
    types.otherMouseDown,
    types.leftMouseDragged,
    types.rightMouseDragged,
    types.scrollWheel,
  }, function(_)
    lastActivity = hs.timer.secondsSinceEpoch()
    if isIdle then stopIdle() end
    return false -- never swallow the event
  end)
  eventTap:start()

  idleTimer = hs.timer.doEvery(checkInterval, function()
    local idleFor = hs.timer.secondsSinceEpoch() - lastActivity
    if not isIdle and idleFor >= idleThreshold then
      startIdle()
    end
  end)

  hs.printf("idlewatch: started")
end

function IdleWatcher.stop()
  hs.printf("idlewatch: stopped")
  if eventTap then eventTap:stop(); eventTap = nil end
  if idleTimer then idleTimer:stop(); idleTimer = nil end
  stopIdle()
end

hs.hotkey.bind({ "cmd", "alt", "shift" }, ".", function()
	Jiggler:toggle_mover()
    --[[
   if enabled then
       IdleWatcher:stop()
       enabled = false
   else
       IdleWatcher:start()
       enabled = true
   end
   ]]
end)
