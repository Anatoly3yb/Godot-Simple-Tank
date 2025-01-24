extends RayCast3D

@onready var parent: RigidBody3D = get_parent().get_parent()
@onready var wheel = get_child(0)
@export var skeletal: Skeleton3D

var previous_spring_length: float = 0.0

func _ready():
	add_exception(parent)

func _physics_process(delta):
	if is_colliding():
		var collision_point = get_collision_point()
		suspension(delta, collision_point)
		acceleration(collision_point)
		
		apply_z_force(collision_point)
		apply_x_force(delta, collision_point)
		
		set_wheel_position(to_local(get_collision_point()).y + (1 - parent.wheel_radius))
		print(get_collision_point().y)

func acceleration(collision_point):
	var accel_dir = -global_basis.z
	
	var torque = parent.accel_input * parent.engine_power
	var point = Vector3(collision_point.x, collision_point.y + parent.wheel_radius, collision_point.z)
	
	parent.apply_force(accel_dir * torque, point - parent.global_position)
	
	if parent.rotation_input:
		var index_wheel = get_parent().name
		if parent.rotation_input > 0:
			match index_wheel: 
				"wheelsL": parent.apply_force(accel_dir * parent.engine_power, point - parent.global_position)
				"wheelsR": parent.apply_force(accel_dir * -parent.engine_power, point - parent.global_position)
		if parent.rotation_input < 0:
			match index_wheel: 
				"wheelsL": parent.apply_force(accel_dir * -parent.engine_power, point - parent.global_position)
				"wheelsR": parent.apply_force(accel_dir * parent.engine_power, point - parent.global_position)
	
	if parent.debug:
		DebugDraw3D.draw_arrow(point, point + (accel_dir * torque) / 2, Color.BLUE, 0.1, true)

func set_wheel_position(new_pos_y: float):
	wheel.position.y = lerp(wheel.position.y, new_pos_y, 0.6)
	var index_wheel = get_index()
	var bone = skeletal.get_bone_pose_position(index_wheel + 1)
	bone.y = wheel.position.y - 1.2
	skeletal.set_bone_pose_position(index_wheel + 1, bone)

func apply_x_force(delta:float, collision_point) -> void:
	var dir: Vector3 = global_basis.x
	var state := PhysicsServer3D.body_get_direct_state(parent.get_rid())
	var tire_world_vel := state.get_velocity_at_local_position(global_position - parent.global_position)
	var lateral_vel: float = dir.dot(tire_world_vel)
	
	var grip = parent.mass * 20
	var desired_vel_change = -lateral_vel * grip
	var x_force = desired_vel_change * delta
	
	parent.apply_force(dir * x_force, collision_point - parent.global_position)
	
	if parent.debug:
		DebugDraw3D.draw_arrow(global_position, global_position + (dir * x_force), Color.RED, 0.1, true)

func apply_z_force(collision_point):
	var dir: Vector3 = global_basis.z
	var state := PhysicsServer3D.body_get_direct_state(parent.get_rid())
	var tire_world_vel := state.get_velocity_at_local_position(global_position - parent.global_position)
	#var tire_world_vel: Vector3 = get_point_velocity(global_position)
	var z_force = dir.dot(tire_world_vel) * parent.mass / 20
	
	parent.apply_force(-dir * z_force, collision_point - parent.global_position)
	
	var point = Vector3(collision_point.x, collision_point.y + parent.wheel_radius, collision_point.z)
	
	if parent.debug:
		DebugDraw3D.draw_arrow(point, point + (-dir * z_force) / 2, Color.BLUE_VIOLET, 0.1, true)

#func get_point_velocity(point: Vector3) -> Vector3:
#	return parent.linear_velocity + parent.angular_velocity.cross(point - parent.global_position)

func suspension(delta: float, collision_point):
	var susp_dir = global_basis.y
	var raycast_origin = global_position
	var raycast_dest = collision_point
	var distance = raycast_dest.distance_to(raycast_origin)
	
	var contact = collision_point - parent.global_position
	var spring_length = clamp(distance - parent.wheel_radius, 0, parent.suspension_rest_dist)
	var spring_force = parent.spring_strength * (parent.suspension_rest_dist - spring_length)
	var spring_velocity = (previous_spring_length - spring_length) / delta 
	
	var damper_forge = parent.spring_damper * spring_velocity
	
	var suspension_force = basis.y * (spring_force + damper_forge)
	previous_spring_length = spring_length
	
	var point = Vector3(collision_point.x, collision_point.y + parent.wheel_radius, collision_point.z)
	
	parent.apply_force(susp_dir + suspension_force, point - parent.global_position)

	if parent.debug:
		##DebugDraw3D.draw_sphere(point, 0.13)
		DebugDraw3D.draw_arrow(global_position, to_global(position + Vector3(-position.x, (suspension_force.y / 5), -position.z)), Color.GREEN, 0.1, true)
		DebugDraw3D.draw_line_hit_offset(global_position, to_global(position + Vector3(-position.x, -1, -position.z)), true, distance, 0.2, Color.RED, Color.RED)
