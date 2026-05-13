extends Node3D
class_name ResidentAvatar

const DEFAULT_HEIGHT := 1.60
const DEFAULT_DOOR_HEIGHT := 2.00

# ここから下の比率は「キャラ作成 UI の値」から生成される見た目の調整用です。
# UI 側で触る値を増やす前に、まずここを変えると全住人へまとめて効きます。
const ARM_ROOT_Y_RATIO := 0.70
const ARM_ROOT_X_RATIO := 0.46
const ARM_SPREAD_DEGREES := 14.0
const HEAD_SCALE_X := 0.96
const HEAD_SCALE_Y := 1.03
const HEAD_SCALE_Z := 0.92
const FACE_PART_SURFACE_LIFT := 0.012
const EYE_VISIBLE_SCALE := 1.18
const WALK_LEG_SWING_DEGREES := 8.0
const WALK_ARM_SWING_DEGREES := 7.0
const WALK_BLEND_SPEED := 7.5
const WALK_CYCLE_BASE_SPEED := 5.4
const WALK_CYCLE_SPEED_SCALE := 1.35

var avatar_height := DEFAULT_HEIGHT
var walk_cycle := 0.0
var walk_blend := 0.0
var walk_target_blend := 0.0
var walk_speed := 0.0
var part_nodes := {}
var part_rest_positions := {}
var part_rest_rotations := {}
var left_leg_pivot := Vector3.ZERO
var right_leg_pivot := Vector3.ZERO
var left_arm_pivot := Vector3.ZERO
var right_arm_pivot := Vector3.ZERO


func build_from_profile(profile: Dictionary, door_height := DEFAULT_DOOR_HEIGHT) -> void:
	for child in get_children():
		child.free()
	part_nodes.clear()
	part_rest_positions.clear()
	part_rest_rotations.clear()

	var height: float = float(profile.get("height", DEFAULT_HEIGHT))
	avatar_height = height
	var head_ratio: float = float(profile.get("head_ratio", 0.24))
	var torso_ratio: float = float(profile.get("torso_ratio", 0.50))
	var leg_bias: float = float(profile.get("leg_bias", 0.0))
	var shoulder_scale: float = float(profile.get("shoulder_scale", 1.0))
	var body_depth_scale: float = float(profile.get("body_depth_scale", 1.0))
	var cloth_color: Color = profile.get("cloth_color", Color(0.55, 0.45, 0.75))
	var skin_color: Color = profile.get("skin_color", Color(0.95, 0.78, 0.62))
	var hair_color: Color = profile.get("hair_color", Color(0.12, 0.09, 0.08))
	var shoe_color: Color = profile.get("shoe_color", Color(0.10, 0.10, 0.12))
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

	_add_lower_body(outfit_type, cloth_color, skin_color, shoe_color, height, leg_height, leg_y, hip_width, leg_radius)
	_add_torso_and_head(cloth_color, skin_color, height, leg_height, torso_height, torso_y, neck_y, head_y, head_radius, torso_radius, shoulder_width)
	_add_arms(cloth_color, skin_color, height, leg_height, torso_height, shoulder_width, torso_radius, arm_radius)

	_add_outfit_detail(outfit_type, cloth_color, leg_height, torso_height, torso_radius, shoulder_width)
	_add_hair_parts(profile, head_y, head_radius, hair_color)
	_add_face_parts(profile, head_y, head_radius)

	if height > door_height:
		_add_part("Door Height Reference", _box_mesh(Vector3(shoulder_width * 1.16, 0.026, 0.026)), Vector3(0.0, door_height, 0.0), Color(0.96, 0.86, 0.34))
	_apply_walk_pose()


func set_walking(active: bool, speed := 1.0) -> void:
	walk_target_blend = 1.0 if active else 0.0
	walk_speed = clampf(float(speed), 0.0, 2.0)


func _process(delta: float) -> void:
	walk_blend = move_toward(walk_blend, walk_target_blend, WALK_BLEND_SPEED * delta)
	if walk_blend > 0.001:
		var speed_ratio := clampf(walk_speed / 1.45, 0.45, 1.60)
		walk_cycle += delta * WALK_CYCLE_BASE_SPEED * lerpf(0.78, WALK_CYCLE_SPEED_SCALE, speed_ratio)
	_apply_walk_pose()


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


