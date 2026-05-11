extends Node3D

const ROOM_WIDTH := 5.0
const ROOM_DEPTH := 4.0
const ROOM_HEIGHT := 2.4

const DEFAULT_HEIGHT := 1.60
const DEFAULT_DOOR_HEIGHT := 2.00
const HEIGHT_MIN := 1.35
const HEIGHT_MAX := 2.60

var residents: Array[Dictionary] = []
var selected_index := 0
var selection_marker: MeshInstance3D
var resident_label: Label
var input_cooldown := 0.0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.seed = 44021
	_build_world()


func _process(delta: float) -> void:
	if residents.is_empty():
		return

	input_cooldown = maxf(input_cooldown - delta, 0.0)
	var selected_moved := _handle_player_input(delta)
	_update_residents(delta, selected_moved)
	_update_selection_marker()
	_update_hud()


func _build_world() -> void:
	_add_lights()
	_add_camera()
	_add_room()
	_add_furniture()
	_add_scale_guides()
	_add_residents()
	_add_selection_marker()
	_add_hud()


func _handle_player_input(delta: float) -> bool:
	if input_cooldown <= 0.0:
		if Input.is_key_pressed(KEY_Q):
			_select_resident(-1)
			input_cooldown = 0.18
		elif Input.is_key_pressed(KEY_E):
			_select_resident(1)
			input_cooldown = 0.18

	if Input.is_key_pressed(KEY_Z):
		_adjust_selected_profile("height", -0.46 * delta, HEIGHT_MIN, HEIGHT_MAX)
	if Input.is_key_pressed(KEY_X):
		_adjust_selected_profile("height", 0.46 * delta, HEIGHT_MIN, HEIGHT_MAX)
	if Input.is_key_pressed(KEY_C):
		_adjust_selected_profile("head_ratio", -0.05 * delta, 0.18, 0.30)
	if Input.is_key_pressed(KEY_V):
		_adjust_selected_profile("head_ratio", 0.05 * delta, 0.18, 0.30)
	if Input.is_key_pressed(KEY_B):
		_adjust_selected_profile("torso_ratio", -0.05 * delta, 0.26, 0.42)
	if Input.is_key_pressed(KEY_N):
		_adjust_selected_profile("torso_ratio", 0.05 * delta, 0.26, 0.42)
	if Input.is_key_pressed(KEY_R):
		_adjust_selected_profile("shoulder_scale", -0.25 * delta, 0.72, 1.35)
	if Input.is_key_pressed(KEY_T):
		_adjust_selected_profile("shoulder_scale", 0.25 * delta, 0.72, 1.35)

	var input := Vector3.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input.z -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input.z += 1.0

	if input.length() <= 0.0:
		return false

	input = input.normalized()
	_break_partner(selected_index)

	var resident: Dictionary = residents[selected_index]
	var node: Node3D = resident["node"] as Node3D
	node.position = _clamp_room_position(node.position + input * 1.45 * delta)
	_face_position(node, node.global_position + input)
	resident["state"] = "manual"
	resident["timer"] = 1.0
	resident["target"] = node.position
	residents[selected_index] = resident
	return true


func _select_resident(step: int) -> void:
	selected_index = (selected_index + step + residents.size()) % residents.size()


func _adjust_selected_profile(key: String, amount: float, min_value: float, max_value: float) -> void:
	var resident: Dictionary = residents[selected_index]
	var profile: Dictionary = resident["profile"]
	var old_value: float = float(profile.get(key, 0.0))
	var new_value: float = clampf(old_value + amount, min_value, max_value)
	if absf(new_value - old_value) < 0.0005:
		return

	profile[key] = new_value
	var node: Node3D = resident["node"] as Node3D
	_rebuild_avatar_mesh(node, profile)
	resident["profile"] = profile
	residents[selected_index] = resident


func _update_residents(delta: float, selected_moved: bool) -> void:
	for index in range(residents.size()):
		if selected_moved and index == selected_index:
			continue
		_update_resident(index, delta)


