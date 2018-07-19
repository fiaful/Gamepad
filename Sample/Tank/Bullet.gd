extends KinematicBody2D

export var speed = 300

var halfPI = PI / 2
var direction = Vector2()

func shot(_angle):
	rotation = _angle
	direction = Vector2(0, -1).rotated(_angle).normalized()
	
func _process(delta):
	position += direction * speed * delta
	
func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
