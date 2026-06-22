-- Default modifier key set
local hyper = { "control", "shift", "option" }

-- Frequently used application list
local frequentApps = {
	"Finder",
	-- 	"WezTerm",
	-- 	"Safari",
	-- 	"Firefox",
	-- 	"Telegram",
	-- 	"Messages",
	"TextEdit",
	"Stickies",
	"YouTube",
}

local chooser = hs.chooser.new(function(choice)
	if choice ~= nil then
		hs.alert.show(choice.text)

		launchApp(choice.text)
	end
end)

function launchApp(name)
	hs.application.launchOrFocus(name)

	-------------------
	-- Special cases --
	-------------------

	-- Finder: simply activate it
	if name == "Finder" then
		hs.appfinder.appFromName(name):activate()
	end

	-- TextEdit: open a new document
	if name == "TextEdit" then
		local app = hs.appfinder.appFromName(name)
		app:selectMenuItem({ "File", "New" })
	end

	-- Stickies: open a new memo
	if name == "Stickies" then
		local app = hs.appfinder.appFromName(name)
		app:selectMenuItem({ "File", "New Note" })
	end

	if name == "YouTube" then
		hs.execute("open -a firefox -g https://www.youtube.com")
		hs.application.launchOrFocus("Firefox")
	end
end

hs.hotkey.bind(hyper, "]", function()
	local list = {}

	for key, value in pairs(frequentApps) do
		local imageFile = hs.image.imageFromPath("~/.hammerspoon/images/" .. value .. ".png")
		table.insert(list, {
			text = value,
			-- subText = "",
			image = imageFile,
		})
	end

	chooser:width(10)
	chooser:choices(list)
	chooser:show()
end)