func _add_lower_body(outfit_type: String, cloth_color: Color, skin_color: Color, shoe_color: Color, height: float, leg_height: float, leg_y: float, hip_width: float, leg_radius: float) -> void:
	# 脚は「長さの編集」が画面に出やすい部分なので、細すぎる棒に見えないように靴とソックスを少し大きめに置きます。
	# skirt 系は肌色の脚、それ以外は服色のパンツにすると、服変更の差が小さな画面でも読みやすくなります。
	var leg_color := _leg_color(outfit_type, cloth_color, skin_color)
	var shoe_size := Vector3(leg_radius * 2.95, maxf(height * 0.038, 0.046), leg_radius * 4.40)
	var shoe_y := maxf(height * 0.019, 0.024)
	var foot_gap := hip_width * 0.26
	left_leg_pivot = Vector3(-foot_gap, leg_height, 0.0)
	right_leg_pivot = Vector3(foot_gap, leg_height, 0.0)
	_add_part("Left Leg", _capsule_mesh(leg_height * 0.92, leg_radius), Vector3(-foot_gap, leg_y + leg_height * 0.035, 0.0), leg_color)
	_add_part("Right Leg", _capsule_mesh(leg_height * 0.92, leg_radius), Vector3(foot_gap, leg_y + leg_height * 0.035, 0.0), leg_color)
	_add_part("Left Sock", _capsule_mesh(maxf(height * 0.07, 0.07), leg_radius * 1.04), Vector3(-foot_gap, shoe_y + height * 0.055, 0.0), Color(0.94, 0.92, 0.84))
	_add_part("Right Sock", _capsule_mesh(maxf(height * 0.07, 0.07), leg_radius * 1.04), Vector3(foot_gap, shoe_y + height * 0.055, 0.0), Color(0.94, 0.92, 0.84))
	_add_part("Left Shoe", _box_mesh(shoe_size), Vector3(-foot_gap, shoe_y, leg_radius * 0.96), shoe_color)
	_add_part("Right Shoe", _box_mesh(shoe_size), Vector3(foot_gap, shoe_y, leg_radius * 0.96), shoe_color)


func _add_torso_and_head(cloth_color: Color, skin_color: Color, height: float, leg_height: float, torso_height: float, torso_y: float, neck_y: float, head_y: float, head_radius: float, torso_radius: float, shoulder_width: float) -> void:
	# 胴は capsule 1本だけだと円柱感が強いので、服と腰の丸みだけを足します。
	# SD寄りの体では肩線を描かず、首元から腕が下へ広がるシルエットで肩を読ませます。
	_add_part("Torso", _capsule_mesh(torso_height * 0.96, torso_radius), Vector3(0.0, torso_y, 0.0), cloth_color)
	_add_part("Waist Softness", _capsule_mesh(shoulder_width * 0.60, torso_radius * 0.40), Vector3(0.0, leg_height + torso_height * 0.31, 0.0), cloth_color.darkened(0.04), Vector3(0.0, 0.0, 90.0))
	_add_part("Neck", _capsule_mesh(height * 0.065, height * 0.028), Vector3(0.0, neck_y - height * 0.006, 0.0), skin_color.darkened(0.03))
	_add_part("Head", _sphere_mesh(head_radius), Vector3(0.0, head_y, 0.0), skin_color, Vector3.ZERO, Vector3(HEAD_SCALE_X, HEAD_SCALE_Y, HEAD_SCALE_Z))


