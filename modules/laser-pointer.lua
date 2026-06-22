local mouse_circle = nil
local mouse_circle_timer = nil

function mouse_highlight()
	-- Delete an existing highlight if it exsits
	if mouse_circle then
		mouse_circle:delete()
		if mouse_circle_timer then
			mouse_circle_timer:stop()
		end
	end

	-- Get the current coordinates of the mouse pointer
	mouse_point = hs.mouse.absolutePosition()
	-- Prepare a big red circle around the mouse pointer
	local mouse_radius = 20
	mouse_circle = hs.drawing.circle(
		hs.geometry.rect(mouse_point.x - mouse_radius, mouse_point.y - mouse_radius, 2 * mouse_radius, 2 * mouse_radius)
	)
	mouse_circle:setStrokeColor({ ["red"] = 1, ["blue"] = 0, ["green"] = 0, ["alpha"] = 1 })
	mouse_circle:setFill(false)
	mouse_circle:setStrokeWidth(5)
	mouse_circle:show()

	-- Set a timer to delete the circle after 3 seconds
	mouse_circle_timer = hs.timer.doAfter(3, function()
		mouse_circle:delete()
		mouse_circle = nil
	end)
end
hs.hotkey.bind({ "cmd", "alt", "shift" }, "M", mouse_highlight)
