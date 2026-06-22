ampOnIcon = [[ASCII:
.....1a..........AC..........E
..............................
......4.......................
1..........aA..........CE.....
e.2......4.3...........h......
..............................
..............................
.......................h......
e.2......6.3..........t..q....
5..........c..........s.......
......6..................q....
......................s..t....
.....5c.......................
]]

ampOffIcon = [[ASCII:
.....1a.....x....AC.y.......zE
..............................
......4.......................
1..........aA..........CE.....
e.2......4.3...........h......
..............................
..............................
.......................h......
e.2......6.3..........t..q....
5..........c..........s.......
......6..................q....
......................s..t....
...x.5c....y.......z..........
]]

-- Create menu bar item
local caffeine = hs.menubar.new()

local moverEnabled = false
local moverTimer = nil

-- Function to start movement
local function startMover()
	moverEnabled = true

	-- Move mouse with random delay and random movement
	moverTimer = hs.timer.doEvery(math.random(30, 90), function()
		local screen = hs.screen.mainScreen():frame()

		local x = math.random(screen.x, screen.x + screen.w)
		local y = math.random(screen.y, screen.y + screen.h)

		hs.mouse.setAbsolutePosition({ x = x, y = y })
	end)
end

-- Function to stop movement
local function stopMover()
	moverEnabled = false

	if moverTimer then
		moverTimer:stop()
		moverTimer = nil
	end
end

-- caffeine replacement
function setCaffeineDisplay(state)
	if state then
		-- caffeine:setIcon(ampOnIcon)
		caffeine:setTitle("☕️")
		startMover()
	else
		-- caffeine:setIcon(ampOffIcon)
		caffeine:setTitle("🥱")
		stopMover()
	end
end

function caffeineClicked()
	setCaffeineDisplay(hs.caffeinate.toggle("displayIdle"))
end

if caffeine then
	caffeine:setClickCallback(caffeineClicked)
	hs.caffeinate.set("displayIdle", false) -- let sleep by default
	setCaffeineDisplay(hs.caffeinate.get("displayIdle"))
end