func _add_arms(cloth_color: Color, skin_color: Color, height: float, leg_height: float, torso_height: float, shoulder_width: float, torso_radius: float, arm_radius: float) -> void:
	# 腕はサンプルのSD感に寄せ、首元の近くから始まって下へ行くほど外へ広がる配置にします。
	# ARM_ROOT_Y_RATIO は袖の上端、ARM_ROOT_X_RATIO は袖の中心幅、ARM_SPREAD_DEGREES は末端の広がりです。
	var arm_root_y := leg_height + torso_height * ARM_ROOT_Y_RATIO
	var arm_x := shoulder_width * ARM_ROOT_X_RATIO
	var arm_length: float = torso_height * 0.82
	var sleeve_length: float = arm_length * 0.32
	var forearm_length: float = arm_length * 0.50
	var sleeve_y := arm_root_y - sleeve_length * 0.05
	var forearm_y := sleeve_y - sleeve_length * 0.44 - forearm_length * 0.43
	var hand_y := forearm_y - forearm_length * 0.54
	var sleeve_z := torso_radius * 0.03
	left_arm_pivot = Vector3(-arm_x * 0.86, arm_root_y + sleeve_length * 0.34, sleeve_z)
	right_arm_pivot = Vector3(arm_x * 0.86, arm_root_y + sleeve_length * 0.34, sleeve_z)
	_add_part("Left Sleeve", _capsule_mesh(sleeve_length, arm_radius * 1.12), Vector3(-arm_x, sleeve_y, sleeve_z), cloth_color.lightened(0.04), Vector3(0.0, 0.0, -ARM_SPREAD_DEGREES))
	_add_part("Right Sleeve", _capsule_mesh(sleeve_length, arm_radius * 1.12), Vector3(arm_x, sleeve_y, sleeve_z), cloth_color.lightened(0.04), Vector3(0.0, 0.0, ARM_SPREAD_DEGREES))
	_add_part("Left Forearm", _capsule_mesh(forearm_length, arm_radius * 0.92), Vector3(-arm_x * 1.16, forearm_y, sleeve_z), skin_color.darkened(0.025), Vector3(0.0, 0.0, -ARM_SPREAD_DEGREES * 0.42))
	_add_part("Right Forearm", _capsule_mesh(forearm_length, arm_radius * 0.92), Vector3(arm_x * 1.16, forearm_y, sleeve_z), skin_color.darkened(0.025), Vector3(0.0, 0.0, ARM_SPREAD_DEGREES * 0.42))
	_add_ellipsoid_part("Left Hand", arm_radius * 1.25, Vector3(-arm_x * 1.22, hand_y, sleeve_z), skin_color, Vector3(0.88, 1.10, 0.88))
	_add_ellipsoid_part("Right Hand", arm_radius * 1.25, Vector3(arm_x * 1.22, hand_y, sleeve_z), skin_color, Vector3(0.88, 1.10, 0.88))


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
	var fringe_color := hair_color.darkened(0.12)
	var cap_radius := head_radius * 1.05 * hair_volume
	var front_z := head_radius * 0.96
	_add_ellipsoid_part("Hair Crown", cap_radius, Vector3(0.0, head_y + head_radius * 0.30, 0.0), hair_color, Vector3(1.08, 0.72, 0.90))
	_add_ellipsoid_part("Forehead Hair Cap", head_radius * 0.24 * hair_volume, Vector3(0.0, head_y + head_radius * 0.27, front_z * 0.96), fringe_color, Vector3(1.90, 0.34, 0.15))
	_add_ellipsoid_part("Front Left Hair Sweep", head_radius * 0.17 * hair_volume, Vector3(-head_radius * 0.22, head_y + head_radius * 0.22, front_z * 0.96), fringe_color, Vector3(0.92, 0.62, 0.14), Vector3(0.0, 0.0, -12.0))
	_add_ellipsoid_part("Front Right Hair Sweep", head_radius * 0.17 * hair_volume, Vector3(head_radius * 0.22, head_y + head_radius * 0.22, front_z * 0.96), fringe_color, Vector3(0.92, 0.62, 0.14), Vector3(0.0, 0.0, 12.0))
	_add_ellipsoid_part("Back Hair Cover", head_radius * 0.66 * hair_volume, Vector3(0.0, head_y - head_radius * 0.03, -head_radius * 0.72), hair_color, Vector3(1.05, 1.22, 0.44))
	_add_part("Nape Hair", _capsule_mesh(head_radius * 0.82, head_radius * 0.19 * hair_volume), Vector3(0.0, head_y - head_radius * 0.42, -head_radius * 0.66), hair_color, Vector3(8.0, 0.0, 0.0))
	_add_part("Left Part Hairline", _capsule_mesh(head_radius * 0.30, head_radius * 0.028 * hair_volume), Vector3(-head_radius * 0.12, head_y + head_radius * 0.36, front_z * 0.97), fringe_color, Vector3(0.0, 0.0, 32.0), Vector3(1.0, 1.0, 0.42))
	_add_part("Right Part Hairline", _capsule_mesh(head_radius * 0.30, head_radius * 0.028 * hair_volume), Vector3(head_radius * 0.12, head_y + head_radius * 0.36, front_z * 0.97), fringe_color, Vector3(0.0, 0.0, -32.0), Vector3(1.0, 1.0, 0.42))
	_add_part("Center Part Seam", _capsule_mesh(head_radius * 0.22, head_radius * 0.018 * hair_volume), Vector3(0.0, head_y + head_radius * 0.48, front_z * 0.96), hair_color.darkened(0.22), Vector3.ZERO, Vector3(0.60, 1.0, 0.36))
	_add_ellipsoid_part("Left Part Bang Tip", head_radius * 0.09 * hair_volume, Vector3(-head_radius * 0.32, head_y + head_radius * 0.20, front_z * 0.97), fringe_color, Vector3(0.58, 0.68, 0.14), Vector3(0.0, 0.0, -14.0))
	_add_ellipsoid_part("Right Part Bang Tip", head_radius * 0.09 * hair_volume, Vector3(head_radius * 0.32, head_y + head_radius * 0.20, front_z * 0.97), fringe_color, Vector3(0.58, 0.68, 0.14), Vector3(0.0, 0.0, 14.0))
	_add_part("Left Side Hair Base", _capsule_mesh(head_radius * 0.68, head_radius * 0.13 * hair_volume), Vector3(-head_radius * 0.62, head_y - head_radius * 0.08, -head_radius * 0.02), hair_color, Vector3(2.0, 0.0, -7.0))
	_add_part("Right Side Hair Base", _capsule_mesh(head_radius * 0.68, head_radius * 0.13 * hair_volume), Vector3(head_radius * 0.62, head_y - head_radius * 0.08, -head_radius * 0.02), hair_color, Vector3(2.0, 0.0, 7.0))

	if hair_style == 1:
		_add_part("Long Back Hair", _capsule_mesh(head_radius * 1.65, head_radius * 0.34 * hair_volume), Vector3(0.0, head_y - head_radius * 0.70, -head_radius * 0.62), hair_color, Vector3(6.0, 0.0, 0.0))
		_add_part("Long Hair Left", _capsule_mesh(head_radius * 1.12, head_radius * 0.16 * hair_volume), Vector3(-head_radius * 0.62, head_y - head_radius * 0.34, head_radius * 0.10), hair_color, Vector3(0.0, 0.0, -8.0))
		_add_part("Long Hair Right", _capsule_mesh(head_radius * 1.12, head_radius * 0.16 * hair_volume), Vector3(head_radius * 0.62, head_y - head_radius * 0.34, head_radius * 0.10), hair_color, Vector3(0.0, 0.0, 8.0))
	elif hair_style == 2:
		_add_part("Left Bun", _sphere_mesh(head_radius * 0.34 * hair_volume), Vector3(-head_radius * 0.82, head_y + head_radius * 0.12, -head_radius * 0.08), hair_color)
		_add_part("Right Bun", _sphere_mesh(head_radius * 0.34 * hair_volume), Vector3(head_radius * 0.82, head_y + head_radius * 0.12, -head_radius * 0.08), hair_color)
		_add_part("Short Side Hair Left", _capsule_mesh(head_radius * 0.46, head_radius * 0.10 * hair_volume), Vector3(-head_radius * 0.58, head_y - head_radius * 0.08, head_radius * 0.12), hair_color, Vector3(0.0, 0.0, -5.0))
		_add_part("Short Side Hair Right", _capsule_mesh(head_radius * 0.46, head_radius * 0.10 * hair_volume), Vector3(head_radius * 0.58, head_y - head_radius * 0.08, head_radius * 0.12), hair_color, Vector3(0.0, 0.0, 5.0))
	elif hair_style == 3:
		_add_part("Ponytail", _capsule_mesh(head_radius * 1.15, head_radius * 0.22 * hair_volume), Vector3(0.0, head_y - head_radius * 0.18, -head_radius * 0.92), hair_color, Vector3(28.0, 0.0, 0.0))
		_add_part("Pony Side Left", _capsule_mesh(head_radius * 0.64, head_radius * 0.12 * hair_volume), Vector3(-head_radius * 0.58, head_y - head_radius * 0.15, head_radius * 0.10), hair_color, Vector3(0.0, 0.0, -7.0))
		_add_part("Pony Side Right", _capsule_mesh(head_radius * 0.64, head_radius * 0.12 * hair_volume), Vector3(head_radius * 0.58, head_y - head_radius * 0.15, head_radius * 0.10), hair_color, Vector3(0.0, 0.0, 7.0))
	elif hair_style == 4:
		_add_part("Bob Hair Left", _capsule_mesh(head_radius * 0.88, head_radius * 0.18 * hair_volume), Vector3(-head_radius * 0.58, head_y - head_radius * 0.26, head_radius * 0.08), hair_color, Vector3(3.0, 0.0, -6.0))
		_add_part("Bob Hair Right", _capsule_mesh(head_radius * 0.88, head_radius * 0.18 * hair_volume), Vector3(head_radius * 0.58, head_y - head_radius * 0.26, head_radius * 0.08), hair_color, Vector3(3.0, 0.0, 6.0))
		_add_part("Bob Back Hair", _capsule_mesh(head_radius * 0.78, head_radius * 0.25 * hair_volume), Vector3(0.0, head_y - head_radius * 0.24, -head_radius * 0.72), hair_color, Vector3(5.0, 0.0, 0.0))
	else:
		_add_part("Short Back Hair", _capsule_mesh(head_radius * 0.58, head_radius * 0.20 * hair_volume), Vector3(0.0, head_y - head_radius * 0.18, -head_radius * 0.72), hair_color, Vector3(5.0, 0.0, 0.0))
		_add_part("Short Side Hair Left", _capsule_mesh(head_radius * 0.40, head_radius * 0.10 * hair_volume), Vector3(-head_radius * 0.58, head_y - head_radius * 0.02, head_radius * 0.10), hair_color, Vector3(0.0, 0.0, -5.0))
		_add_part("Short Side Hair Right", _capsule_mesh(head_radius * 0.40, head_radius * 0.10 * hair_volume), Vector3(head_radius * 0.58, head_y - head_radius * 0.02, head_radius * 0.10), hair_color, Vector3(0.0, 0.0, 5.0))