func _update_resident(index: int, delta: float) -> void:
	var resident: Dictionary = residents[index]
	var state := String(resident.get("state", "idle"))

	if state == "chat":
		var partner := int(resident.get("partner", -1))
		if partner >= 0 and partner < residents.size():
			var partner_node: Node3D = residents[partner]["node"] as Node3D
			var node: Node3D = resident["node"] as Node3D
			_face_position(node, partner_node.global_position)
		resident["timer"] = float(resident.get("timer", 0.0)) - delta
		residents[index] = resident
		if float(resident["timer"]) <= 0.0 and index < partner:
			_finish_chat_pair(index, partner)
		return

	if state == "meet":
		var node: Node3D = resident["node"] as Node3D
		var target: Vector3 = resident.get("target", node.position)
		var arrived := _move_resident_toward(node, target, float(resident.get("speed", 0.7)), delta)
		resident["timer"] = float(resident.get("timer", 0.0)) - delta
		residents[index] = resident

		var partner := int(resident.get("partner", -1))
		if partner >= 0 and partner < residents.size() and index < partner:
			var partner_resident: Dictionary = residents[partner]
			var partner_node: Node3D = partner_resident["node"] as Node3D
			var partner_target: Vector3 = partner_resident.get("target", partner_node.position)
			if arrived and partner_node.position.distance_to(partner_target) < 0.12:
				_begin_chat_pair(index, partner)
		elif float(resident["timer"]) <= 0.0:
			_clear_social_state(index)
		return

	if state == "wander":
		var node: Node3D = resident["node"] as Node3D
		var target: Vector3 = resident.get("target", node.position)
		if _move_resident_toward(node, target, float(resident.get("speed", 0.65)), delta):
			resident["state"] = "idle"
			resident["timer"] = rng.randf_range(0.5, 1.8)
		residents[index] = resident
		return

	if state == "manual":
		resident["timer"] = float(resident.get("timer", 0.0)) - delta
		if float(resident["timer"]) <= 0.0:
			resident["state"] = "idle"
			resident["timer"] = rng.randf_range(0.7, 1.8)
		residents[index] = resident
		return

	resident["timer"] = float(resident.get("timer", 0.0)) - delta
	residents[index] = resident
	if float(resident["timer"]) <= 0.0:
		_choose_next_action(index)


func _choose_next_action(index: int) -> void:
	if rng.randf() < 0.66:
		var partner := _find_available_partner(index)
		if partner != -1:
			_start_meeting(index, partner)
			return

	_start_wander(index)


func _find_available_partner(index: int) -> int:
	var candidates: Array[int] = []
	for other in range(residents.size()):
		if other == index:
			continue
		var resident: Dictionary = residents[other]
		var state := String(resident.get("state", "idle"))
		if state == "chat" or state == "meet":
			continue
		if int(resident.get("partner", -1)) != -1:
			continue
		candidates.append(other)

	if candidates.is_empty():
		return -1

	return candidates[rng.randi_range(0, candidates.size() - 1)]


func _start_meeting(a: int, b: int) -> void:
	_break_partner(a)
	_break_partner(b)

	var a_resident: Dictionary = residents[a]
	var b_resident: Dictionary = residents[b]
	var a_node: Node3D = a_resident["node"] as Node3D
	var b_node: Node3D = b_resident["node"] as Node3D
	var direction := b_node.position - a_node.position
	direction.y = 0.0
	if direction.length() < 0.1:
		direction = Vector3.RIGHT
	direction = direction.normalized()

	var a_profile: Dictionary = a_resident["profile"]
	var b_profile: Dictionary = b_resident["profile"]
	var spacing := 0.70 + absf(float(a_profile["height"]) - float(b_profile["height"])) * 0.12
	var midpoint := (a_node.position + b_node.position) * 0.5
	var a_target := _clamp_room_position(midpoint - direction * spacing * 0.5)
	var b_target := _clamp_room_position(midpoint + direction * spacing * 0.5)

	a_resident["state"] = "meet"
	a_resident["partner"] = b
	a_resident["target"] = a_target
	a_resident["timer"] = 7.0
	b_resident["state"] = "meet"
	b_resident["partner"] = a
	b_resident["target"] = b_target
	b_resident["timer"] = 7.0

	residents[a] = a_resident
	residents[b] = b_resident


