tool
extends EditorPlugin

func _enter_tree():
	# 120 - 80 - 70 (colora)
	add_custom_type("GamepadContainer", "Control", preload("GamepadContainer.gd"), preload("icons/container.png"))
	add_custom_type("GamepadArea", "Control", preload("GamepadArea.gd"), preload("icons/area.png"))
	add_custom_type("GamepadStick", "Control", preload("GamepadStick.gd"), preload("icons/stick.png"))
	add_custom_type("GamepadPaddle", "Control", preload("GamepadPaddle.gd"), preload("icons/paddle.png"))
	add_custom_type("GamepadButton", "Control", preload("GamepadButton.gd"), preload("icons/button.png"))

func _exit_tree():
	remove_custom_type("GamepadContainer")
	remove_custom_type("GamepadArea")
	remove_custom_type("GamepadStick")
	remove_custom_type("GamepadPaddle")
	remove_custom_type("GamepadButton")
