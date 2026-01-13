class_name Motorcycle

extends RigidBody3D

@export_group("Suspension")
@export var suspension_rest_dist := 0.6
@export var spring_strength := 250.0
@export var spring_damp := 15.0
@export var wheel_radius := 0.3

@export_group("Engine")
@export var engine_power := 250.0 # Increased power to prevent speed loss on upshift
@export var brake_power := 150.0
@export var tire_grip := 3.0 # Slight increase for better cornering
@export var max_rpm := 9000.0
@export var idle_rpm := 1200.0
@export var torque_curve: Curve

@export_group("Gearbox")
@export var automatic_gearbox := true
@export var abs_enabled := true
# Higher ratios = More Torque. Speed is now controlled by 'gear_max_speeds'
@export var gear_ratios := [12.0, 8.0, 6.0, 4.5, 3.5] 
# Explicit speed limits in km/h for each gear
@export var gear_max_speeds := [40.0, 75.0, 110.0, 150.0, 200.0]
@export var gear_shift_delay := 0.35

@export_group("Handling")
@export var max_steer_angle := 0.6
@export var lean_force := 900.0
@export var min_lean_speed := 2.0
@export var max_lean_speed := 18.0
@export var turning_compensation := 0.5 # 0.0 = Real physics (slows down), 1.0 = Arcade (keeps speed)

@export_group("Stability")
@export var stability_force := 800.0
@export var stability_damping := 0.94

@export_group("Nodes")
@export var front_raycast: RayCast3D
@export var rear_raycast: RayCast3D
@export var front_tyre: Node3D
@export var rear_tyre: Node3D
@export var handling: Node3D

var current_gear := 1
var gear_shift_timer := 0.0
var steer_angle := 0.0
var throttle := 0.0
var reverse := 0.0
var clutch := 0.0
var front_brake := 0.0
var rear_brake := 0.0
var engine_rpm := 1200.0
var front_roll := 0.0
var rear_roll := 0.0

func _physics_process(delta):
	gear_shift_timer -= delta
	read_input(delta)
	
	process_wheel(front_raycast, front_tyre, true, delta)
	process_wheel(rear_raycast, rear_tyre, false, delta)
	
	apply_lean_and_stability(delta)

func read_input(delta):
	var speed := linear_velocity.length()
	
	# ---- Steering
	var lean_factor :float= clamp(
		(speed - min_lean_speed) / (max_lean_speed - min_lean_speed), 
		0.0, 1.0
	)
	
	var steer_input := Input.get_axis("Steer Right", "Steer Left")
	# Reduce steering sensitivity slightly less at high speeds for stability
	var steer_strength :float= lerp(1.0, 0.35, lean_factor)
	
	steer_angle = lerp(
		steer_angle,
		steer_input * max_steer_angle * steer_strength,
		6.0 * delta
	)
	
	# ---- Throttle / Reverse
	throttle = Input.get_action_strength("Throttle")
	reverse = Input.get_action_strength("Reverse")
	
	# ---- Clutch (0 = engaged, 1 = fully pulled)
	clutch = Input.get_action_strength("Clutch")
	
	# ---- Brakes
	front_brake = Input.get_action_strength("Front Brake")
	rear_brake = Input.get_action_strength("Rear Brake")
	
	if abs_enabled:
		var b :float= max(front_brake, rear_brake)
		front_brake = b
		rear_brake = b
		
	# ---- Gearbox
	if not automatic_gearbox:
		if Input.is_action_just_pressed("Shift Up"):
			current_gear = min(current_gear + 1, gear_ratios.size())
		if Input.is_action_just_pressed("Shift Down"):
			current_gear = max(current_gear - 1, 1)
	else:
		auto_shift()

func auto_shift():
	if gear_shift_timer > 0.0:
		return
	
	var speed_kmh = linear_velocity.length() * 3.6
	var max_speed_current = gear_max_speeds[current_gear - 1]
	
	# Shift UP if RPM is high OR we hit the speed limit of current gear
	# (0.95 factor ensures we shift slightly before hitting the hard limiter wall)
	if (engine_rpm > max_rpm * 0.9 or speed_kmh > max_speed_current * 0.95) and current_gear < gear_ratios.size():
		current_gear += 1
		gear_shift_timer = gear_shift_delay
		
	# Shift DOWN if RPM is low
	elif engine_rpm < max_rpm * 0.4 and current_gear > 1:
		current_gear -= 1
		gear_shift_timer = gear_shift_delay

