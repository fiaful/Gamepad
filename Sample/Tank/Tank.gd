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
	print (current_force, " - ", sender.angle)
	if sender.direction == []:
		engine = Vector2(0, 0).rotated(rotation)
		return
		
	if sender.angle != sender.INVALID_ANGLE: # and sender.angle != 0:
		rotation = sender.angle

	engine = Vector2(engine_speed, 0).rotated(rotation)

func _on_move_digital(current_force, sender):
	print (current_force, " - ", sender.angle)
	engine = current_force * engine_speed
	if sender.direction.size() > 0:
		rotation = sender.angle

func _on_fire(current_force, sender):
	print (current_force, " - ", sender.angle)
	if sender.angle != sender.INVALID_ANGLE: # and sender.angle != 0:
		turret.rotation = halfPI + sender.angle - rotation
	if fire_timer.is_stopped():
		fire_timer.start()

func _on_stop():
	print ("stop")
	engine = Vector2(0, 0)

func _on_stop_fire():
	print ("fire stop")
	fire_timer.stop()

func _on_FireTimer_timeout():
	var b = bullet.instance()
	b.position = bullet_spawn_pos.global_position
	get_parent().add_child(b)
	b.shot(turret.rotation + rotation)

func _on_rotate(current_angle, sender):
	print (current_angle)
	rotation = current_angle - PI

func _on_button_fire(sender):
	print ("fire!")
	_on_FireTimer_timeout()

func _on_button_engine(sender):
	print ("engine")
	reset = true
	engine = Vector2(-engine_speed, 0).rotated(rotation)

func _on_updown(current_force, sender):
	print (current_force, " - ", sender.angle)
	reset = false
	if sender.UP in sender.direction:
		engine = Vector2(-engine_speed, 0).rotated(rotation)
	elif sender.DOWN in sender.direction:
		engine = Vector2(engine_speed, 0).rotated(rotation)
	else:
		engine = Vector2(0, 0)

func _on_updown_stop():
	print ("stop")
	engine = Vector2(0, 0)