func _start_wander(index: int) -> void:
	var resident: Dictionary = residents[index]
	resident["state"] = "wander"
	resident["partner"] = -1
	resident["target"] = Vector3(
		rng.randf_range(-ROOM_WIDTH * 0.38, ROOM_WIDTH * 0.36),
		0.0,
		rng.randf_range(-ROOM_DEPTH * 0.34, ROOM_DEPTH * 0.28)
	)
	residents[index] = resident


func _begin_chat_pair(a: int, b: int) -> void:
	var duration := rng.randf_range(3.0, 6.0)
	var a_resident: Dictionary = residents[a]
	var b_resident: Dictionary = residents[b]
	var a_node: Node3D = a_resident["node"] as Node3D
	var b_node: Node3D = b_resident["node"] as Node3D

	a_resident["state"] = "chat"
	a_resident["timer"] = duration
	b_resident["state"] = "chat"
	b_resident["timer"] = duration
	residents[a] = a_resident
	residents[b] = b_resident

	_face_position(a_node, b_node.global_position)
	_face_position(b_node, a_node.global_position)
	_set_chat_marker(a, true)
	_set_chat_marker(b, true)


func _finish_chat_pair(a: int, b: int) -> void:
	_clear_social_state(a)
	_clear_social_state(b)


func _break_partner(index: int) -> void:
	var resident: Dictionary = residents[index]
	var partner := int(resident.get("partner", -1))
	if partner >= 0 and partner < residents.size():
		_clear_social_state(partner)
	_clear_social_state(index)


func _clear_social_state(index: int) -> void:
	var resident: Dictionary = residents[index]
	resident["state"] = "idle"
	resident["partner"] = -1
	resident["timer"] = rng.randf_range(0.5, 1.7)
	residents[index] = resident
	_set_chat_marker(index, false)


func _move_resident_toward(node: Node3D, target: Vector3, speed: float, delta: float) -> bool:
	var offset := target - node.position
	offset.y = 0.0
	var distance := offset.length()
	if distance <= 0.06:
		return true

	var step := minf(speed * delta, distance)
	node.position = _clamp_room_position(node.position + offset.normalized() * step)
	_face_position(node, node.global_position + offset)
	return distance <= 0.12


func _face_position(node: Node3D, target: Vector3) -> void:
	var flat_target := Vector3(target.x, node.global_position.y, target.z)
	if node.global_position.distance_to(flat_target) > 0.05:
		node.look_at(flat_target, Vector3.UP)


func _clamp_room_position(position: Vector3) -> Vector3:
	return Vector3(
		clampf(position.x, -ROOM_WIDTH * 0.43, ROOM_WIDTH * 0.43),
		0.0,
		clampf(position.z, -ROOM_DEPTH * 0.39, ROOM_DEPTH * 0.34)
	)


