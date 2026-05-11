extends Node3D
class_name ResidentAvatar

const DEFAULT_HEIGHT := 1.60
const DEFAULT_DOOR_HEIGHT := 2.00


func build_from_profile(profile: Dictionary, door_height := DEFAULT_DOOR_HEIGHT) -> void:
	for child in get_children():
		child.free()

	var height: float = float(profile.get("height", DEFAULT_HEIGHT))
	var head_ratio: float = float(profile.get("head_ratio", 0.24))
	var torso_ratio: float = float(profile.get("torso_ratio", 0.50))
	var leg_bias: float = float(profile.get("leg_bias", 0.0))
	var shoulder_scale: float = float(profile.get("shoulder_scale", 1.0))
	var body_depth_scale: float = float(profile.get("body_depth_scale", 1.0))
	var cloth_color: Color = profile.get("cloth_color", Color(0.55, 0.45, 0.75))
	var skin_color: Color = profile.get("skin_color", Color(0.95, 0.78, 0.62))
	var hair_color: Color = profile.get("hair_color", Color(0.12, 0.09, 0.08))
	var outfit_type := String(profile.get("outfit_type", "casual"))

	# 頭を除いた首下を、胴体と脚でほぼ半分ずつ使う。leg_bias は少しだけ脚長/胴長へ寄せる調整値。
	var head_height: float = clampf(height * head_ratio, 0.32, 0.64)
	var body_height: float = maxf(height - head_height, 0.72)
	var torso_share: float = clampf(torso_ratio - leg_bias, 0.43, 0.57)
	var torso_height: float = body_height * torso_share
	var leg_height: float = body_height - torso_height

	var shoulder_width: float = height * 0.22 * shoulder_scale
	var hip_width: float = height * 0.18 * clampf(shoulder_scale * 0.86, 0.74, 1.14)
	var torso_radius: float = shoulder_width * 0.34 * body_depth_scale
	var leg_radius: float = height * 0.038 * clampf(body_depth_scale, 0.82, 1.18)
	var arm_radius: float = height * 0.032 * clampf(body_depth_scale, 0.82, 1.18)

	var leg_y: float = leg_height * 0.5
	var torso_y: float = leg_height + torso_height * 0.5
	var neck_y: float = leg_height + torso_height + height * 0.018
	var head_y: float = leg_height + torso_height + head_height * 0.5
	var head_radius: float = head_height * 0.5

	_add_part("Left Leg", _capsule_mesh(leg_height, leg_radius), Vector3(-hip_width * 0.25, leg_y, 0.0), cloth_color.darkened(0.20))
	_add_part("Right Leg", _capsule_mesh(leg_height, leg_radius), Vector3(hip_width * 0.25, leg_y, 0.0), cloth_color.darkened(0.20))

	_add_part("Torso", _capsule_mesh(torso_height, torso_radius), Vector3(0.0, torso_y, 0.0), cloth_color)
	_add_part("Neck", _capsule_mesh(height * 0.08, height * 0.035), Vector3(0.0, neck_y, 0.0), skin_color.darkened(0.03))
	_add_part("Head", _sphere_mesh(head_radius), Vector3(0.0, head_y, 0.0), skin_color)

	var arm_length: float = torso_height * 0.86
	var arm_y := torso_y - torso_height * 0.05
	_add_part("Left Arm", _capsule_mesh(arm_length, arm_radius), Vector3(-shoulder_width * 0.62, arm_y, 0.0), skin_color.darkened(0.03), Vector3(0.0, 0.0, 7.0))
	_add_part("Right Arm", _capsule_mesh(arm_length, arm_radius), Vector3(shoulder_width * 0.62, arm_y, 0.0), skin_color.darkened(0.03), Vector3(0.0, 0.0, -7.0))

	_add_outfit_detail(outfit_type, cloth_color, leg_height, torso_height, torso_radius, shoulder_width)
	_add_hair_parts(profile, head_y, head_radius, hair_color)
	_add_face_parts(profile, head_y, head_radius)

	if height > door_height:
		_add_part("Door Height Reference", _box_mesh(Vector3(shoulder_width * 1.16, 0.026, 0.026)), Vector3(0.0, door_height, 0.0), Color(0.96, 0.86, 0.34))


func head_position(profile: Dictionary) -> Vector3:
	var height: float = float(profile.get("height", DEFAULT_HEIGHT))
	var head_ratio: float = float(profile.get("head_ratio", 0.24))
	var torso_ratio: float = float(profile.get("torso_ratio", 0.50))
	var leg_bias: float = float(profile.get("leg_bias", 0.0))
	var head_height: float = clampf(height * head_ratio, 0.32, 0.64)
	var body_height: float = maxf(height - head_height, 0.72)
	var torso_share: float = clampf(torso_ratio - leg_bias, 0.43, 0.57)
	var torso_height: float = body_height * torso_share
	var leg_height: float = body_height - torso_height
	return Vector3(0.0, leg_height + torso_height + head_height * 0.5, 0.0)