func _add_face_parts(profile: Dictionary, head_y: float, head_radius: float) -> void:
	var skin_color: Color = profile.get("skin_color", Color(0.95, 0.78, 0.62))
	var eye_style := int(profile.get("eye_style", 0))
	var mouth_style := int(profile.get("mouth_style", 0))
	var eye_spacing: float = float(profile.get("eye_spacing", 0.40)) * head_radius
	var eye_y_offset: float = float(profile.get("eye_height", 0.04)) * head_radius
	var face_detail_size: float = float(profile.get("eye_size", 0.052)) * head_radius * 1.08
	var eye_size: float = face_detail_size * EYE_VISIBLE_SCALE
	var mouth_width: float = float(profile.get("mouth_width", 0.24)) * head_radius
	var mouth_y_offset: float = float(profile.get("mouth_y", -0.20)) * head_radius

	_add_ellipsoid_part("Left Ear", head_radius * 0.14, Vector3(-head_radius * 0.92, head_y + head_radius * 0.02, head_radius * 0.04), skin_color.darkened(0.02), Vector3(0.58, 1.0, 0.42))
	_add_ellipsoid_part("Right Ear", head_radius * 0.14, Vector3(head_radius * 0.92, head_y + head_radius * 0.02, head_radius * 0.04), skin_color.darkened(0.02), Vector3(0.58, 1.0, 0.42))

	# 顔はお面状の板を使わず、頭の楕円体の表面座標を計算してそこへ直接置きます。
	# eye_style は 0:点目、1:楕円目、2:眠そう目です。まずは小さく、曲面に貼り付いて見えることを優先します。
	var pupil := Color(0.0, 0.0, 0.0)
	match eye_style:
		1:
			_add_face_ellipsoid("Left Eye", head_radius, head_y, -eye_spacing, eye_y_offset, eye_size, pupil, Vector3(1.36, 0.68, 0.18))
			_add_face_ellipsoid("Right Eye", head_radius, head_y, eye_spacing, eye_y_offset, eye_size, pupil, Vector3(1.36, 0.68, 0.18))
		2:
			_add_face_line("Left Sleepy Eye", head_radius, head_y, -eye_spacing, eye_y_offset, eye_size * 1.65, eye_size * 0.12, pupil, -5.0)
			_add_face_line("Right Sleepy Eye", head_radius, head_y, eye_spacing, eye_y_offset, eye_size * 1.65, eye_size * 0.12, pupil, 5.0)
		_:
			_add_face_ellipsoid("Left Dot Eye", head_radius, head_y, -eye_spacing, eye_y_offset, eye_size, pupil, Vector3(0.86, 0.86, 0.20))
			_add_face_ellipsoid("Right Dot Eye", head_radius, head_y, eye_spacing, eye_y_offset, eye_size, pupil, Vector3(0.86, 0.86, 0.20))

	_add_face_ellipsoid("Nose", head_radius, head_y, 0.0, -head_radius * 0.07, face_detail_size * 0.20, skin_color.darkened(0.08), Vector3(0.70, 1.00, 0.16))
	_add_face_ellipsoid("Left Cheek", head_radius, head_y, -eye_spacing * 0.86, mouth_y_offset + face_detail_size * 0.58, face_detail_size * 0.30, Color(1.0, 0.55, 0.52, 0.20), Vector3(1.20, 0.55, 0.10))
	_add_face_ellipsoid("Right Cheek", head_radius, head_y, eye_spacing * 0.86, mouth_y_offset + face_detail_size * 0.58, face_detail_size * 0.30, Color(1.0, 0.55, 0.52, 0.20), Vector3(1.20, 0.55, 0.10))

	# mouth_style は 0:にこ口、1:まっすぐ、2:小さい口。必要ならここに開き口や困り口を足します。
	match mouth_style:
		1:
			_add_face_line("Flat Mouth", head_radius, head_y, 0.0, mouth_y_offset, maxf(mouth_width, face_detail_size * 1.55), face_detail_size * 0.11, Color(0.42, 0.12, 0.12), 0.0)
		2:
			_add_face_ellipsoid("Small Mouth", head_radius, head_y, 0.0, mouth_y_offset, face_detail_size * 0.34, Color(0.48, 0.12, 0.14), Vector3(1.15, 0.56, 0.14))
		_:
			_add_face_line("Smile Left", head_radius, head_y, -mouth_width * 0.22, mouth_y_offset, maxf(mouth_width * 0.58, face_detail_size), face_detail_size * 0.11, Color(0.50, 0.13, 0.13), -8.0)
			_add_face_line("Smile Right", head_radius, head_y, mouth_width * 0.22, mouth_y_offset, maxf(mouth_width * 0.58, face_detail_size), face_detail_size * 0.11, Color(0.50, 0.13, 0.13), 8.0)


