extends KinematicBody2D

onready var turret = $Turret
onready var fire_timer = $Turret/FireTimer
onready var bullet_spawn_pos = $Turret/Position2D

export(PackedScene) var bullet = null

# movimento
var engine = Vector2()
var engine_speed = 150

var halfPI = PI / 2

var screen_bounds = Vector2()
var margin = 50
var reset = false

func _ready():
	screen_bounds = get_viewport().get_visible_rect().size
	
func _process(delta):
	position += engine * delta
	if position.x < -margin:
		position.x = screen_bounds.x + margin
	elif position.x > screen_bounds.x + margin:
		position.x = -margin
	if position.y < -margin:
		position.y = screen_bounds.y + margin
	elif position.y > screen_bounds.y + margin:
		position.y = -margin
	if reset:
		engine = Vector2()

func _on_move(current_force, sender):
	if sender.angle != sender.INVALID_ANGLE and sender.angle != 0:
		rotation = sender.angle

	engine = Vector2(engine_speed, 0).rotated(rotation)

func _on_fire(current_force, sender):
#	print (sender.angle)
	if sender.angle != sender.INVALID_ANGLE and sender.angle != 0:
		turret.rotation = halfPI + sender.angle - rotation
	if fire_timer.is_stopped():
		fire_timer.start()

func _on_stop():
	engine = Vector2(0, 0)

func _on_stop_fire():
	fire_timer.stop()

func _on_FireTimer_timeout():
	var b = bullet.instance()
	b.position = bullet_spawn_pos.global_position
	get_parent().add_child(b)
	b.shot(turret.rotation + rotation)

func _on_rotate(current_angle, sender):
	rotation = current_angle - PI

func _on_button_fire(sender):
	_on_FireTimer_timeout()

func _on_button_engine(sender):
	reset = true
	engine = Vector2(-engine_speed, 0).rotated(rotation)

func _on_updown(current_force, sender):
	reset = false
	if sender.UP in sender.direction:
		engine = Vector2(-engine_speed, 0).rotated(rotation)
	elif sender.DOWN in sender.direction:
		engine = Vector2(engine_speed, 0).rotated(rotation)
	else:
		engine = Vector2(0, 0)

func _on_updown_stop():
	engine = Vector2(0, 0)
