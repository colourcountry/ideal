function love.conf(t)
	t.console = true
	t.identity = "ideal-5" --save dir in the internal storage
	t.accelerometerjoystick = false -- Enable the accelerometer on iOS and Android by exposing it as a Joystick (boolean)
	t.externalstorage = true -- True to save files (and read from the save directory) in external storage on Android (boolean)

	t.window.title = "IDEAL 5"
	t.window.resizable = true -- Let the window be user-resizable (boolean)
	t.window.minwidth = 480 --if vertical(portrait)
	t.window.minheight = 480 --if horizontal(landscape)

        t.modules.sound = false
        t.audio.mixwithsystem = true --keep the user's tunes going

	love.fps = 30
end
