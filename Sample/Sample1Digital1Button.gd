extends Node

onready var gamepad = $Gamepad/GamepadContainer/GamepadArea/GamepadStick
onready var button_fire = $Gamepad/GamepadContainer/GamepadArea2/GamepadButton

func _ready():
	gamepad.show_dynamically = true
	button_fire.show_dynamically = true

func _on_CheckBox_toggled(button_pressed):
	gamepad.show_dynamically = button_pressed
	button_fire.show_dynamically = button_pressed


func _on_Button_pressed():
	get_tree().change_scene("res://Sample/MainMenu.tscn")
