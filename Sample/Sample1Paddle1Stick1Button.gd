extends Node

onready var gamepaddle = $Gamepad/GamepadContainer/GamepadArea/GamepadPaddle
onready var button_fire = $Gamepad/GamepadContainer/GamepadArea2/GamepadButton
onready var engine = $Gamepad/GamepadContainer/GamepadArea3/GamepadStick

func _ready():
	gamepaddle.show_dynamically = true
	button_fire.show_dynamically = true
	engine.show_dynamically = true

func _on_CheckBox_toggled(button_pressed):
	gamepaddle.show_dynamically = button_pressed
	button_fire.show_dynamically = button_pressed
	engine.show_dynamically = button_pressed


func _on_Button_pressed():
	get_tree().change_scene("res://Sample/MainMenu.tscn")
