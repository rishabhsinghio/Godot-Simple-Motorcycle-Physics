extends Control

@export var bike: Motorcycle

@export var max_display_speed := 200.0    # km/h
@export var max_display_rpm := 10000.0

@onready var speed_label: Label = $"info/Label"
@onready var rpm_label: Label = $"info/Label2"
@onready var gear_label: Label = $"info/Label3"

@onready var throttle_bar: ProgressBar = $"info/Label4"
@onready var front_brake_bar: ProgressBar = $"info/Label5"
@onready var rear_brake_bar: ProgressBar = $"info/Label6"
@onready var torque_bar: ProgressBar = $"info/Label7"

@onready var abs_label: Label = $"info/Label8"
@onready var gearbox_label: Label = $"info/Label9"

# =========================================================

func _process(_delta):
	if bike == null:
		return

	update_speed()
	update_engine()
	update_controls()
	update_modes()


func update_speed():
	var speed_kmh := bike.linear_velocity.length() * 3.6
	speed_label.text = "Speed: %d km/h" % int(speed_kmh)

func update_engine():
	# RPM
	var rpm :float = bike.engine_rpm
	rpm_label.text = "RPM: %d" % int(rpm)

	# Gear
	gear_label.text = "Gear: %d" % bike.current_gear

	# Torque (from same torque curve logic as physics)
	var rpm_norm :float = clamp(rpm / bike.max_rpm, 0.0, 1.0)
	var torque :float = 0.0

	if bike.torque_curve != null:
		torque = bike.torque_curve.sample(rpm_norm)

	torque_bar.value = torque

# CONTROLS

func update_controls():
	throttle_bar.value = bike.throttle * 100
	front_brake_bar.value = bike.front_brake
	rear_brake_bar.value = bike.rear_brake


func update_modes():
	abs_label.text = "ABS: %s" % ("ON" if bike.abs_enabled else "OFF")
	gearbox_label.text = "Gearbox: %s" % (
		"AUTO" if bike.automatic_gearbox else "MANUAL"
	)