func _add_outfit_detail(outfit_type: String, cloth_color: Color, leg_height: float, torso_height: float, torso_radius: float, shoulder_width: float) -> void:
	if outfit_type == "formal":
		_add_part("Collar", _box_mesh(Vector3(shoulder_width * 0.62, 0.035, torso_radius * 1.7)), Vector3(0.0, leg_height + torso_height * 0.86, torso_radius * 0.55), Color(0.96, 0.95, 0.90))
		_add_part("Tie", _box_mesh(Vector3(shoulder_width * 0.12, torso_height * 0.26, 0.018)), Vector3(0.0, leg_height + torso_height * 0.67, torso_radius * 0.92), Color(0.18, 0.22, 0.42))
	elif outfit_type == "work":
		_add_part("Apron", _box_mesh(Vector3(shoulder_width * 0.64, torso_height * 0.72, 0.022)), Vector3(0.0, leg_height + torso_height * 0.46, torso_radius * 0.94), Color(0.92, 0.88, 0.72))
	elif outfit_type == "skirt":
		var skirt := CylinderMesh.new()
		skirt.top_radius = shoulder_width * 0.34
		skirt.bottom_radius = shoulder_width * 0.45
		skirt.height = torso_height * 0.34
		skirt.radial_segments = 24
		_add_part("Skirt Hem", skirt, Vector3(0.0, leg_height + torso_height * 0.12, 0.0), cloth_color.darkened(0.12))
	elif outfit_type == "room":
		_add_part("Soft Hem", _box_mesh(Vector3(shoulder_width * 0.70, 0.045, torso_radius * 1.8)), Vector3(0.0, leg_height + torso_height * 0.20, 0.0), cloth_color.lightened(0.16))


func _add_hair_parts(profile: Dictionary, head_y: float, head_radius: float, hair_color: Color) -> void:
	var hair_style := int(profile.get("hair_style", 0))
	var hair_volume: float = float(profile.get("hair_volume", 1.0))
	var cap_radius := head_radius * 1.02 * hair_volume
	_add_part("Hair Cap", _sphere_mesh(cap_radius), Vector3(0.0, head_y + head_radius * 0.14, -head_radius * 0.08), hair_color)

	if hair_style == 1:
		_add_part("Long Back Hair", _capsule_mesh(head_radius * 1.65, head_radius * 0.34 * hair_volume), Vector3(0.0, head_y - head_radius * 0.70, -head_radius * 0.62), hair_color, Vector3(6.0, 0.0, 0.0))
	elif hair_style == 2:
		_add_part("Left Bun", _sphere_mesh(head_radius * 0.34 * hair_volume), Vector3(-head_radius * 0.82, head_y + head_radius * 0.12, -head_radius * 0.08), hair_color)
		_add_part("Right Bun", _sphere_mesh(head_radius * 0.34 * hair_volume), Vector3(head_radius * 0.82, head_y + head_radius * 0.12, -head_radius * 0.08), hair_color)
	elif hair_style == 3:
		_add_part("Ponytail", _capsule_mesh(head_radius * 1.15, head_radius * 0.22 * hair_volume), Vector3(0.0, head_y - head_radius * 0.18, -head_radius * 0.92), hair_color, Vector3(28.0, 0.0, 0.0))
	elif hair_style == 4:
		_add_part("Bob Hair Left", _capsule_mesh(head_radius * 0.85, head_radius * 0.18 * hair_volume), Vector3(-head_radius * 0.58, head_y - head_radius * 0.28, -head_radius * 0.18), hair_color, Vector3(5.0, 0.0, -6.0))
		_add_part("Bob Hair Right", _capsule_mesh(head_radius * 0.85, head_radius * 0.18 * hair_volume), Vector3(head_radius * 0.58, head_y - head_radius * 0.28, -head_radius * 0.18), hair_color, Vector3(5.0, 0.0, 6.0))


func _add_face_parts(profile: Dictionary, head_y: float, head_radius: float) -> void:
	var eye_spacing: float = float(profile.get("eye_spacing", 0.40)) * head_radius
	var eye_height: float = head_y + float(profile.get("eye_height", 0.04)) * head_radius
	var eye_size: float = float(profile.get("eye_size", 0.052)) * head_radius
	var mouth_width: float = float(profile.get("mouth_width", 0.24)) * head_radius
	var mouth_y: float = head_y + float(profile.get("mouth_y", -0.20)) * head_radius
	var face_z: float = head_radius * 0.86

	_add_part("Left Eye", _sphere_mesh(eye_size), Vector3(-eye_spacing, eye_height, face_z), Color(0.05, 0.04, 0.04))
	_add_part("Right Eye", _sphere_mesh(eye_size), Vector3(eye_spacing, eye_height, face_z), Color(0.05, 0.04, 0.04))
	_add_part("Mouth", _box_mesh(Vector3(mouth_width, eye_size * 0.55, eye_size * 0.45)), Vector3(0.0, mouth_y, face_z + eye_size * 0.18), Color(0.46, 0.13, 0.16))


func _add_part(part_name: String, mesh: Mesh, local_position: Vector3, color: Color, rotation_deg := Vector3.ZERO) -> void:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = local_position
	instance.rotation_degrees = rotation_deg
	instance.material_override = _material(color)
	add_child(instance)


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