func _add_residents() -> void:
	var profiles: Array[Dictionary] = [
		{
			"name": "Haru",
			"height": 2.24,
			"head_ratio": 0.22,
			"torso_ratio": 0.33,
			"shoulder_scale": 0.94,
			"cloth_color": Color(0.78, 0.30, 0.42),
			"skin_color": Color(0.96, 0.80, 0.64),
			"hair_color": Color(0.14, 0.10, 0.09),
			"eye_spacing": 0.42,
			"eye_height": 0.05,
			"eye_size": 0.055,
			"mouth_width": 0.26,
			"mouth_y": -0.22,
			"hair_style": 1
		},
		{
			"name": "Mio",
			"height": 1.58,
			"head_ratio": 0.25,
			"torso_ratio": 0.35,
			"shoulder_scale": 1.02,
			"cloth_color": Color(0.34, 0.50, 0.80),
			"skin_color": Color(0.94, 0.76, 0.62),
			"hair_color": Color(0.26, 0.16, 0.10),
			"eye_spacing": 0.38,
			"eye_height": 0.02,
			"eye_size": 0.052,
			"mouth_width": 0.22,
			"mouth_y": -0.20,
			"hair_style": 0
		},
		{
			"name": "Sena",
			"height": 1.42,
			"head_ratio": 0.28,
			"torso_ratio": 0.34,
			"shoulder_scale": 0.82,
			"cloth_color": Color(0.28, 0.64, 0.48),
			"skin_color": Color(0.91, 0.70, 0.55),
			"hair_color": Color(0.08, 0.08, 0.10),
			"eye_spacing": 0.46,
			"eye_height": 0.07,
			"eye_size": 0.062,
			"mouth_width": 0.20,
			"mouth_y": -0.18,
			"hair_style": 2
		},
		{
			"name": "Riku",
			"height": 1.82,
			"head_ratio": 0.23,
			"torso_ratio": 0.32,
			"shoulder_scale": 1.16,
			"cloth_color": Color(0.66, 0.48, 0.26),
			"skin_color": Color(0.96, 0.78, 0.60),
			"hair_color": Color(0.12, 0.11, 0.09),
			"eye_spacing": 0.34,
			"eye_height": 0.04,
			"eye_size": 0.050,
			"mouth_width": 0.28,
			"mouth_y": -0.25,
			"hair_style": 0
		}
	]
	var positions: Array[Vector3] = [
		Vector3(0.92, 0.0, 0.10),
		Vector3(-1.35, 0.0, 0.34),
		Vector3(-0.45, 0.0, 1.12),
		Vector3(1.62, 0.0, -0.72)
	]

	for index in range(profiles.size()):
		var profile: Dictionary = profiles[index]
		var node := _create_resident(profile)
		node.position = positions[index]
		add_child(node)

		residents.append({
			"node": node,
			"profile": profile,
			"state": "idle",
			"target": node.position,
			"timer": rng.randf_range(0.4, 1.8),
			"partner": -1,
			"speed": rng.randf_range(0.58, 0.86)
		})


func _create_resident(profile: Dictionary) -> Node3D:
	var avatar := Node3D.new()
	avatar.name = String(profile.get("name", "Resident"))
	_rebuild_avatar_mesh(avatar, profile)
	return avatar


func _rebuild_avatar_mesh(avatar: Node3D, profile: Dictionary) -> void:
	for child in avatar.get_children():
		child.free()

	var height: float = float(profile.get("height", DEFAULT_HEIGHT))
	var head_ratio: float = float(profile.get("head_ratio", 0.24))
	var torso_ratio: float = float(profile.get("torso_ratio", 0.34))
	var shoulder_scale: float = float(profile.get("shoulder_scale", 1.0))
	var cloth_color: Color = profile.get("cloth_color", Color(0.55, 0.45, 0.75))
	var skin_color: Color = profile.get("skin_color", Color(0.95, 0.78, 0.62))
	var hair_color: Color = profile.get("hair_color", Color(0.12, 0.09, 0.08))

	var head_height: float = clampf(height * head_ratio, 0.32, 0.58)
	var torso_height: float = clampf(height * torso_ratio, 0.36, height * 0.48)
	var leg_height: float = maxf(height - head_height - torso_height, 0.36)
	var shoulder_width: float = height * 0.22 * shoulder_scale
	var hip_width: float = height * 0.17 * clampf(shoulder_scale * 0.86, 0.72, 1.12)

	var leg_y: float = leg_height * 0.5
	var torso_y: float = leg_height + torso_height * 0.5
	var head_y: float = leg_height + torso_height + head_height * 0.5
	var head_radius: float = head_height * 0.5

	_add_avatar_part(avatar, "Left Leg", _capsule_mesh(leg_height, height * 0.040), Vector3(-hip_width * 0.24, leg_y, 0.0), cloth_color.darkened(0.18))
	_add_avatar_part(avatar, "Right Leg", _capsule_mesh(leg_height, height * 0.040), Vector3(hip_width * 0.24, leg_y, 0.0), cloth_color.darkened(0.18))
	_add_avatar_part(avatar, "Torso", _capsule_mesh(torso_height, shoulder_width * 0.34), Vector3(0.0, torso_y, 0.0), cloth_color)
	_add_avatar_part(avatar, "Head", _sphere_mesh(head_radius), Vector3(0.0, head_y, 0.0), skin_color)

	var arm_length: float = torso_height * 0.82
	_add_avatar_part(avatar, "Left Arm", _capsule_mesh(arm_length, height * 0.033), Vector3(-shoulder_width * 0.62, torso_y - 0.02, 0.0), skin_color.darkened(0.03), Vector3(0.0, 0.0, 7.0))
	_add_avatar_part(avatar, "Right Arm", _capsule_mesh(arm_length, height * 0.033), Vector3(shoulder_width * 0.62, torso_y - 0.02, 0.0), skin_color.darkened(0.03), Vector3(0.0, 0.0, -7.0))

	_add_hair_parts(avatar, profile, head_y, head_radius, hair_color)
	_add_face_parts(avatar, profile, head_y, head_radius)

	if height > DEFAULT_DOOR_HEIGHT:
		_add_avatar_part(avatar, "Door Height Reference", _box_mesh(Vector3(shoulder_width * 1.16, 0.026, 0.026)), Vector3(0.0, DEFAULT_DOOR_HEIGHT, 0.0), Color(0.96, 0.86, 0.34))


