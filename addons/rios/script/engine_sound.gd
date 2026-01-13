extends AudioStreamPlayer3D

@export var motorcycle : Motorcycle
@export var sample_rpm := 4000.0

func _physics_process(_delta):
	pitch_scale = motorcycle.engine_rpm / sample_rpm
	volume_db = linear_to_db((motorcycle.throttle * 0.5) + 0.5)
