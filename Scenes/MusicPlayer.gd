extends AudioStreamPlayer

var SCREENSHOTS_ENABLED = false
var screenshotNumber = 0

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_select"):
		takeScreenshot()

func takeScreenshot():
	if SCREENSHOTS_ENABLED:
		var screenshot = get_viewport().get_texture().get_data()
		screenshot.save_png("c:/Screenshots/DirtCave/screenshot" + str(screenshotNumber) + ".png")
		print("screenshot" + str(screenshotNumber) + " saved")
		screenshotNumber += 1
