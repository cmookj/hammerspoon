local chooser = hs.chooser.new(function(choice)
	if choice ~= nil then
		hs.alert.show(choice.text)

		chooseAudioOutputDevice(choice.text)
	else
		local currentDevice = hs.audiodevice.defaultOutputDevice()
		hs.alert.show(currentDevice:name())
	end
end)

function chooseAudioOutputDevice(name)
	device = hs.audiodevice.findDeviceByName(name)
	if device then
		device:setDefaultOutputDevice()
		device:setDefaultEffectDevice()
	end
end

hs.hotkey.bind({ "control", "shift", "option" }, "a", function()
	-- Get all audio output devices
	local devices = hs.audiodevice.allOutputDevices()
	local list = {}

	local currentDevice = hs.audiodevice.defaultOutputDevice()
	print(currentDevice:name())

	local countDevices = 0
	for key, value in pairs(devices) do
		local selected = ""
		local imageFile = hs.image.imageFromPath("~/.hammerspoon/images/empty.png")
		if value:name() == currentDevice:name() then
			selected = "Current output device"
			imageFile = hs.image.imageFromPath("~/.hammerspoon/images/speaker_high.png")
		end

		table.insert(list, {
			text = value:name(),
			subText = selected,
			image = imageFile,
			-- image = hs.image.imageFromPath(image address .. '.jpg'),
		})

		countDevices = countDevices + 1
	end

	chooser:width(20)
	chooser:rows(countDevices + 1)
	chooser:subTextColor(hs.drawing.color.x11.darkred)
	chooser:choices(list)
	chooser:show()
end)

--
-- Reference Code
--

-- function setMacAsDefaultAudioDevice()
-- 	mic = hs.audiodevice.findDeviceByUID("BuiltInMicrophoneDevice") -- use UID instead of name since it's more stable
-- 	if mic then
-- 		mic:setDefaultInputDevice()
-- 	end
-- 	speakers = hs.audiodevice.findDeviceByUID("BuiltInSpeakerDevice")
-- 	if speakers then
-- 		speakers:setDefaultOutputDevice()
-- 		speakers:setDefaultEffectDevice()
-- 	end
-- 	if speakers and mic then
-- 		hs.alert.show("Changed input and output to Mac")
-- 	else
-- 		hs.alert.show("Couldn't change input and output to Mac")
-- 	end
-- end
--
-- function setHeadphonesAsDefaultAudioDevice()
-- 	headphonesIn = hs.audiodevice.findInputByName("WH-H900N (h.ear)")
-- 	headphonesOut = hs.audiodevice.findOutputByName("WH-H900N (h.ear)")
-- 	if headphonesIn then
-- 		headphonesIn:setDefaultInputDevice()
-- 	end
-- 	if headphonesOut then
-- 		headphonesOut:setDefaultOutputDevice()
-- 		headphonesOut:setDefaultEffectDevice()
-- 	end
-- 	if headphonesIn and headphonesOut then
-- 		hs.alert.show("Changed input and output to Sony headphones")
-- 	else
-- 		hs.alert.show("Couldn't change input and output to Sony headphones")
-- 	end
-- end
--
-- function setScarlettAsDefaultAudioDevice()
-- 	scarlett = hs.audiodevice.findDeviceByName("Scarlett 2i2 USB")
-- 	if scarlett then
-- 		scarlett:setDefaultInputDevice()
-- 		scarlett:setDefaultOutputDevice()
-- 		scarlett:setDefaultEffectDevice()
-- 		hs.alert.show("Changed input and output to Scarlett")
-- 	else
-- 		hs.alert.show("Couldn't change input and output to Scarlett")
-- 	end
-- end
--
-- function displayCurrentAudioDevices()
-- 	input = hs.audiodevice.defaultInputDevice()
-- 	if input then
-- 		inputName = input:name()
-- 	else
-- 		inputName = "None"
-- 	end
-- 	output = hs.audiodevice.defaultOutputDevice()
-- 	if output then
-- 		outputName = output:name()
-- 	else
-- 		outputName = "None"
-- 	end
-- 	hs.alert.show(string.format("Input: %s | Output: %s", inputName, outputName))
-- end
--
-- hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "M", setMacAsDefaultAudioDevice)
-- hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "H", setHeadphonesAsDefaultAudioDevice)
-- hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "S", setScarlettAsDefaultAudioDevice)
-- hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "A", displayCurrentAudioDevices)
