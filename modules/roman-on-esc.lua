-- ID of the target application.
local targetAppBundleID = "com.mitchellh.ghostty"

-- If a listener already exists upon reloading the config, stop it to prevent conflicts.
if escape_keyevent then
    escape_keyevent:stop()
end

-- Create a new event tap listener for key down events.
escape_keyevent = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
    local flags = event:getFlags()
    local keycode = hs.keycodes.map[event:getKeyCode()]
    local frontApp = hs.application.frontmostApplication()

    -- 1. First, check if a key was pressed within the target application.
    if frontApp and frontApp:bundleID() == targetAppBundleID then

        -- 2. Check if the pressed key is ESC or the Ctrl+C combination.
        if keycode == 'escape' or (keycode == 'c' and flags.ctrl) then

            -- Add a 0.05-second delay to resolve timing issues.
            hs.timer.doAfter(0.03, function()
                local input_english = "com.apple.keylayout.ABC"
                local current_source = hs.keycodes.currentSourceID()

                -- [CASE 1] If the ESC key was pressed (original logic).
                if keycode == 'escape' then
                    if current_source ~= input_english then
                        hs.keycodes.currentSourceID(input_english)
                        -- print("ESC pressed: Switched to English.")
                    end

                -- [CASE 2] If the Ctrl+[ key combination was pressed (new logic).
                elseif keycode == '[' and flags.ctrl then
                    -- Perform this special action only if the current input source is not English.
                    if current_source ~= input_english then
                        -- print("Ctrl+[ (in non-English): Intercepted.")
                        -- a. Change the input source to English.
                        hs.keycodes.currentSourceID(input_english)
                        -- b. Simulate an ESC key press.
                        hs.eventtap.keyStroke({}, 'escape')
                        -- print("--> Switched to English and sent ESC.")
                        -- c. Block the original Ctrl+C event from being processed. (Crucial)
                        return true
                    end
                end
            end)
        end
    end

    -- Allow all other key events to pass through.
    return false
end)

-- Start the listener.
escape_keyevent:start()
