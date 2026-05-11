extends Node3D

const ROOM_WIDTH := 5.0
const ROOM_DEPTH := 4.0
const ROOM_HEIGHT := 2.4

const AVERAGE_HEIGHT := 1.60
const TALL_HEIGHT := 2.20
const DOOR_HEIGHT := 2.00

var tall_girl: Node3D
var move_speed := 1.45

func _ready() -> void:
	_build_world()


func _process(delta: float) -> void:
	if tall_girl == null:
		return

	var input := Vector3.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input.z -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input.z += 1.0

	if input.length() > 0.0:
		input = input.normalized()
		tall_girl.position += input * move_speed * delta
		tall_girl.position.x = clamp(tall_girl.position.x, -ROOM_WIDTH * 0.42, ROOM_WIDTH * 0.42)
		tall_girl.position.z = clamp(tall_girl.position.z, -ROOM_DEPTH * 0.38, ROOM_DEPTH * 0.34)
		tall_girl.look_at(tall_girl.global_position + Vector3(input.x, 0.0, input.z), Vector3.UP)


func _build_world() -> void:
	_add_lights()
	_add_camera()
	_add_room()
	_add_furniture()
	_add_scale_guides()

	var average := _create_avatar("Average NPC", AVERAGE_HEIGHT, Color(0.36, 0.50, 0.78), Color(0.95, 0.78, 0.62))
	average.position = Vector3(-1.35, 0.0, 0.35)
	add_child(average)

	tall_girl = _create_avatar("Tall Girl", TALL_HEIGHT, Color(0.78, 0.30, 0.42), Color(0.96, 0.80, 0.64))
	tall_girl.position = Vector3(0.95, 0.0, 0.15)
	add_child(tall_girl)


func _add_lights() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Soft Window Light"
	sun.light_energy = 1.4
	sun.rotation_degrees = Vector3(-42.0, -30.0, 0.0)
	add_child(sun)

	var room_light := OmniLight3D.new()
	room_light.name = "Ceiling Light"
	room_light.position = Vector3(0.0, ROOM_HEIGHT - 0.1, -0.25)
	room_light.light_energy = 2.2
	room_light.omni_range = 5.5
	add_child(room_light)


func _add_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "Dollhouse Camera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.8
	camera.position = Vector3(4.0, 2.8, 5.2)
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(0.0, 1.08, 0.0), Vector3.UP)


func _add_room() -> void:
	_add_box("Floor", Vector3(ROOM_WIDTH, 0.05, ROOM_DEPTH), Vector3(0.0, -0.025, 0.0), Color(0.78, 0.71, 0.62))
	_add_box("Back Wall", Vector3(ROOM_WIDTH, ROOM_HEIGHT, 0.08), Vector3(0.0, ROOM_HEIGHT * 0.5, -ROOM_DEPTH * 0.5), Color(0.90, 0.88, 0.82))
	_add_box("Left Wall", Vector3(0.08, ROOM_HEIGHT, ROOM_DEPTH), Vector3(-ROOM_WIDTH * 0.5, ROOM_HEIGHT * 0.5, 0.0), Color(0.86, 0.88, 0.84))
	_add_box("Ceiling Plane", Vector3(ROOM_WIDTH, 0.04, ROOM_DEPTH), Vector3(0.0, ROOM_HEIGHT, 0.0), Color(0.93, 0.92, 0.88, 0.35), true)

	var door_x := 1.45
	var wall_z := -ROOM_DEPTH * 0.5 + 0.045
	_add_box("Door Panel 2.0m", Vector3(0.86, DOOR_HEIGHT, 0.04), Vector3(door_x, DOOR_HEIGHT * 0.5, wall_z + 0.01), Color(0.62, 0.50, 0.38))
	_add_box("Door Top Clearance", Vector3(1.02, 0.06, 0.08), Vector3(door_x, DOOR_HEIGHT, wall_z + 0.035), Color(0.30, 0.24, 0.20))
	_add_box("Door Handle", Vector3(0.06, 0.08, 0.08), Vector3(door_x - 0.32, 0.92, wall_z + 0.08), Color(0.95, 0.80, 0.36))