func _leg_color(outfit_type: String, cloth_color: Color, skin_color: Color) -> Color:
	if outfit_type == "skirt":
		return skin_color.lightened(0.02)
	if outfit_type == "room":
		return cloth_color.lightened(0.18)
	return cloth_color.darkened(0.20)


func _add_face_ellipsoid(part_name: String, head_radius: float, head_y: float, x: float, y_offset: float, radius: float, color: Color, local_scale := Vector3.ONE, rotation_deg := Vector3.ZERO) -> MeshInstance3D:
	var position := _face_surface_point(head_radius, head_y, x, y_offset, radius * 0.18 + FACE_PART_SURFACE_LIFT)
	var instance := _add_ellipsoid_part(part_name, radius, position, color, local_scale, rotation_deg)
	instance.material_override = _feature_material(color)
	return instance


func _add_face_line(part_name: String, head_radius: float, head_y: float, x: float, y_offset: float, length: float, radius: float, color: Color, tilt_degrees := 0.0) -> MeshInstance3D:
	var position := _face_surface_point(head_radius, head_y, x, y_offset, radius + FACE_PART_SURFACE_LIFT)
	var instance := _add_part(part_name, _capsule_mesh(length, radius), position, color, Vector3(0.0, 0.0, 90.0 + tilt_degrees), Vector3.ONE)
	instance.material_override = _feature_material(color)
	return instance


