extends Node3D


const SENSITIVITY = 0.03

@onready var camera: Camera3D = $Camera3D


func _input(event: InputEvent) -> void:
	if event.is_action("up"):
		rotation.x += SENSITIVITY * camera.position.z
	if event.is_action("down"):
		rotation.x -= SENSITIVITY * camera.position.z
	if event.is_action_pressed("zoom_in"):
		camera.position.z = camera.position.z * 0.96
	if event.is_action_pressed("zoom_out"):
		camera.position.z = camera.position.z * 1.1
	camera.position.z = clamp(camera.position.z, 1.8, 18)
