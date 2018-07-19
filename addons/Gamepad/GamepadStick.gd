tool
extends Control

const INVALID_ANGLE = -99

enum STICK_TYPE { _ANALOG, _DIGITAL_8, _DIGITAL_4_PLUS, _DIGITAL_4_X, _DIGITAL_4_ISO, _LEFT_RIGHT, _UP_DOWN }
enum DIGITAL_DIRECTIONS { UP, LEFT, DOWN, RIGHT }

onready var bg = $StickBackground
onready var stick = $Stick
onready var fader = $ShowHideAnimation

export var disabled = false
export var show_dynamically = false setget _set_show_dynamically
export var gamepad_type = "STICK 0"
export(STICK_TYPE) var stick_type = STICK_TYPE._ANALOG
export(Texture) var background_texture setget _set_bg_texture, _get_bg_texture
export(Texture) var stick_texture setget _set_texture, _get_texture
export(Vector2) var stick_scale setget _set_scale, _get_scale
export var static_position = Vector2(0, 0)
export var hide_stick_on_stop = false
export var adjust_iso = 0
export var valid_threshold = 0.2
export var step = 0.0

var center_point = Vector2(0,0)
var current_force = Vector2(0,0)
var half_size = Vector2()
var half_stick = Vector2()
var stick_pos = Vector2()
var squared_half_size_length = 0

var finger_data = null
var angle = -1
var direction = []

signal gamepad_force_changed(current_force, sender)
signal gamepad_stick_released

func _init():
	if get_child_count() > 0: return
	var gamepad_stick_template = load("res://addons/Gamepad/GamepadStickTemplate.tscn").instance()
	if gamepad_stick_template.get_child_count() > 0:
		for child in gamepad_stick_template.get_children():
			add_child(child.duplicate())

func _ready():
	if show_dynamically:
		_hide_stick()
	rect_position = static_position
	half_size = bg.rect_size / 2
	center_point = half_size	
	stick.position = half_size
	half_stick = (stick.texture.get_size() * stick.scale) / 2
	squared_half_size_length = half_size.x * half_size.y

func _get_scale():
#	if !has_node("Stick"): return Vector2(1.0, 1.0)
	return $Stick.scale

func _set_scale(value):
#	if !has_node("Stick"): return
	$Stick.scale = value
	$Stick.position = $StickBackground.rect_size / 2

func _get_bg_texture():
#	if !has_node("StickBackground"): return null
	return $StickBackground.texture

func _set_bg_texture(value):
#	if !has_node("StickBackground"): return
	$StickBackground.texture = value	
	$Stick.position = $StickBackground.rect_size / 2

func _get_texture():
#	if !has_node("Stick"): return null
	return $Stick.texture
	
func _set_texture(value):
#	if !has_node("Stick"): return
	$Stick.texture = value
	$Stick.position = $StickBackground.rect_size / 2

func _set_show_dynamically(value):
	show_dynamically = value
	if Engine.editor_hint: return
	if value:
		_hide_stick()
	else:
		_show_stick(null)

func get_force():
	return current_force
	
func handle_down_event(event, finger):
	if disabled:
		reset()
		return
	finger_data = finger
	print (finger_data.to_string())
	if show_dynamically:
		_show_stick(event)
		
	if bg.get_global_rect().has_point(event.position):
		calculate(event)
	else:
		reset()
	
func handle_up_event(event, finger):
	if disabled:
		reset()
		return
	finger_data = finger
	if show_dynamically:
		_hide_stick()
		
	reset()
	emit_signal("gamepad_stick_released")
	
func handle_move_event(event, finger):
	if disabled:
		reset()
		return
	finger_data = finger
	calculate(event)
	
func calculate(event):
	var pos = event.position - rect_global_position
	calculate_force(pos)
	update_stick_pos()
	emit()

func calculate_force(pos):
#	print ("pos: ", pos, " - center_point: ", center_point, " - half_size: ", half_size) 
	current_force.x = (pos.x - center_point.x) / half_size.x
	current_force.y = (pos.y - center_point.y) / half_size.y
	if current_force.length_squared() > 1:
		current_force = current_force / current_force.length()
	if (current_force.length() < valid_threshold):
		current_force = Vector2(0,0) 
	select_force()

