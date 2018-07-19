tool
extends Control

onready var button = $ButtonFace
onready var timer = $AutofireTimer
onready var fader = $ShowHideAnimation

export var disabled = false setget _set_disabled
export var show_dynamically = false setget _set_show_dynamically
export var gamepad_type = "BUTTON 0"
export(Texture) var texture_normal setget _set_texture_normal, _get_texture_normal
export(Texture) var texture_pressed setget _set_texture_pressed, _get_texture_pressed
export(Texture) var texture_disabled setget _set_texture_disabled, _get_texture_disabled
export var static_position = Vector2(0, 0)
export var autofire_delay = 0.0

signal down(sender)
signal up(sender)
signal fire(sender)

var center_point = Vector2(0,0)

var finger_data = null
var is_pressed = false

func _init():
	if get_child_count() > 0: return
	var gamepad_button_template = load("res://addons/Gamepad/GamepadButtonTemplate.tscn").instance()
	if gamepad_button_template.get_child_count() > 0:
		for child in gamepad_button_template.get_children():
			if child is Timer:
				var tmr = child.duplicate()
				add_child(tmr)
				tmr.connect("timeout", self, "_on_AutofireTimer_timeout")
			else:
				add_child(child.duplicate())

func _ready():
	rect_position = static_position
	center_point = self.rect_size / 2
	if show_dynamically:
		_hide_button()

func _get_texture_normal():
	return $ButtonFace.texture_normal
	
func _set_texture_normal(value):
#	if !has_node("ButtonFace"): return
	$ButtonFace.texture_normal = value

func _get_texture_pressed():
	return $ButtonFace.texture_pressed
	
func _set_texture_pressed(value):
#	if !has_node("ButtonFace"): return
	$ButtonFace.texture_pressed = value

func _get_texture_disabled():
	return $ButtonFace.texture_disabled
	
func _set_texture_disabled(value):
#	if !has_node("ButtonFace"): return
	$ButtonFace.texture_disabled = value

func _set_disabled(value):
	disabled = value
#	if !has_node("ButtonFace"): return
	$ButtonFace.disabled = value
	
func _set_show_dynamically(value):
	show_dynamically = value
	if Engine.editor_hint: return
	if value:
		_hide_button()
	else:
		_show_button(null)

func handle_down_event(event, finger):
	if disabled:
		return
	finger_data = finger
	if show_dynamically:
		_show_button(event)
	
	button.pressed = true
	is_pressed = true
	emit_signal("down", self)
	emit_signal("fire", self)
	if autofire_delay > 0:
		timer.wait_time = autofire_delay
		timer.start()
	
func handle_up_event(event, finger):
	if disabled:
		return
	finger_data = finger
	if show_dynamically:
		_hide_button()

	button.pressed = false
	is_pressed = false
	emit_signal("up", self)
	timer.stop()
	
func handle_move_event(event, finger):
	if disabled:
		return

func _on_AutofireTimer_timeout():
	emit_signal("fire", self)

func _show_button(event):
	if event:
		rect_global_position = event.position - center_point
	else:
		rect_position = static_position
	if fader:
		fader.stop()
		fader.play("fade_in", -1, 10)
	
func _hide_button():
	if fader:
		fader.stop()
		fader.play("fade_out", -1, 10)