func _add_hair_parts(avatar: Node3D, profile: Dictionary, head_y: float, head_radius: float, hair_color: Color) -> void:
	var hair_style := int(profile.get("hair_style", 0))
	_add_avatar_part(avatar, "Hair Cap", _sphere_mesh(head_radius * 1.02), Vector3(0.0, head_y + head_radius * 0.14, -head_radius * 0.08), hair_color)

	if hair_style == 1:
		_add_avatar_part(avatar, "Back Hair", _capsule_mesh(head_radius * 1.35, head_radius * 0.34), Vector3(0.0, head_y - head_radius * 0.55, -head_radius * 0.64), hair_color, Vector3(6.0, 0.0, 0.0))
	elif hair_style == 2:
		_add_avatar_part(avatar, "Left Bun", _sphere_mesh(head_radius * 0.34), Vector3(-head_radius * 0.82, head_y + head_radius * 0.12, -head_radius * 0.08), hair_color)
		_add_avatar_part(avatar, "Right Bun", _sphere_mesh(head_radius * 0.34), Vector3(head_radius * 0.82, head_y + head_radius * 0.12, -head_radius * 0.08), hair_color)


func _add_face_parts(avatar: Node3D, profile: Dictionary, head_y: float, head_radius: float) -> void:
	var eye_spacing: float = float(profile.get("eye_spacing", 0.40)) * head_radius
	var eye_height: float = head_y + float(profile.get("eye_height", 0.04)) * head_radius
	var eye_size: float = float(profile.get("eye_size", 0.052)) * head_radius
	var mouth_width: float = float(profile.get("mouth_width", 0.24)) * head_radius
	var mouth_y: float = head_y + float(profile.get("mouth_y", -0.20)) * head_radius
	var face_z: float = head_radius * 0.86

	_add_avatar_part(avatar, "Left Eye", _sphere_mesh(eye_size), Vector3(-eye_spacing, eye_height, face_z), Color(0.05, 0.04, 0.04))
	_add_avatar_part(avatar, "Right Eye", _sphere_mesh(eye_size), Vector3(eye_spacing, eye_height, face_z), Color(0.05, 0.04, 0.04))
	_add_avatar_part(avatar, "Mouth", _box_mesh(Vector3(mouth_width, eye_size * 0.55, eye_size * 0.45)), Vector3(0.0, mouth_y, face_z + eye_size * 0.18), Color(0.46, 0.13, 0.16))


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
	_add_box("Door Panel 2.0m", Vector3(0.86, DEFAULT_DOOR_HEIGHT, 0.04), Vector3(door_x, DEFAULT_DOOR_HEIGHT * 0.5, wall_z + 0.01), Color(0.62, 0.50, 0.38))
	_add_box("Door Top Clearance", Vector3(1.02, 0.06, 0.08), Vector3(door_x, DEFAULT_DOOR_HEIGHT, wall_z + 0.035), Color(0.30, 0.24, 0.20))
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
	for i in range(1, 6):
		var height := float(i) * 0.5
		_add_box("Height Mark %.1fm" % height, Vector3(0.42, 0.014, 0.018), Vector3(2.22, height, -ROOM_DEPTH * 0.5 + 0.095), Color(0.34, 0.39, 0.43))

	_add_box("Default Height Marker", Vector3(0.34, 0.018, 0.018), Vector3(2.03, DEFAULT_HEIGHT, -ROOM_DEPTH * 0.5 + 0.10), Color(0.30, 0.45, 0.78))
	_add_box("Creator Height Cap Marker", Vector3(0.62, 0.024, 0.018), Vector3(2.05, HEIGHT_MAX, -ROOM_DEPTH * 0.5 + 0.11), Color(0.78, 0.30, 0.42))