func update_stick_pos():
	stick_pos.x = center_point.x + half_size.x * current_force.x
	stick_pos.y = center_point.y + half_size.y * current_force.y
	adjust_stick_pos()
	stick.position = Vector2(stick_pos)
	angle = stick.position.angle_to_point(center_point)
	if hide_stick_on_stop and current_force.x == 0 and current_force.y == 0:
		stick.hide()
	else:
		stick.show()

func reset():
	calculate_force(center_point)
	update_stick_pos()
	angle = INVALID_ANGLE
#	emit()
	
func emit():
	emit_signal("gamepad_force_changed", current_force, self)

func adjust_stick_pos():
	if stick_type != STICK_TYPE._ANALOG and stick_type != null:
		if stick_type == STICK_TYPE._DIGITAL_4_ISO and adjust_iso != 0 and current_force.y == -1:
			if stick_pos.x < half_stick.x + adjust_iso:
				stick_pos.x = half_stick.x + adjust_iso
			elif stick_pos.x > rect_size.x - half_stick.x - adjust_iso:
				stick_pos.x = rect_size.x - half_stick.x - adjust_iso
		else:
			if stick_pos.x < half_stick.x:
				stick_pos.x = half_stick.x
			elif stick_pos.x > rect_size.x - half_stick.x:
				stick_pos.x = rect_size.x - half_stick.x
		if stick_pos.y < half_stick.y:
			stick_pos.y = half_stick.y
		elif stick_pos.y > rect_size.y - half_stick.y:
			stick_pos.y = rect_size.y - half_stick.y

func select_force():
	match stick_type:
		STICK_TYPE._DIGITAL_8:
			to_digital()
		STICK_TYPE._DIGITAL_4_PLUS:
			if abs(current_force.x) > abs(current_force.y):
				current_force.y = 0
			else:
				current_force.x = 0
			to_digital()
		STICK_TYPE._DIGITAL_4_X, STICK_TYPE._DIGITAL_4_ISO:
			var curr = Vector2(current_force.x, current_force.y)
			to_digital()
			if abs(current_force.x) == 1:
				if curr.y > 0.35:
					current_force.y = 1
				else:
					current_force.y = -1
			else:
				if abs(current_force.y) == 1:
					if curr.x > 0.35:
						current_force.x = 1
					else:
						current_force.x = -1
		STICK_TYPE._LEFT_RIGHT:
			current_force.y = 0
			to_steps()
		STICK_TYPE._UP_DOWN:
			current_force.x = 0
			to_steps()
		_:
			to_steps()
	direction = []
	if current_force.x == -1:
		direction.append(DIGITAL_DIRECTIONS.LEFT)
	elif current_force.x == 1:
		direction.append(DIGITAL_DIRECTIONS.RIGHT)
	if current_force.y == -1:
		direction.append(DIGITAL_DIRECTIONS.UP)
	elif current_force.y == 1:
		direction.append(DIGITAL_DIRECTIONS.DOWN)
		

func to_steps():
	if step <= 0:
		return
	if step >= 1:
		to_digital()
		return
	var modx = int(current_force.x / step) * step if abs(current_force.x) < 0.99 else 1 * sign(current_force.x)
	var mody = int(current_force.y / step) * step if abs(current_force.y) < 0.99 else 1 * sign(current_force.y)
	current_force = Vector2(modx, mody)

func to_digital():
	current_force = current_force.normalized()
	current_force.x = stepify(current_force.x, 1)
	current_force.y = stepify(current_force.y, 1)

func _show_stick(event):
	if event:
		rect_global_position = event.position - center_point
	else:
		rect_position = static_position
	if fader:
		reset()
		fader.stop()
		fader.play("fade_in", -1, 10)
	
func _hide_stick():
	if fader:
		fader.stop()
		fader.play("fade_out", -1, 10)
