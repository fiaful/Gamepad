extends Node

onready var checks = [
		$Control/MarginContainer/HBoxContainer/chk0,
		$Control/MarginContainer/HBoxContainer/chk1,
		$Control/MarginContainer/HBoxContainer/chk2,
		$Control/MarginContainer/HBoxContainer/chk3,
		$Control/MarginContainer/HBoxContainer/chk4
]

onready var labels = [
		$Control/MarginContainer2/HBoxContainer/HBoxContainer/pos0,
		$Control/MarginContainer2/HBoxContainer/HBoxContainer2/pos1,
		$Control/MarginContainer2/HBoxContainer/HBoxContainer3/pos2,
		$Control/MarginContainer2/HBoxContainer/HBoxContainer4/pos3,
		$Control/MarginContainer2/HBoxContainer/HBoxContainer5/pos4
]

var positions = [
		Vector2(),
		Vector2(),
		Vector2(),
		Vector2(),
		Vector2()
]

onready var force = $Control/Force
onready var logger = $Control/TextEdit

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func _on_GamepadContainer_finger_down(finger_data):
	checks[finger_data.index].pressed = finger_data.pressed
	labels[finger_data.index].text = finger_data.to_string()

func _on_GamepadContainer_finger_up(finger_data):
	checks[finger_data.index].pressed = finger_data.pressed
	labels[finger_data.index].text = str(Vector2())

func _on_GamepadContainer_finger_move(finger_data):
	checks[finger_data.index].pressed = finger_data.pressed
	labels[finger_data.index].text = finger_data.to_string()


func _on_Button0_down(sender):
	var text = "%s - DOWN" % [sender.gamepad_type, ]
	logger.text = text + "\n" + logger.text

func _on_Button0_up(sender):
	var text = "%s - UP" % [sender.gamepad_type, ]
	logger.text = text + "\n" + logger.text

func _on_Button0_fire(sender):
	var text = "%s - FIRE!" % [sender.gamepad_type, ]
	logger.text = text + "\n" + logger.text


func _on_Button1_down(sender):
	var text = "%s - DOWN" % [sender.gamepad_type, ]
	logger.text = text + "\n" + logger.text

func _on_Button1_up(sender):
	var text = "%s - UP" % [sender.gamepad_type, ]
	logger.text = text + "\n" + logger.text

func _on_Button1_fire(sender):
	var text = "%s - FIRE!" % [sender.gamepad_type, ]
	logger.text = text + "\n" + logger.text


func _on_GamepadStick_gamepad_force_changed(current_force, sender):
	force.text = str(current_force)


func _on_Button_pressed():
	get_tree().change_scene("res://Sample/MainMenu.tscn")