func _add_furniture() -> void:
	_add_box("Low Desk", Vector3(1.25, 0.08, 0.62), Vector3(-1.35, 0.72, -1.10), Color(0.58, 0.40, 0.26))
	_add_box("Desk Left Leg", Vector3(0.08, 0.70, 0.08), Vector3(-1.88, 0.35, -0.84), Color(0.42, 0.28, 0.18))
	_add_box("Desk Right Leg", Vector3(0.08, 0.70, 0.08), Vector3(-0.82, 0.35, -0.84), Color(0.42, 0.28, 0.18))

	_add_box("Chair Seat", Vector3(0.55, 0.08, 0.55), Vector3(-1.35, 0.43, -0.25), Color(0.35, 0.58, 0.62))
	_add_box("Chair Back", Vector3(0.55, 0.78, 0.08), Vector3(-1.35, 0.82, -0.50), Color(0.31, 0.50, 0.54))

	_add_box("Single Bed", Vector3(1.00, 0.28, 1.85), Vector3(1.55, 0.25, 0.98), Color(0.72, 0.66, 0.82))
	_add_box("Bed Pillow", Vector3(0.72, 0.16, 0.34), Vector3(1.55, 0.51, 0.24), Color(0.96, 0.94, 0.88))

	_add_box("Shelf Body", Vector3(0.88, 1.72, 0.30), Vector3(-2.03, 0.86, 0.86), Color(0.64, 0.52, 0.39))
	_add_box("Shelf Upper", Vector3(0.94, 0.05, 0.34), Vector3(-2.03, 1.55, 0.86), Color(0.45, 0.34, 0.25))
	_add_box("Shelf Middle", Vector3(0.94, 0.05, 0.34), Vector3(-2.03, 1.05, 0.86), Color(0.45, 0.34, 0.25))
	_add_box("Shelf Lower", Vector3(0.94, 0.05, 0.34), Vector3(-2.03, 0.55, 0.86), Color(0.45, 0.34, 0.25))

	_add_box("Ceiling Lamp Shade", Vector3(0.42, 0.12, 0.42), Vector3(0.0, ROOM_HEIGHT - 0.16, -0.05), Color(0.98, 0.91, 0.58))


func _add_scale_guides() -> void:
	for i in range(1, 5):
		var height := float(i) * 0.5
		_add_box("Height Mark %.1fm" % height, Vector3(0.42, 0.014, 0.018), Vector3(2.22, height, -ROOM_DEPTH * 0.5 + 0.095), Color(0.34, 0.39, 0.43))

	_add_box("Average Height Marker", Vector3(0.34, 0.018, 0.018), Vector3(2.03, AVERAGE_HEIGHT, -ROOM_DEPTH * 0.5 + 0.10), Color(0.30, 0.45, 0.78))
	_add_box("Tall Height Marker", Vector3(0.54, 0.024, 0.018), Vector3(2.08, TALL_HEIGHT, -ROOM_DEPTH * 0.5 + 0.11), Color(0.78, 0.30, 0.42))


func _create_avatar(label: String, height: float, cloth_color: Color, skin_color: Color) -> Node3D:
	var avatar := Node3D.new()
	avatar.name = label

	var head_height: float = clampf(height * 0.23, 0.38, 0.50)
	var torso_height: float = height * 0.34
	var leg_height: float = height - head_height - torso_height
	var shoulder_width: float = height * 0.23
	var hip_width: float = height * 0.18

	var leg_y: float = leg_height * 0.5
	var torso_y: float = leg_height + torso_height * 0.5
	var head_y: float = height - head_height * 0.5

	_add_avatar_part(avatar, "Left Leg", _capsule_mesh(leg_height, height * 0.040), Vector3(-hip_width * 0.24, leg_y, 0.0), cloth_color.darkened(0.18))
	_add_avatar_part(avatar, "Right Leg", _capsule_mesh(leg_height, height * 0.040), Vector3(hip_width * 0.24, leg_y, 0.0), cloth_color.darkened(0.18))
	_add_avatar_part(avatar, "Torso", _capsule_mesh(torso_height, shoulder_width * 0.34), Vector3(0.0, torso_y, 0.0), cloth_color)
	_add_avatar_part(avatar, "Head", _sphere_mesh(head_height * 0.5), Vector3(0.0, head_y, 0.0), skin_color)

	var arm_length: float = torso_height * 0.82
	_add_avatar_part(avatar, "Left Arm", _capsule_mesh(arm_length, height * 0.033), Vector3(-shoulder_width * 0.62, torso_y - 0.02, 0.0), skin_color.darkened(0.03), Vector3(0.0, 0.0, 7.0))
	_add_avatar_part(avatar, "Right Arm", _capsule_mesh(arm_length, height * 0.033), Vector3(shoulder_width * 0.62, torso_y - 0.02, 0.0), skin_color.darkened(0.03), Vector3(0.0, 0.0, -7.0))

	_add_avatar_part(avatar, "Hair Cap", _sphere_mesh(head_height * 0.51), Vector3(0.0, head_y + head_height * 0.08, -0.01), Color(0.15, 0.11, 0.09))

	if height > 2.0:
		_add_avatar_part(avatar, "Door Awareness Tilt", _box_mesh(Vector3(shoulder_width * 1.25, 0.035, 0.035)), Vector3(0.0, DOOR_HEIGHT, 0.0), Color(0.96, 0.88, 0.36))

	return avatar


func _add_avatar_part(parent: Node3D, part_name: String, mesh: Mesh, local_position: Vector3, color: Color, rotation_deg := Vector3.ZERO) -> void:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = local_position
	instance.rotation_degrees = rotation_deg
	instance.material_override = _material(color)
	parent.add_child(instance)


func _add_box(node_name: String, size: Vector3, position: Vector3, color: Color, transparent := false) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = _box_mesh(size)
	instance.position = position
	instance.material_override = _material(color, transparent)
	add_child(instance)
	return instance


func _box_mesh(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


func _sphere_mesh(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 24
	mesh.rings = 12
	return mesh


func _capsule_mesh(height: float, radius: float) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = max(height, radius * 2.2)
	mesh.radial_segments = 18
	mesh.rings = 8
	return mesh


func _material(color: Color, transparent := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	if transparent or color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = min(color.a, 0.42)
	return material
