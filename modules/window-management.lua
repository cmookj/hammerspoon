-- hs.window.animationDuration = 0.01

local function move_win(xx, yy, ww, hh)
  return function()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local max = win:screen():frame()

    -- hs.printf("BEFORE")
    -- hs.printf("  Screen frame (x, y, w, h) = %d, %d, %d, %d", max.x, max.y, max.w, max.h)
    -- hs.printf("  Window frame (x, y, w, h) = %d, %d, %d, %d", f.x, f.y, f.w, f.h)

    f.x = max.x + max.w * xx
    f.y = max.y + max.h * yy
    f.w = max.w * ww
    f.h = max.h * hh

    -- hs.printf("AFTER")
    -- hs.printf("  Screen frame (x, y, w, h) = %d, %d, %d, %d", max.x, max.y, max.w, max.h)
    -- hs.printf("  Window frame (x, y, w, h) = %d, %d, %d, %d", f.x, f.y, f.w, f.h)
    win:setFrame(f)
  end
end

local function resize_win(cmd)
  return function()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local max = win:screen():frame()

    -- hs.printf("BEFORE")
    -- hs.printf("  Screen frame (x, y, w, h) = %d, %d, %d, %d", max.x, max.y, max.w, max.h)
    -- hs.printf("  Window frame (x, y, w, h) = %d, %d, %d, %d", f.x, f.y, f.w, f.h)

    local incr_w = math.floor(max.w / 10)
    local incr_h = math.floor(max.h / 10)

    local min_w = incr_w
    local min_h = incr_h

    if cmd == "wider" then
      f.w = f.w + incr_w
      if f.w > max.w then
        f.w = max.w
      end

      if f.x + f.w > max.x + max.w then
        f.x = max.x + max.w - f.w
      end

      win:setFrame(f)
    end

    if cmd == "narrower" then
      f.w = f.w - incr_w
      if f.w < min_w then
        f.w = min_w
      end
    end

    if cmd == "taller" then
      f.h = f.h + incr_h
      if f.h > max.h then
        f.h = max.h
      end

      if f.y + f.h > max.y + max.w then
        f.y = max.y + max.h - f.h
      end
    end

    if cmd == "shorter" then
      f.h = f.h - incr_h
      if f.h < min_h then
        f.h = min_h
      end
    end

    -- hs.printf("AFTER")
    -- hs.printf("  Screen frame (x, y, w, h) = %d, %d, %d, %d", max.x, max.y, max.w, max.h)
    -- hs.printf("  Window frame (x, y, w, h) = %d, %d, %d, %d", f.x, f.y, f.w, f.h)
    win:setFrame(f)
  end
end

local function move_to_display(dir)
  return function()
    local win = hs.window.focusedWindow()

    if (dir == "left") then
      win:moveOneScreenWest()
    elseif (dir == "right") then
      win:moveOneScreenEast()
    elseif (dir == "down") then
      win:moveOneScreenSouth()
    elseif (dir == "up") then
      win:moveOneScreenNorth()
    end
  end
end

local mod = { "option", "ctrl" }
local mod_shift = { "option", "ctrl", "shift" }

hs.hotkey.bind(mod, "h", move_win(0, 0, 1 / 2, 1))
hs.hotkey.bind(mod, "j", move_win(0, 1 / 2, 1, 1 / 2))
hs.hotkey.bind(mod, "k", move_win(0, 0, 1, 1 / 2))
hs.hotkey.bind(mod, "l", move_win(1 / 2, 0, 1 / 2, 1))

hs.hotkey.bind(mod, "1", move_win(0, 1 / 2, 1 / 2, 1 / 2))
hs.hotkey.bind(mod, "3", move_win(1 / 2, 1 / 2, 1 / 2, 1 / 2))
hs.hotkey.bind(mod, "5", move_win(0, 0, 1, 1))
hs.hotkey.bind(mod, "7", move_win(0, 0, 1 / 2, 1 / 2))
hs.hotkey.bind(mod, "9", move_win(1 / 2, 0, 1 / 2, 1 / 2))

hs.hotkey.bind(mod, "right", resize_win("wider"))
hs.hotkey.bind(mod, "left", resize_win("narrower"))
hs.hotkey.bind(mod, "down", resize_win("taller"))
hs.hotkey.bind(mod, "up", resize_win("shorter"))

hs.hotkey.bind(mod_shift, "h", move_to_display("left"))
hs.hotkey.bind(mod_shift, "j", move_to_display("down"))
hs.hotkey.bind(mod_shift, "k", move_to_display("up"))
hs.hotkey.bind(mod_shift, "l", move_to_display("right"))