func process_wheel(ray: RayCast3D, mesh: Node3D, is_front: bool, delta):
	var forward := global_transform.basis.z
	var right := global_transform.basis.x
	
	if is_front:
		forward = forward.rotated(Vector3.UP, steer_angle)
		right = right.rotated(Vector3.UP, steer_angle)
	
	if ray.is_colliding():
		var hit := ray.get_collision_point()
		var normal := ray.get_collision_normal()
		var dist := ray.global_position.distance_to(hit)
		
		# ---- Suspension
		var compression := 1.0 - (dist / suspension_rest_dist)
		var vel := get_velocity_at_point(hit)
		
		var spring := compression * spring_strength
		var damp := vel.dot(normal) * spring_damp
		apply_force((spring - damp) * normal, hit - global_position)
		
		# ---- Lateral grip (Friction)
		var lateral_vel := vel.dot(right)
		# Turning Compensation: Reduce lateral drag slightly to prevent massive speed loss
		var grip_factor = tire_grip
		if abs(lateral_vel) > 1.0 and throttle > 0.0:
			grip_factor *= (1.0 - (turning_compensation * 0.5))
			
		apply_force(-lateral_vel * grip_factor * right, hit - global_position)
		
		# ---- Drive (rear wheel only)
		if not is_front:
			var move_dir_dot = vel.dot(forward)
			update_engine_rpm(move_dir_dot, delta)
			
			var rpm_norm := engine_rpm / max_rpm
			var torque_mul := torque_curve.sample(clamp(rpm_norm, 0.0, 1.0)) if torque_curve else 1.0
			var ratio :float= gear_ratios[current_gear - 1]
			var clutch_engagement := 1.0 - clutch
			
			# Calculate base drive force
			var drive_force_mag := (
				(throttle - reverse) 
				* engine_power 
				* ratio 
				* torque_mul 
				* clutch_engagement
			)
			
			# ---- Speed Limiter Logic ----
			var speed_kmh = linear_velocity.length() * 3.6
			var gear_limit = gear_max_speeds[current_gear - 1]
			
			# If limiting, cut throttle power gracefully
			if speed_kmh > gear_limit and drive_force_mag > 0:
				var over_limit = speed_kmh - gear_limit
				# Fade out power over 5kmh buffer
				var cut_factor = clamp(1.0 - (over_limit / 5.0), 0.0, 1.0)
				drive_force_mag *= cut_factor
			
			apply_force(forward * drive_force_mag, hit - global_position)
			
		# ---- Braking (Fixed) ----
		var brake := front_brake if is_front else rear_brake
		if brake > 0.0:
			# Calculate direction of wheel movement relative to the bike's forward vector
			var wheel_vel_forward = vel.dot(forward)
			
			# FIX: Brake must oppose VELOCITY, not just point backwards.
			# If moving forward (+), brake pushes backward (-).
			# If moving backward (-), brake pushes forward (+).
			var brake_dir = -sign(wheel_vel_forward)
			
			# Apply brake only if moving (deadzone to prevent jitter at 0 speed)
			if abs(wheel_vel_forward) > 0.1:
				apply_force(forward * brake_dir * brake * brake_power, hit - global_position)
		
		# ---- Wheel visuals
		var roll :float= vel.dot(forward) * delta / wheel_radius
		if is_front: front_roll -= roll
		else: rear_roll -= roll
		
		mesh.position.y = ray.to_local(hit).y + wheel_radius
	else:
		mesh.position.y = -suspension_rest_dist

	# ---- Visuals
	if is_front:
		if handling: handling.rotation.y = steer_angle
		mesh.rotation = Vector3(-front_roll, 0, 0)
	else:
		mesh.rotation = Vector3(-rear_roll, 0, 0)

func update_engine_rpm(wheel_speed, delta):
	var ratio :float= gear_ratios[current_gear - 1]
	
	# RPM based on physical wheel speed
	var wheel_rpm :float= (
		abs(wheel_speed) 
		* ratio 
		* 60.0 
		/ (TAU * wheel_radius)
	)
	
	var rpm_rise := 6000.0
	var rpm_fall := 8000.0
	
	# Free rev when clutch pulled
	if clutch > 0.1:
		engine_rpm += throttle * rpm_rise * delta
		engine_rpm -= rpm_fall * (1.0 - throttle) * delta
	else:
		# Locked to wheel, but smoothed slightly
		var target :float= max(wheel_rpm, idle_rpm)
		engine_rpm = lerp(engine_rpm, target, 0.4)
		
	engine_rpm = clamp(engine_rpm, idle_rpm, max_rpm)

func apply_lean_and_stability(delta):
	var speed := linear_velocity.length()
	var lean_factor :float= clamp(
		(speed - min_lean_speed) / (max_lean_speed - min_lean_speed), 
		0.0, 1.0
	)
	
	var target_lean := -steer_angle * lean_factor
	var up := global_transform.basis.y
	var target_up := Vector3.UP.rotated(global_transform.basis.z, target_lean)
	
	apply_torque(up.cross(target_up) * lean_force)
	
	var stability_strength :float= lerp(
		stability_force,
		stability_force * 0.25,
		lean_factor
	)
	
	apply_torque(up.cross(Vector3.UP) * stability_strength)
	
	angular_velocity.x *= stability_damping
	angular_velocity.z *= stability_damping

func get_velocity_at_point(p: Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(p - global_position)
