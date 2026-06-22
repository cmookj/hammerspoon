hyper = {"ctrl", "alt", "cmd"}

-- auto reload config
configFileWatcher = hs.pathwatcher.new(hs.configdir, hs.reload):start()

-- Assign a short cut to the 'Reload Config' menu command
hs.hotkey.bind ({'option', 'cmd'}, 'r', hs.reload)
