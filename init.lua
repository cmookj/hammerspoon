require("modules.config")
-- require("modules.emacs-keybindings")
-- require("modules.input-switcher")
require("modules.launcher")
-- require("modules.caffeine")
require("modules.window-management")
require("modules.emoji")
require("modules.sys-monitor")
-- require("modules.workload-monitor")
require("modules.laser-pointer")
require("modules.audio-output")
require("modules.mouse-jiggler")
-- require("modules.battery-monitor")

-- local pasteboard = require("modules.pasteboard")
-- pasteboard.setSize(10)
-- hs.hotkey.bind({ "ctrl", "shift", "option" }, "p", pasteboard.showList)
-- hs.hotkey.bind({ "ctrl", "shift", "option" }, "c", pasteboard.clear)

-- Shortcuts
hs.hotkey.bind({ "cmd", "alt", "shift" }, "C", function()
	hs.loadSpoon("AClock")
	spoon.AClock.format = "%I:%M [%d]"
	spoon.AClock.width = 800
	spoon.AClock:toggleShow()
end)

hs.loadSpoon("Emojis")
spoon.Emojis:bindHotkeys({
	toggle = {
		{ "cmd", "alt", "shift" },
		"E",
	},
})

local inspect = require("hs.inspect")

hs.hotkey.bind({ "cmd", "alt", "shift" }, "W", function()
	-- https://www.hammerspoon.org/docs/hs.window.html
	local window = hs.window.focusedWindow()
	-- window:focus()
	-- window:maximize()
	print("window", inspect(window:topLeft().x))
	if window:topLeft().x == 0 and window:topLeft().y == 0 then
		window:setTopLeft({ x = 400, y = 400 })
	else
		window:setTopLeft({ x = 0, y = 0 })
	end
end)

-- hammerflow
-- hs.loadSpoon("Hammerflow")
-- spoon.Hammerflow.loadFirstValidTomlFile({
-- "home.toml",
-- "work.toml",
-- --	"Spoons/Hammerflow.spoon/sample.toml",
-- })
--
-- -- optionally respect auto_reload setting in the toml config.
-- if spoon.Hammerflow.auto_reload then
-- hs.loadSpoon("ReloadConfiguration")
-- -- set any paths for auto reload
-- -- spoon.ReloadConfiguration.watch_paths = {hs.configDir, "~/path/to/my/configs/"}
-- spoon.ReloadConfiguration:start()
-- end

-- hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "M", function()
--     local mouse = require("hs.mouse")
--     local pos = mouse.absolutePosition()
--     print("mouse pos", inspect(pos))
--
--     local canvas = require("hs.canvas")
--     local width = 50
--     local rect = canvas.new({ x = pos.x - width / 2, y = pos.y - width / 2, w = width, h = width })
--         :appendElements({
--             action = "stroke",
--             padding = 0,
--             type = "rectangle",
--             fillColor = { red = 1, blue = 0, green = 0 },
--             strokeColor = { red = 1, blue = 0, green = 0 },
--             strokeWidth = 8,
--         }):show()
--
--     local timer = hs.timer.doAfter(3, function()
--         rect:delete()
--         print("rect deleted")
--     end)
--     timer:start()
-- end)