func _add_selection_marker() -> void:
	selection_marker = _add_box("Selected Resident Marker", Vector3(1.0, 0.018, 1.0), Vector3.ZERO, Color(1.0, 0.86, 0.22, 0.56), true)
	_update_selection_marker()


func _update_selection_marker() -> void:
	if selection_marker == null or residents.is_empty():
		return
	var resident: Dictionary = residents[selected_index]
	var node: Node3D = resident["node"] as Node3D
	var profile: Dictionary = resident["profile"]
	var height: float = float(profile.get("height", DEFAULT_HEIGHT))
	selection_marker.position = Vector3(node.position.x, 0.018, node.position.z)
	selection_marker.scale = Vector3(maxf(height * 0.34, 0.55), 1.0, maxf(height * 0.34, 0.55))


func _add_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "Resident HUD"
	resident_label = Label.new()
	resident_label.position = Vector2(16.0, 14.0)
	resident_label.add_theme_color_override("font_color", Color(0.10, 0.12, 0.14))
	resident_label.add_theme_color_override("font_shadow_color", Color(1.0, 1.0, 1.0, 0.82))
	resident_label.add_theme_constant_override("shadow_offset_x", 1)
	resident_label.add_theme_constant_override("shadow_offset_y", 1)
	canvas.add_child(resident_label)
	add_child(canvas)
	_update_hud()


func _update_hud() -> void:
	if resident_label == null or residents.is_empty():
		return

	var resident: Dictionary = residents[selected_index]
	var profile: Dictionary = resident["profile"]
	resident_label.text = "%s\n%.2fm  head %.2f  torso %.2f  width %.2f\n%s" % [
		String(profile.get("name", "Resident")),
		float(profile.get("height", DEFAULT_HEIGHT)),
		float(profile.get("head_ratio", 0.24)),
		float(profile.get("torso_ratio", 0.34)),
		float(profile.get("shoulder_scale", 1.0)),
		String(resident.get("state", "idle"))
	]


func _set_chat_marker(index: int, enabled: bool) -> void:
	if index < 0 or index >= residents.size():
		return

	var resident: Dictionary = residents[index]
	var node: Node3D = resident["node"] as Node3D
	var existing := node.get_node_or_null("Chat Marker")
	if existing != null:
		existing.queue_free()

	if not enabled:
		return

	var profile: Dictionary = resident["profile"]
	var marker := MeshInstance3D.new()
	marker.name = "Chat Marker"
	marker.mesh = _sphere_mesh(0.075)
	marker.position = Vector3(0.0, float(profile.get("height", DEFAULT_HEIGHT)) + 0.22, 0.0)
	marker.material_override = _material(Color(1.0, 0.92, 0.34))
	node.add_child(marker)


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
	mesh.height = maxf(height, radius * 2.2)
	mesh.radial_segments = 18
	mesh.rings = 8
	return mesh


func _material(color: Color, transparent := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	if transparent or color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = minf(color.a, 0.56)
	return material
