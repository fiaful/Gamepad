extends Node

onready var left_gamepad = $Gamepad/GamepadContainer/GamepadArea/GamepadStick
onready var right_gamepad = $Gamepad/GamepadContainer/GamepadArea2/GamepadStick
onready var fire = $Gamepad/GamepadContainer/GamepadArea3/GamepadButton

func _ready():
	left_gamepad.show_dynamically = true
	right_gamepad.show_dynamically = true
	fire.show_dynamically = true

func _on_CheckBox_toggled(button_pressed):
	left_gamepad.show_dynamically = button_pressed
	right_gamepad.show_dynamically = button_pressed
	fire.show_dynamically = button_pressed

func _on_Button_pressed():
	get_tree().change_scene("res://Sample/MainMenu.tscn")
