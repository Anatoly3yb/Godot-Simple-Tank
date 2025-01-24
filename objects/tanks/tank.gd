extends RigidBody3D

const SENSITIVE = 0.5

@onready var camera_pivot = $SpringArm3D

@export var suspension_rest_dist: float = 0.5
@export var spring_strength: float = 10
@export var spring_damper: float = 1
@export var wheel_radius: float = 0.5

@export var debug: bool = false

@export var engine_power: float

var accel_input: float
var rotation_input: float

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _unhandled_input(e):
	if e is InputEventMouseMotion:
		camera_pivot.rotate_y(deg_to_rad(-e.relative.x * SENSITIVE))
		camera_pivot.rotation_degrees.x += e.relative.y * SENSITIVE
		camera_pivot.rotation_degrees.x = clamp(camera_pivot.rotation_degrees.x, -15, 45)

func _physics_process(delta) -> void:
	$CanvasLayer/Speedometr.text = str(round(linear_velocity.length() * 3.6)) + " Km/h"
	
	camera_pivot.position.y = global_position.y + 3.0
	accel_input = Input.get_axis("ui_up", "ui_down")
	rotation_input = Input.get_axis("ui_right", "ui_left")

	camera_pivot.global_position = camera_pivot.global_position.lerp(global_position, delta * 20.0)
