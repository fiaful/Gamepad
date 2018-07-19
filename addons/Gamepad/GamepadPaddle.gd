tool
extends Control

const INVALID_ANGLE = -99

onready var bg = $PaddleBackground
onready var paddle = $Paddle
onready var fader = $ShowHideAnimation

export var disabled = false
export var show_dynamically = false setget _set_show_dynamically
export var gamepad_type = "PADDLE 0"
export(Texture) var background_texture setget _set_bg_texture, _get_bg_texture
export(Texture) var paddle_texture setget _set_texture, _get_texture
export(Vector2) var paddle_scale setget _set_scale, _get_scale
export var static_position = Vector2(0, 0)
export var valid_threshold = 0.2
export var reset_on_release = true
export var low_limit = 0
export var high_limit = 0

var center_point = Vector2(0,0)
var current_force = Vector2(0,0)
var half_size = Vector2()
var squared_half_size_length = 0
var into_limits = false

var finger_data = null
var angle = -1

signal angle_changed(current_angle, sender)
signal paddle_released

func _init():
	if get_child_count() > 0: return
	var gamepad_paddle_template = load("res://addons/Gamepad/GamepadPaddleTemplate.tscn").instance()
	if gamepad_paddle_template.get_child_count() > 0:
		for child in gamepad_paddle_template.get_children():
			add_child(child.duplicate())

func _ready():
	if show_dynamically:
		_hide_paddle()
	rect_position = static_position	
	half_size = bg.rect_size / 2
	center_point = half_size	
	paddle.position = half_size
	squared_half_size_length = half_size.x * half_size.y

func _get_scale():
	return $Paddle.scale

func _set_scale(value):
#	if !has_node("Paddle"): return
	$Paddle.scale = value
	$Paddle.position = $PaddleBackground.rect_size / 2

func _get_bg_texture():
	return $PaddleBackground.texture

func _set_bg_texture(value):
#	if !has_node("PaddleBackground"): return
	$PaddleBackground.texture = value	
	$Paddle.position = $PaddleBackground.rect_size / 2

func _get_texture():
	return $Paddle.texture
	
func _set_texture(value):
#	if !has_node("PaddleBackground"): return
	$Paddle.texture = value
	$Paddle.position = $PaddleBackground.rect_size / 2

func _set_show_dynamically(value):
	show_dynamically = value
	if Engine.editor_hint: return
	if value:
		_hide_paddle()
	else:
		_show_paddle(null)

func get_force():
	return current_force
	
func handle_down_event(event, finger):
	if disabled:
		reset()
		return
	finger_data = finger
	if show_dynamically:
		_show_paddle(event)
		
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
		_hide_paddle()
		
	reset()
	emit_signal("paddle_released")
	
func handle_move_event(event, finger):
	if disabled:
		reset()
		return
	finger_data = finger
	calculate(event)
	
func calculate(event):
	var pos = event.position - rect_global_position
	calculate_force(pos)
	update_paddle_pos()
	emit()

func calculate_force(pos):
#	print ("pos: ", pos, " - center_point: ", center_point, " - half_size: ", half_size) 
	current_force.x = (pos.x - center_point.x) / half_size.x
	current_force.y = (pos.y - center_point.y) / half_size.y
	if current_force.length_squared() > 1:
		current_force = current_force / current_force.length()
	if (current_force.length() < valid_threshold):
		current_force = Vector2(0,0) 

func update_paddle_pos():
	var x = center_point.x + half_size.x * current_force.x
	var y = center_point.y + half_size.y * current_force.y
	var new_angle = Vector2(x, y).angle_to_point(center_point)
	into_limits = false
	var deg_angle = rad2deg(new_angle) + 180
#	print ([deg_angle, low_limit, high_limit])
	if low_limit != high_limit:
		if low_limit > high_limit:
			if deg_angle <= high_limit:
				into_limits = true
			if deg_angle >= low_limit:
				if deg_angle >= high_limit:
					into_limits = true
		else:
			if deg_angle <= high_limit and deg_angle >= low_limit:
				into_limits = true
	else:
		into_limits = true
		
	if into_limits:
		angle = new_angle
		paddle.rotation = angle

func reset():
	if !reset_on_release: return
	calculate_force(center_point)
	update_paddle_pos()
	angle = INVALID_ANGLE
#	emit()
	
func emit():
	if into_limits:
		emit_signal("angle_changed", angle, self)
#	print (angle / PI * 180)
#	print (rad2deg(angle) + 180)

func _show_paddle(event):
#	print (event)
	if event:
		rect_global_position = event.position - center_point
	else:
		rect_position = static_position
	if fader:
		reset()
		fader.stop()
		fader.play("fade_in", -1, 10)
	
func _hide_paddle():
	if fader:
		fader.stop()
		fader.play("fade_out", -1, 10)
