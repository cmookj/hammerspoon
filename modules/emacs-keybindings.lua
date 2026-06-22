local inputSource = {
	english = "com.apple.keylayout.ABC",
	korean = "com.apple.inputmethod.Korean.3SetKorean",
}

local events = hs.eventtap.event.types
keyboardTracker = hs.eventtap.new({ events.keyDown }, function(e)
	local currentIM = hs.keycodes.currentSourceID()

	-- If current input method is NOT Korean, simply return and ask
	-- macOS to process the key event.
	if currentIM ~= inputSource.korean then
		return false
	end

	-- From now on, currentIM is inputSource.korean
	local modifiers = e:getFlags()

	if modifiers.ctrl == true then
		local keyCode = e:getKeyCode()

		-- Handle simple key bindings using system-wide shortcuts
		-- Left, Right, Up, and Down arrows
		if keyCode == 11 then -- 'b'
			hs.eventtap.event.newKeyEvent({}, "left", true):post()
			return true
		end

		if keyCode == 3 then -- 'f'
			hs.eventtap.event.newKeyEvent({}, "right", true):post()
			return true
		end

		if keyCode == 35 then -- 'p'
			hs.eventtap.event.newKeyEvent({}, "up", true):post()
			return true
		end

		if keyCode == 45 then -- 'n'
			hs.eventtap.event.newKeyEvent({}, "down", true):post()
			return true
		end

		-- Forward and backward delete
		if keyCode == 2 then -- 'd'
			hs.eventtap.event.newKeyEvent({}, "forwarddelete", true):post()
			return true
		end

		if keyCode == 4 then -- 'h'
			hs.eventtap.event.newKeyEvent({}, "delete", true):post()
			return true
		end

		-- The following section does not work so well. (2024.03.31)
		--
		-- Other key bindings: ctrl-a, ctrl-e, ctrl-k, ctrl-y, ctrl-l
		-- Key codes for these bindings: a = 0, e = 14, k = 40, y = 16
		-- These key bindings are hard to mimic using system-wide shortcuts.
		-- Ask these to english input method to process.
		hs.keycodes.currentSourceID(inputSource.english)

		-- According to Apple Documentation, the proper way to perform a keypress
		-- with modifiers is through multiple key events.
		-- hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, true):post()
		-- hs.eventtap.event.newKeyEvent(keyCode, true):post()
		-- hs.eventtap.event.newKeyEvent(keyCode, false):post()
		-- hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, false):post()

		hs.timer.doAfter(0.05, function()
			hs.keycodes.currentSourceID(inputSource.korean)
		end)
		return false
	end
end)

keyboardTracker:start()
