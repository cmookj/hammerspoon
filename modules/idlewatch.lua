local M = {}

-- Configuration
local idleThreshold = 60      -- seconds of inactivity before "screensaver" mode starts
local checkInterval = 5       -- how often to check for idleness (seconds)
local periodicInterval = 10   -- how often the periodic function runs while idle (seconds)

-- State
local lastActivity = hs.timer.secondsSinceEpoch()
local isIdle = false
local idleTimer, periodicTimer, eventTap

-- Your periodic work goes here
local function periodicFunction()
  hs.alert.show("Still idle...", 1)
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

function M.start()
    M.stop()
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
  hs.printf("eventTap running: %s", tostring(eventTap:isEnabled()))

  idleTimer = hs.timer.doEvery(checkInterval, function()
    local idleFor = hs.timer.secondsSinceEpoch() - lastActivity
    if not isIdle and idleFor >= idleThreshold then
      startIdle()
    end
  end)
end

function M.stop()
  hs.printf("idlewatch: stopped")
  if eventTap then eventTap:stop(); eventTap = nil end
  if idleTimer then idleTimer:stop(); idleTimer = nil end
  stopIdle()
end

return M