func _face_surface_point(head_radius: float, head_y: float, x: float, y_offset: float, lift := 0.0) -> Vector3:
	# 頭は少しだけ楕円に潰しているので、同じ比率で表面 z を求めます。
	# x/y が端に寄りすぎると sqrt が崩れるため、顔パーツ用の安全範囲へ丸めます。
	var radius_x := head_radius * HEAD_SCALE_X
	var radius_y := head_radius * HEAD_SCALE_Y
	var radius_z := head_radius * HEAD_SCALE_Z
	var safe_x := clampf(x, -radius_x * 0.78, radius_x * 0.78)
	var safe_y := clampf(y_offset, -radius_y * 0.68, radius_y * 0.70)
	var nx := safe_x / radius_x
	var ny := safe_y / radius_y
	var front_z := sqrt(maxf(0.04, 1.0 - nx * nx - ny * ny)) * radius_z
	return Vector3(safe_x, head_y + safe_y, front_z + lift)


func _add_ellipsoid_part(part_name: String, radius: float, local_position: Vector3, color: Color, local_scale := Vector3.ONE, rotation_deg := Vector3.ZERO) -> MeshInstance3D:
	return _add_part(part_name, _sphere_mesh(radius), local_position, color, rotation_deg, local_scale)


func _add_part(part_name: String, mesh: Mesh, local_position: Vector3, color: Color, rotation_deg := Vector3.ZERO, local_scale := Vector3.ONE) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = local_position
	instance.rotation_degrees = rotation_deg
	instance.scale = local_scale
	instance.material_override = _material(color)
	add_child(instance)
	part_nodes[part_name] = instance
	part_rest_positions[part_name] = local_position
	part_rest_rotations[part_name] = rotation_deg
	return instance


func _apply_walk_pose() -> void:
	if part_nodes.is_empty():
		return

	var phase := sin(walk_cycle)
	var opposite := -phase
	var left_leg_rotation := Vector3(phase * WALK_LEG_SWING_DEGREES, 0.0, 0.0)
	var right_leg_rotation := Vector3(opposite * WALK_LEG_SWING_DEGREES, 0.0, 0.0)
	var left_arm_rotation := Vector3(opposite * WALK_ARM_SWING_DEGREES, 0.0, 0.0)
	var right_arm_rotation := Vector3(phase * WALK_ARM_SWING_DEGREES, 0.0, 0.0)

	_pose_part_around_pivot("Left Leg", left_leg_pivot, left_leg_rotation)
	_pose_part_around_pivot("Left Sock", left_leg_pivot, left_leg_rotation)
	_pose_part_around_pivot("Left Shoe", left_leg_pivot, left_leg_rotation)
	_pose_part_around_pivot("Right Leg", right_leg_pivot, right_leg_rotation)
	_pose_part_around_pivot("Right Sock", right_leg_pivot, right_leg_rotation)
	_pose_part_around_pivot("Right Shoe", right_leg_pivot, right_leg_rotation)

	_pose_part_around_pivot("Left Sleeve", left_arm_pivot, left_arm_rotation)
	_pose_part_around_pivot("Left Forearm", left_arm_pivot, left_arm_rotation)
	_pose_part_around_pivot("Left Hand", left_arm_pivot, left_arm_rotation)
	_pose_part_around_pivot("Right Sleeve", right_arm_pivot, right_arm_rotation)
	_pose_part_around_pivot("Right Forearm", right_arm_pivot, right_arm_rotation)
	_pose_part_around_pivot("Right Hand", right_arm_pivot, right_arm_rotation)


func _pose_part_around_pivot(part_name: String, pivot: Vector3, rotation_offset: Vector3) -> void:
	if not part_nodes.has(part_name):
		return
	var part := part_nodes[part_name] as Node3D
	if part == null:
		return
	var blended_rotation := rotation_offset * walk_blend
	var rest_position: Vector3 = part_rest_positions[part_name]
	var pivot_offset := rest_position - pivot
	pivot_offset = pivot_offset.rotated(Vector3.RIGHT, deg_to_rad(blended_rotation.x))
	pivot_offset = pivot_offset.rotated(Vector3.UP, deg_to_rad(blended_rotation.y))
	pivot_offset = pivot_offset.rotated(Vector3.FORWARD, deg_to_rad(blended_rotation.z))
	part.rotation_degrees = part_rest_rotations[part_name] + blended_rotation
	part.position = pivot + pivot_offset


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


func _feature_material(color: Color) -> StandardMaterial3D:
	var material := _material(color)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material
