extends Node3D

const ResidentAvatarScript := preload("res://scripts/ResidentAvatar.gd")

const SAVE_PATH := "user://residents.json"

const ROOM_WIDTH := 5.0
const ROOM_DEPTH := 4.0
const ROOM_HEIGHT := 2.4

const ISLAND_RADIUS_X := 4.25
const ISLAND_RADIUS_Z := 3.05

const DEFAULT_HEIGHT := 1.60
const DEFAULT_DOOR_HEIGHT := 2.00
const HEIGHT_MIN := 1.35
const HEIGHT_MAX := 3.20
const ISLAND_RESIDENT_SCALE := 0.46
const HOUSE_RESIDENT_SCALE := 1.0

const EDIT_SECTION_BODY := 0
const EDIT_SECTION_FACE := 1
const EDIT_SECTION_HAIR := 2
const EDIT_SECTION_CLOTHES := 3
const EDIT_SECTION_COUNT := 4

const BODY_AXIS_HEIGHT := 0
const BODY_AXIS_HEAD := 1
const BODY_AXIS_TORSO := 2
const BODY_AXIS_LEGS := 3
const BODY_AXIS_WIDTH := 4
const BODY_AXIS_DEPTH := 5

const FACE_AXIS_EYE_SPACING := 0
const FACE_AXIS_EYE_HEIGHT := 1
const FACE_AXIS_EYE_SIZE := 2
const FACE_AXIS_MOUTH_WIDTH := 3
const FACE_AXIS_MOUTH_HEIGHT := 4

const HAIR_AXIS_STYLE := 0
const HAIR_AXIS_COLOR := 1
const HAIR_AXIS_VOLUME := 2

const CLOTHES_AXIS_STYLE := 0
const CLOTHES_AXIS_COLOR := 1
const CLOTHES_AXIS_SKIN := 2

const HOUSE_ENTRY_POINT := Vector3(0.0, 0.0, -0.82)
const ROOM_EXIT_POINT := Vector3(1.45, 0.0, -1.43)

const GIFT_CATEGORY_KEYS := ["food", "clothes", "furniture", "tools"]
const GIFT_CATEGORY_LABELS := {
	"food": "食べ物",
	"clothes": "服",
	"furniture": "家具",
	"tools": "道具"
}

const FOOD_ITEMS := [
	{"id": "onigiri", "name": "おにぎり", "tag": "米", "color": Color(0.96, 0.96, 0.90)},
	{"id": "pancake", "name": "パンケーキ", "tag": "甘いもの", "color": Color(0.92, 0.70, 0.38)},
	{"id": "soup", "name": "野菜スープ", "tag": "温かいもの", "color": Color(0.88, 0.48, 0.28)}
]
const CLOTHES_ITEMS := [
	{"id": "casual", "name": "普段着", "tag": "落ち着いた服", "outfit": "casual", "color": Color(0.34, 0.50, 0.80)},
	{"id": "skirt", "name": "スカート服", "tag": "かわいい服", "outfit": "skirt", "color": Color(0.78, 0.30, 0.42)},
	{"id": "formal", "name": "きちんとした服", "tag": "きれいな服", "outfit": "formal", "color": Color(0.22, 0.28, 0.48)},
	{"id": "room", "name": "部屋着", "tag": "楽な服", "outfit": "room", "color": Color(0.55, 0.62, 0.46)}
]
const FURNITURE_ITEMS := [
	{"id": "stool", "name": "踏み台", "tag": "棚", "color": Color(0.62, 0.46, 0.28)},
	{"id": "long_bed", "name": "長めのベッド", "tag": "寝具", "color": Color(0.64, 0.62, 0.80)},
	{"id": "wide_chair", "name": "ゆったり椅子", "tag": "椅子", "color": Color(0.35, 0.58, 0.62)}
]
const TOOL_ITEMS := [
	{"id": "camera", "name": "カメラ", "tag": "観察", "color": Color(0.18, 0.18, 0.20)},
	{"id": "book", "name": "日記帳", "tag": "読書", "color": Color(0.58, 0.40, 0.26)},
	{"id": "measure", "name": "メジャー", "tag": "採寸", "color": Color(0.95, 0.80, 0.36)}
]

const HAIR_COLORS := [
	Color(0.12, 0.09, 0.08),
	Color(0.26, 0.16, 0.10),
	Color(0.62, 0.42, 0.22),
	Color(0.08, 0.08, 0.10),
	Color(0.58, 0.36, 0.48)
]
const CLOTH_COLORS := [
	Color(0.34, 0.50, 0.80),
	Color(0.78, 0.30, 0.42),
	Color(0.28, 0.64, 0.48),
	Color(0.66, 0.48, 0.26),
	Color(0.22, 0.28, 0.48),
	Color(0.55, 0.62, 0.46)
]
const SKIN_COLORS := [
	Color(0.96, 0.80, 0.64),
	Color(0.94, 0.76, 0.62),
	Color(0.91, 0.70, 0.55),
	Color(0.72, 0.50, 0.36),
	Color(0.98, 0.86, 0.72)
]
const HAIR_STYLE_LABELS := ["短め", "長め", "おだんご", "ポニーテール", "ボブ"]
const OUTFIT_LABELS := {
	"casual": "普段着",
	"skirt": "スカート服",
	"formal": "きちんとした服",
	"work": "エプロン",
	"room": "部屋着"
}
const OUTFIT_ORDER := ["casual", "skirt", "formal", "work", "room"]

const FURNITURE_ACTIONS := [
	{"id": "shelf", "name": "棚", "position": Vector3(-2.03, 0.0, 0.86), "radius": 0.82},
	{"id": "chair", "name": "椅子", "position": Vector3(-1.35, 0.0, -0.25), "radius": 0.78},
	{"id": "desk", "name": "机", "position": Vector3(-1.35, 0.0, -1.10), "radius": 0.78},
	{"id": "bed", "name": "ベッド", "position": Vector3(1.55, 0.0, 0.98), "radius": 0.95},
	{"id": "door", "name": "ドア", "position": ROOM_EXIT_POINT, "radius": 0.86}
]

var residents: Array[Dictionary] = []
var selected_index := 0
var current_place := "island"
var selection_marker: MeshInstance3D
var resident_label: Label
var input_cooldown := 0.0
var edit_mode := false
var edit_section := EDIT_SECTION_BODY
var edit_axis := 0
var gift_category_index := 0
var gift_item_index := 0
var event_log := "島の暮らしが始まった。"
var rng := RandomNumberGenerator.new()

var build_root: Node3D
var island_root: Node3D
var room_root: Node3D
var camera: Camera3D
var camera_yaw := 0.0
var camera_distance := 7.2
var camera_height := 3.2
var camera_size := 7.0


func _ready() -> void:
	rng.seed = 44021
	_build_world()


func _process(delta: float) -> void:
	if residents.is_empty():
		return

	input_cooldown = maxf(input_cooldown - delta, 0.0)
	_handle_camera_input(delta)
	_handle_player_input(delta)
	_update_residents(delta)
	_update_selection_marker()
	_update_hud()
	_update_camera()


func _build_world() -> void:
	_add_lights()
	_add_camera()

	island_root = Node3D.new()
	island_root.name = "Island"
	add_child(island_root)
	build_root = island_root
	_add_island()

	room_root = Node3D.new()
	room_root.name = "House Interior"
	add_child(room_root)
	build_root = room_root
	_add_room()
	_add_furniture()
	_add_scale_guides()
	room_root.visible = false

	build_root = null
	_add_residents()
	_add_selection_marker()
	_add_hud()
	_update_camera()


func _handle_camera_input(delta: float) -> void:
	if Input.is_key_pressed(KEY_J):
		camera_yaw -= 1.15 * delta
	if Input.is_key_pressed(KEY_L):
		camera_yaw += 1.15 * delta
	if Input.is_key_pressed(KEY_I):
		camera_height = clampf(camera_height + 1.8 * delta, 1.6, 6.4)
	if Input.is_key_pressed(KEY_K):
		camera_height = clampf(camera_height - 1.8 * delta, 1.6, 6.4)
	if Input.is_key_pressed(KEY_MINUS):
		camera_size = clampf(camera_size + 2.5 * delta, 4.4, 10.0)
	if Input.is_key_pressed(KEY_EQUAL):
		camera_size = clampf(camera_size - 2.5 * delta, 4.4, 10.0)
	if Input.is_key_pressed(KEY_HOME):
		camera_yaw = 0.0
		camera_height = 2.9 if current_place == "room" else 3.2
		camera_size = 6.0 if current_place == "room" else 7.0


func _handle_player_input(delta: float) -> bool:
	if input_cooldown <= 0.0:
		if Input.is_key_pressed(KEY_Q):
			_select_resident(-1)
			input_cooldown = 0.18
		elif Input.is_key_pressed(KEY_TAB):
			_select_resident(1)
			input_cooldown = 0.18
		elif Input.is_key_pressed(KEY_F):
			edit_mode = not edit_mode
			input_cooldown = 0.20
		elif edit_mode and Input.is_key_pressed(KEY_R):
			_cycle_edit_section()
			input_cooldown = 0.18
		elif edit_mode and _handle_edit_axis_shortcuts():
			input_cooldown = 0.16
		elif Input.is_key_pressed(KEY_T):
			_cycle_gift_category()
			input_cooldown = 0.18
		elif Input.is_key_pressed(KEY_U):
			_cycle_gift_item()
			input_cooldown = 0.18
		elif Input.is_key_pressed(KEY_Y):
			_give_selected_gift()
			input_cooldown = 0.28
		elif Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_SPACE):
			if _try_primary_action():
				input_cooldown = 0.35
				return true

	if edit_mode:
		_handle_edit_input(delta)

	var input := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input.y -= 1.0

	if input.length() <= 0.0:
		return false

	var move_direction := _screen_input_to_world(input.normalized())
	_break_partner(selected_index)

	var resident: Dictionary = residents[selected_index]
	var node: Node3D = resident["node"] as Node3D
	node.position = _clamp_current_position(node.position + move_direction * 1.45 * delta)
	_face_position(node, node.global_position + move_direction)
	resident["state"] = "manual"
	resident["timer"] = 1.0
	resident["target"] = node.position
	residents[selected_index] = resident
	return true


func _handle_edit_axis_shortcuts() -> bool:
	if Input.is_key_pressed(KEY_1):
		edit_axis = 0
		return true
	if Input.is_key_pressed(KEY_2):
		edit_axis = 1
		return true
	if Input.is_key_pressed(KEY_3):
		edit_axis = 2
		return true
	if Input.is_key_pressed(KEY_4):
		edit_axis = 3
		return true
	if Input.is_key_pressed(KEY_5):
		edit_axis = 4
		return true
	if Input.is_key_pressed(KEY_6):
		edit_axis = 5
		return true
	return false


func _cycle_edit_section() -> void:
	edit_section = (edit_section + 1) % EDIT_SECTION_COUNT
	edit_axis = 0


func _handle_edit_input(delta: float) -> void:
	var direction := 0.0
	if Input.is_key_pressed(KEY_Z):
		direction -= 1.0
	if Input.is_key_pressed(KEY_X):
		direction += 1.0
	if direction == 0.0:
		return

	var discrete := _is_current_edit_discrete()
	if discrete and input_cooldown > 0.0:
		return

	var changed := false
	match edit_section:
		EDIT_SECTION_BODY:
			changed = _adjust_body_value(direction, delta)
		EDIT_SECTION_FACE:
			changed = _adjust_face_value(direction, delta)
		EDIT_SECTION_HAIR:
			changed = _adjust_hair_value(direction, delta)
		EDIT_SECTION_CLOTHES:
			changed = _adjust_clothes_value(direction, delta)

	if changed and discrete:
		input_cooldown = 0.18


func _is_current_edit_discrete() -> bool:
	if edit_section == EDIT_SECTION_HAIR:
		return edit_axis == HAIR_AXIS_STYLE or edit_axis == HAIR_AXIS_COLOR
	if edit_section == EDIT_SECTION_CLOTHES:
		return edit_axis == CLOTHES_AXIS_STYLE or edit_axis == CLOTHES_AXIS_COLOR or edit_axis == CLOTHES_AXIS_SKIN
	return false


func _adjust_body_value(direction: float, delta: float) -> bool:
	match edit_axis:
		BODY_AXIS_HEIGHT:
			return _adjust_selected_profile("height", direction * 0.56 * delta, HEIGHT_MIN, HEIGHT_MAX)
		BODY_AXIS_HEAD:
			return _adjust_selected_profile("head_ratio", direction * 0.05 * delta, 0.18, 0.30)
		BODY_AXIS_TORSO:
			return _adjust_selected_profile("torso_ratio", direction * 0.05 * delta, 0.44, 0.56)
		BODY_AXIS_LEGS:
			return _adjust_selected_profile("leg_bias", direction * 0.05 * delta, -0.08, 0.08)
		BODY_AXIS_WIDTH:
			return _adjust_selected_profile("shoulder_scale", direction * 0.25 * delta, 0.72, 1.35)
		BODY_AXIS_DEPTH:
			return _adjust_selected_profile("body_depth_scale", direction * 0.22 * delta, 0.70, 1.35)
	return false


func _adjust_face_value(direction: float, delta: float) -> bool:
	match edit_axis:
		FACE_AXIS_EYE_SPACING:
			return _adjust_selected_profile("eye_spacing", direction * 0.10 * delta, 0.28, 0.58)
		FACE_AXIS_EYE_HEIGHT:
			return _adjust_selected_profile("eye_height", direction * 0.08 * delta, -0.06, 0.12)
		FACE_AXIS_EYE_SIZE:
			return _adjust_selected_profile("eye_size", direction * 0.025 * delta, 0.038, 0.080)
		FACE_AXIS_MOUTH_WIDTH:
			return _adjust_selected_profile("mouth_width", direction * 0.10 * delta, 0.16, 0.36)
		FACE_AXIS_MOUTH_HEIGHT:
			return _adjust_selected_profile("mouth_y", direction * 0.10 * delta, -0.34, -0.06)
	return false


func _adjust_hair_value(direction: float, delta: float) -> bool:
	var resident: Dictionary = residents[selected_index]
	var profile: Dictionary = resident["profile"]
	match edit_axis:
		HAIR_AXIS_STYLE:
			var old_style := int(profile.get("hair_style", 0))
			var next_style := _wrap_index(old_style + int(sign(direction)), HAIR_STYLE_LABELS.size())
			profile["hair_style"] = next_style
		HAIR_AXIS_COLOR:
			var old_color_index := int(profile.get("hair_color_index", 0))
			var next_color_index := _wrap_index(old_color_index + int(sign(direction)), HAIR_COLORS.size())
			profile["hair_color_index"] = next_color_index
			profile["hair_color"] = HAIR_COLORS[next_color_index]
		HAIR_AXIS_VOLUME:
			return _adjust_selected_profile("hair_volume", direction * 0.16 * delta, 0.82, 1.20)
		_:
			return false
	resident["profile"] = profile
	residents[selected_index] = resident
	_rebuild_resident_avatar(selected_index)
	_save_residents()
	return true


func _adjust_clothes_value(direction: float, delta: float) -> bool:
	var resident: Dictionary = residents[selected_index]
	var profile: Dictionary = resident["profile"]
	match edit_axis:
		CLOTHES_AXIS_STYLE:
			var old_outfit := String(profile.get("outfit_type", "casual"))
			var current := OUTFIT_ORDER.find(old_outfit)
			if current < 0:
				current = 0
			var next := _wrap_index(current + int(sign(direction)), OUTFIT_ORDER.size())
			profile["outfit_type"] = OUTFIT_ORDER[next]
		CLOTHES_AXIS_COLOR:
			var old_color_index := int(profile.get("cloth_color_index", 0))
			var next_color_index := _wrap_index(old_color_index + int(sign(direction)), CLOTH_COLORS.size())
			profile["cloth_color_index"] = next_color_index
			profile["cloth_color"] = CLOTH_COLORS[next_color_index]
		CLOTHES_AXIS_SKIN:
			var old_skin_index := int(profile.get("skin_color_index", 0))
			var next_skin_index := _wrap_index(old_skin_index + int(sign(direction)), SKIN_COLORS.size())
			profile["skin_color_index"] = next_skin_index
			profile["skin_color"] = SKIN_COLORS[next_skin_index]
		_:
			return false
	resident["profile"] = profile
	residents[selected_index] = resident
	_rebuild_resident_avatar(selected_index)
	_save_residents()
	return true


func _adjust_selected_profile(key: String, amount: float, min_value: float, max_value: float) -> bool:
	var resident: Dictionary = residents[selected_index]
	var profile: Dictionary = resident["profile"]
	var old_value: float = float(profile.get(key, 0.0))
	var new_value: float = clampf(old_value + amount, min_value, max_value)
	if absf(new_value - old_value) < 0.0005:
		return false

	profile[key] = new_value
	resident["profile"] = profile
	residents[selected_index] = resident
	_rebuild_resident_avatar(selected_index)
	_save_residents()
	return true


func _wrap_index(value: int, count: int) -> int:
	if count <= 0:
		return 0
	return (value % count + count) % count


func _screen_input_to_world(input: Vector2) -> Vector3:
	var right := Vector3(cos(camera_yaw), 0.0, -sin(camera_yaw))
	var forward := Vector3(-sin(camera_yaw), 0.0, -cos(camera_yaw))
	return (right * input.x + forward * input.y).normalized()


func _try_primary_action() -> bool:
	if _try_place_transition():
		return true
	if _try_room_context_action():
		return true
	if _try_solve_selected_problem():
		return true

	var profile: Dictionary = residents[selected_index]["profile"]
	_record_event("%s は少し様子を見た。" % String(profile.get("name", "Resident")))
	return true


func _try_place_transition() -> bool:
	var selected := residents[selected_index]
	var profile: Dictionary = selected["profile"]
	var node: Node3D = selected["node"] as Node3D
	if current_place == "island":
		if node.position.distance_to(HOUSE_ENTRY_POINT) <= 0.78:
			if float(profile.get("height", DEFAULT_HEIGHT)) > DEFAULT_DOOR_HEIGHT:
				_record_event("%s は玄関で少し頭を下げて家に入った。" % String(profile.get("name", "Resident")))
			_enter_house()
			return true
	else:
		if node.position.distance_to(ROOM_EXIT_POINT) <= 0.78:
			if float(profile.get("height", DEFAULT_HEIGHT)) > DEFAULT_DOOR_HEIGHT:
				_record_event("%s はドア枠を意識して、ゆっくり部屋を出た。" % String(profile.get("name", "Resident")))
			_exit_house()
			return true
	return false


func _try_room_context_action() -> bool:
	if current_place != "room":
		return false

	# 家具の近くで E を押したとき、身長に応じた短い生活反応を出す。
	var node: Node3D = residents[selected_index]["node"] as Node3D
	for action in FURNITURE_ACTIONS:
		var position: Vector3 = action["position"]
		var radius: float = float(action["radius"])
		if node.position.distance_to(position) <= radius:
			_play_furniture_event(String(action["id"]))
			return true
	return false


func _play_furniture_event(action_id: String) -> void:
	var resident: Dictionary = residents[selected_index]
	var profile: Dictionary = resident["profile"]
	var name := String(profile.get("name", "Resident"))
	var height: float = float(profile.get("height", DEFAULT_HEIGHT))
	var satisfaction_gain := 3.0
	var message := ""

	match action_id:
		"shelf":
			if height >= 1.90:
				message = "%s は棚の上段を自然にのぞいた。少し便利そうだ。" % name
				satisfaction_gain = 7.0
			else:
				message = "%s は棚の上段を見上げた。踏み台があると楽そうだ。" % name
		"chair":
			if height >= 1.95:
				message = "%s は椅子に座り、脚の置き場を少し探した。" % name
			else:
				message = "%s は椅子でひと息ついた。" % name
		"desk":
			if height >= 1.95:
				message = "%s は机の前で少し浅く腰をかけた。" % name
			else:
				message = "%s は机の上を片づけた。" % name
		"bed":
			if height >= 2.05:
				message = "%s はベッドに横になり、足先の余白を確かめた。" % name
				satisfaction_gain = 5.0
			else:
				message = "%s はベッドで少し休んだ。" % name
		"door":
			if height > DEFAULT_DOOR_HEIGHT:
				message = "%s はドアの高さを意識して、通り方を少し工夫した。" % name
				satisfaction_gain = 6.0
			else:
				message = "%s はドアの前で外の様子を見た。" % name
		_:
			message = "%s は部屋の中を見回した。" % name

	_apply_satisfaction(profile, satisfaction_gain)
	resident["profile"] = profile
	residents[selected_index] = resident
	_record_event(message)
	_save_residents()


func _enter_house() -> void:
	current_place = "room"
	island_root.visible = false
	room_root.visible = true
	camera_yaw = 0.0
	camera_height = 2.9
	camera_size = 6.0
	camera_distance = 6.0
	_place_single_resident_in_room(selected_index)


func _exit_house() -> void:
	current_place = "island"
	room_root.visible = false
	island_root.visible = true
	camera_yaw = 0.0
	camera_height = 3.2
	camera_size = 7.0
	camera_distance = 7.2
	_place_all_residents_on_island()


func _place_all_residents_on_island() -> void:
	_place_residents(_island_spawn_points(), ISLAND_RESIDENT_SCALE, true)


func _place_single_resident_in_room(active_index: int) -> void:
	var spawn_points := _room_spawn_points()
	for index in range(residents.size()):
		var visible := index == active_index
		var spawn := spawn_points[0] if visible else Vector3.ZERO
		_place_resident(index, spawn, HOUSE_RESIDENT_SCALE, visible)


func _place_residents(spawn_points: Array[Vector3], visual_scale: float, visible: bool) -> void:
	for index in range(residents.size()):
		_place_resident(index, spawn_points[index % spawn_points.size()], visual_scale, visible)


func _place_resident(index: int, position: Vector3, visual_scale: float, visible: bool) -> void:
	var resident: Dictionary = residents[index]
	var node: Node3D = resident["node"] as Node3D
	node.visible = visible
	node.position = position
	node.rotation = Vector3.ZERO
	node.scale = Vector3.ONE * visual_scale
	resident["state"] = "idle"
	resident["target"] = node.position
	resident["timer"] = rng.randf_range(0.4, 1.6)
	resident["partner"] = -1
	residents[index] = resident
	_refresh_resident_markers(index)


func _island_spawn_points() -> Array[Vector3]:
	return [
		Vector3(-0.70, 0.0, 0.75),
		Vector3(0.68, 0.0, 0.58),
		Vector3(-1.46, 0.0, 0.02),
		Vector3(1.42, 0.0, -0.08)
	]


func _room_spawn_points() -> Array[Vector3]:
	return [
		Vector3(1.20, 0.0, -1.18),
		Vector3(-1.35, 0.0, 0.34),
		Vector3(-0.45, 0.0, 1.12),
		Vector3(1.62, 0.0, -0.30)
	]


func _select_resident(step: int) -> void:
	var previous_index := selected_index
	for offset in range(1, residents.size() + 1):
		var candidate := (selected_index + step * offset + residents.size()) % residents.size()
		if _is_resident_active(candidate):
			_release_selected_resident(previous_index)
			selected_index = candidate
			_hold_selected_resident()
			return


func _update_residents(delta: float) -> void:
	for index in range(residents.size()):
		if not _is_resident_active(index):
			continue
		_update_problem_timer(index, delta)
		if index == selected_index:
			_hold_selected_resident()
			continue
		_update_resident(index, delta)


func _hold_selected_resident() -> void:
	if not _is_resident_active(selected_index):
		return

	var resident: Dictionary = residents[selected_index]
	var partner := int(resident.get("partner", -1))
	if partner >= 0 and partner < residents.size():
		_clear_social_state(partner)

	var node: Node3D = resident["node"] as Node3D
	resident["state"] = "selected"
	resident["partner"] = -1
	resident["target"] = node.position
	resident["timer"] = 9999.0
	residents[selected_index] = resident
	_set_chat_marker(selected_index, false)


func _release_selected_resident(index: int) -> void:
	if not _is_resident_active(index):
		return

	var resident: Dictionary = residents[index]
	if String(resident.get("state", "idle")) != "selected":
		return

	var node: Node3D = resident["node"] as Node3D
	resident["state"] = "idle"
	resident["target"] = node.position
	resident["timer"] = rng.randf_range(0.8, 2.0)
	residents[index] = resident


func _is_resident_active(index: int) -> bool:
	if index < 0 or index >= residents.size():
		return false
	var resident: Dictionary = residents[index]
	var node: Node3D = resident["node"] as Node3D
	return node.visible


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

	if state == "fight":
		resident["timer"] = float(resident.get("timer", 0.0)) - delta
		residents[index] = resident
		if float(resident["timer"]) <= 0.0:
			_clear_social_state(index)
		return

	if state == "visit":
		var visit_node: Node3D = resident["node"] as Node3D
		var visit_target: Vector3 = resident.get("target", visit_node.position)
		if _move_resident_toward(visit_node, visit_target, float(resident.get("speed", 0.7)), delta):
			resident["state"] = "idle"
			resident["timer"] = rng.randf_range(1.2, 2.4)
		residents[index] = resident
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
	if current_place == "island" and rng.randf() < 0.18 and _try_start_visit(index):
		return

	if rng.randf() < 0.66:
		var partner := _find_available_partner(index)
		if partner != -1:
			_start_meeting(index, partner)
			return

	_start_wander(index)


func _try_start_visit(index: int) -> bool:
	var partner := _find_friend_partner(index)
	if partner == -1:
		return false

	var resident: Dictionary = residents[index]
	var profile: Dictionary = resident["profile"]
	var partner_profile: Dictionary = residents[partner]["profile"]
	resident["state"] = "visit"
	resident["partner"] = partner
	resident["target"] = HOUSE_ENTRY_POINT + Vector3(rng.randf_range(-0.25, 0.25), 0.0, rng.randf_range(0.35, 0.65))
	resident["timer"] = 4.0
	residents[index] = resident
	_adjust_relationship(index, partner, 1, false)
	_record_event("%s は %s の家の前へ遊びに来た。" % [String(profile.get("name", "Resident")), String(partner_profile.get("name", "Resident"))])
	return true


func _find_friend_partner(index: int) -> int:
	var profile: Dictionary = residents[index]["profile"]
	var candidates: Array[int] = []
	for other in range(residents.size()):
		if other == index or other == selected_index:
			continue
		if not _is_resident_active(other):
			continue
		var other_state := String(residents[other].get("state", "idle"))
		if other_state == "chat" or other_state == "meet" or other_state == "fight":
			continue
		var other_name := String(residents[other]["profile"].get("name", "Resident"))
		if _relationship_score(profile, other_name) >= 30:
			candidates.append(other)
	if candidates.is_empty():
		return -1
	return candidates[rng.randi_range(0, candidates.size() - 1)]


func _find_available_partner(index: int) -> int:
	var candidates: Array[int] = []
	for other in range(residents.size()):
		if other == index:
			continue
		if other == selected_index:
			continue
		var resident: Dictionary = residents[other]
		if not _is_resident_active(other):
			continue
		var state := String(resident.get("state", "idle"))
		if state == "chat" or state == "meet" or state == "fight" or state == "visit":
			continue
		if int(resident.get("partner", -1)) != -1:
			continue
		candidates.append(other)

	if candidates.is_empty():
		return -1

	return candidates[rng.randi_range(0, candidates.size() - 1)]


func _start_meeting(a: int, b: int) -> void:
	if a == selected_index or b == selected_index:
		return

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
	var spacing := 0.70 + absf(float(a_profile["height"]) - float(b_profile["height"])) * 0.16
	var midpoint := (a_node.position + b_node.position) * 0.5
	var a_target := _clamp_current_position(midpoint - direction * spacing * 0.5)
	var b_target := _clamp_current_position(midpoint + direction * spacing * 0.5)

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
	resident["target"] = _random_wander_target()
	residents[index] = resident


func _random_wander_target() -> Vector3:
	if current_place == "room":
		return Vector3(
			rng.randf_range(-ROOM_WIDTH * 0.38, ROOM_WIDTH * 0.36),
			0.0,
			rng.randf_range(-ROOM_DEPTH * 0.34, ROOM_DEPTH * 0.28)
		)

	for attempt in range(12):
		var candidate := Vector3(
			rng.randf_range(-ISLAND_RADIUS_X * 0.82, ISLAND_RADIUS_X * 0.82),
			0.0,
			rng.randf_range(-ISLAND_RADIUS_Z * 0.74, ISLAND_RADIUS_Z * 0.66)
		)
		if _is_inside_island(candidate):
			return candidate
	return Vector3.ZERO


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

	var height_diff := absf(float(a_resident["profile"].get("height", DEFAULT_HEIGHT)) - float(b_resident["profile"].get("height", DEFAULT_HEIGHT)))
	if height_diff >= 0.45 and rng.randf() < 0.35:
		_record_event("%s と %s は目線の高さを合わせながら話している。" % [
			String(a_resident["profile"].get("name", "Resident")),
			String(b_resident["profile"].get("name", "Resident"))
		])


func _finish_chat_pair(a: int, b: int) -> void:
	# 会話は関係値を少し動かす。悪い方向に振れたときだけ、簡易的なけんか相談へつなぐ。
	var delta := rng.randi_range(4, 9)
	if rng.randf() < 0.13:
		delta = -rng.randi_range(12, 22)

	var score := _adjust_relationship(a, b, delta, true)
	if score <= -24 and delta < 0:
		_start_fight_pair(a, b)
	else:
		_clear_social_state(a)
		_clear_social_state(b)


func _start_fight_pair(a: int, b: int) -> void:
	var a_resident: Dictionary = residents[a]
	var b_resident: Dictionary = residents[b]
	var a_profile: Dictionary = a_resident["profile"]
	var b_profile: Dictionary = b_resident["profile"]
	a_resident["state"] = "fight"
	b_resident["state"] = "fight"
	a_resident["timer"] = rng.randf_range(3.5, 6.0)
	b_resident["timer"] = rng.randf_range(3.5, 6.0)
	a_resident["partner"] = b
	b_resident["partner"] = a
	a_profile["current_problem"] = {"type": "make_up", "category": "relationship", "target": String(b_profile.get("name", "Resident")), "text": "仲直りしたい"}
	b_profile["current_problem"] = {"type": "make_up", "category": "relationship", "target": String(a_profile.get("name", "Resident")), "text": "仲直りしたい"}
	a_resident["profile"] = a_profile
	b_resident["profile"] = b_profile
	residents[a] = a_resident
	residents[b] = b_resident
	_set_chat_marker(a, false)
	_set_chat_marker(b, false)
	_refresh_resident_markers(a)
	_refresh_resident_markers(b)
	_record_event("%s と %s は少し言い合いになった。" % [String(a_profile.get("name", "Resident")), String(b_profile.get("name", "Resident"))])
	_save_residents()


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
	var movement := offset.normalized()
	node.position = _clamp_current_position(node.position + movement * step)
	_face_position(node, node.global_position + movement)
	return distance <= 0.12


func _face_position(node: Node3D, target: Vector3) -> void:
	var flat_target := Vector3(target.x, node.global_position.y, target.z)
	if node.global_position.distance_to(flat_target) > 0.05:
		node.look_at(flat_target, Vector3.UP)
		node.rotate_y(PI)


func _clamp_current_position(position: Vector3) -> Vector3:
	if current_place == "room":
		return _clamp_room_position(position)
	return _clamp_island_position(position)


func _clamp_room_position(position: Vector3) -> Vector3:
	return Vector3(
		clampf(position.x, -ROOM_WIDTH * 0.43, ROOM_WIDTH * 0.43),
		0.0,
		clampf(position.z, -ROOM_DEPTH * 0.39, ROOM_DEPTH * 0.34)
	)


func _clamp_island_position(position: Vector3) -> Vector3:
	var x := position.x
	var z := position.z
	var normalized := Vector2(x / (ISLAND_RADIUS_X * 0.88), z / (ISLAND_RADIUS_Z * 0.78))
	if normalized.length() > 1.0:
		normalized = normalized.normalized()
		x = normalized.x * ISLAND_RADIUS_X * 0.88
		z = normalized.y * ISLAND_RADIUS_Z * 0.78
	return Vector3(x, 0.0, z)


func _is_inside_island(position: Vector3) -> bool:
	var normalized := Vector2(position.x / (ISLAND_RADIUS_X * 0.88), position.z / (ISLAND_RADIUS_Z * 0.78))
	return normalized.length() <= 1.0


func _add_residents() -> void:
	var profiles := _load_profiles()
	var positions := _island_spawn_points()

	for index in range(profiles.size()):
		var profile: Dictionary = profiles[index]
		var node := _create_resident(profile)
		node.position = positions[index % positions.size()]
		node.scale = Vector3.ONE * ISLAND_RESIDENT_SCALE
		add_child(node)

		residents.append({
			"node": node,
			"profile": profile,
			"state": "idle",
			"target": node.position,
			"timer": rng.randf_range(0.4, 1.8),
			"partner": -1,
			"speed": rng.randf_range(0.58, 0.86),
			"problem_timer": rng.randf_range(5.0, 13.0)
		})

	_ensure_all_relationships()
	_save_residents()


func _create_resident(profile: Dictionary) -> Node3D:
	var avatar: Node3D = ResidentAvatarScript.new()
	avatar.name = String(profile.get("name", "Resident"))
	if avatar.has_method("build_from_profile"):
		avatar.call("build_from_profile", profile, DEFAULT_DOOR_HEIGHT)
	return avatar


func _rebuild_resident_avatar(index: int) -> void:
	var resident: Dictionary = residents[index]
	var node: Node3D = resident["node"] as Node3D
	var profile: Dictionary = resident["profile"]
	if node.has_method("build_from_profile"):
		node.call("build_from_profile", profile, DEFAULT_DOOR_HEIGHT)
	_refresh_resident_markers(index)


func _load_profiles() -> Array[Dictionary]:
	# 住人プロフィールは user://residents.json に保存する。存在しない場合は初期住人を作る。
	var profiles: Array[Dictionary] = []
	if FileAccess.file_exists(SAVE_PATH):
		var text := FileAccess.get_file_as_string(SAVE_PATH)
		var parsed = JSON.parse_string(text)
		if parsed is Array:
			for raw_profile in parsed:
				if raw_profile is Dictionary:
					profiles.append(_profile_from_save(raw_profile))

	if profiles.is_empty():
		profiles = _default_profiles()

	for index in range(profiles.size()):
		profiles[index] = _ensure_profile_defaults(profiles[index], index)
	return profiles


func _default_profiles() -> Array[Dictionary]:
	return [
		{
			"name": "Haru",
			"height": 2.24,
			"head_ratio": 0.23,
			"torso_ratio": 0.50,
			"leg_bias": 0.03,
			"shoulder_scale": 0.94,
			"body_depth_scale": 0.88,
			"cloth_color_index": 1,
			"cloth_color": CLOTH_COLORS[1],
			"skin_color_index": 0,
			"skin_color": SKIN_COLORS[0],
			"hair_color_index": 0,
			"hair_color": HAIR_COLORS[0],
			"hair_style": 1,
			"hair_volume": 1.0,
			"eye_spacing": 0.42,
			"eye_height": 0.05,
			"eye_size": 0.055,
			"mouth_width": 0.26,
			"mouth_y": -0.22,
			"outfit_type": "skirt",
			"personality": "おだやか",
			"likes": {"food": "甘いもの", "clothes": "かわいい服", "furniture": "寝具", "tools": "採寸"},
			"satisfaction": 24.0,
			"relationships": {},
			"inventory": {}
		},
		{
			"name": "Mio",
			"height": 1.58,
			"head_ratio": 0.25,
			"torso_ratio": 0.51,
			"leg_bias": 0.00,
			"shoulder_scale": 1.02,
			"body_depth_scale": 1.00,
			"cloth_color_index": 0,
			"cloth_color": CLOTH_COLORS[0],
			"skin_color_index": 1,
			"skin_color": SKIN_COLORS[1],
			"hair_color_index": 1,
			"hair_color": HAIR_COLORS[1],
			"hair_style": 0,
			"hair_volume": 1.0,
			"eye_spacing": 0.38,
			"eye_height": 0.02,
			"eye_size": 0.052,
			"mouth_width": 0.22,
			"mouth_y": -0.20,
			"outfit_type": "casual",
			"personality": "まじめ",
			"likes": {"food": "米", "clothes": "落ち着いた服", "furniture": "椅子", "tools": "読書"},
			"satisfaction": 18.0,
			"relationships": {},
			"inventory": {}
		},
		{
			"name": "Sena",
			"height": 1.42,
			"head_ratio": 0.28,
			"torso_ratio": 0.52,
			"leg_bias": -0.02,
			"shoulder_scale": 0.82,
			"body_depth_scale": 0.82,
			"cloth_color_index": 2,
			"cloth_color": CLOTH_COLORS[2],
			"skin_color_index": 2,
			"skin_color": SKIN_COLORS[2],
			"hair_color_index": 3,
			"hair_color": HAIR_COLORS[3],
			"hair_style": 2,
			"hair_volume": 1.0,
			"eye_spacing": 0.46,
			"eye_height": 0.07,
			"eye_size": 0.062,
			"mouth_width": 0.20,
			"mouth_y": -0.18,
			"outfit_type": "room",
			"personality": "好奇心つよめ",
			"likes": {"food": "温かいもの", "clothes": "楽な服", "furniture": "棚", "tools": "観察"},
			"satisfaction": 16.0,
			"relationships": {},
			"inventory": {}
		},
		{
			"name": "Riku",
			"height": 1.82,
			"head_ratio": 0.24,
			"torso_ratio": 0.50,
			"leg_bias": 0.01,
			"shoulder_scale": 1.16,
			"body_depth_scale": 1.16,
			"cloth_color_index": 3,
			"cloth_color": CLOTH_COLORS[3],
			"skin_color_index": 0,
			"skin_color": SKIN_COLORS[0],
			"hair_color_index": 0,
			"hair_color": HAIR_COLORS[0],
			"hair_style": 0,
			"hair_volume": 0.94,
			"eye_spacing": 0.34,
			"eye_height": 0.04,
			"eye_size": 0.050,
			"mouth_width": 0.28,
			"mouth_y": -0.25,
			"outfit_type": "formal",
			"personality": "元気",
			"likes": {"food": "米", "clothes": "きれいな服", "furniture": "椅子", "tools": "読書"},
			"satisfaction": 20.0,
			"relationships": {},
			"inventory": {}
		}
	]


func _ensure_profile_defaults(profile: Dictionary, index: int) -> Dictionary:
	var defaults := _default_profiles()
	var fallback: Dictionary = defaults[index % defaults.size()]
	for key in fallback.keys():
		if not profile.has(key):
			profile[key] = fallback[key]

	profile["height"] = clampf(float(profile.get("height", DEFAULT_HEIGHT)), HEIGHT_MIN, HEIGHT_MAX)
	profile["head_ratio"] = clampf(float(profile.get("head_ratio", 0.24)), 0.18, 0.30)
	profile["torso_ratio"] = clampf(float(profile.get("torso_ratio", 0.50)), 0.44, 0.56)
	profile["leg_bias"] = clampf(float(profile.get("leg_bias", 0.0)), -0.08, 0.08)
	profile["hair_style"] = _wrap_index(int(profile.get("hair_style", 0)), HAIR_STYLE_LABELS.size())
	profile["hair_volume"] = clampf(float(profile.get("hair_volume", 1.0)), 0.82, 1.20)
	profile["cloth_color_index"] = _wrap_index(int(profile.get("cloth_color_index", 0)), CLOTH_COLORS.size())
	profile["skin_color_index"] = _wrap_index(int(profile.get("skin_color_index", 0)), SKIN_COLORS.size())
	profile["hair_color_index"] = _wrap_index(int(profile.get("hair_color_index", 0)), HAIR_COLORS.size())
	profile["cloth_color"] = _color_from_value(profile.get("cloth_color", CLOTH_COLORS[int(profile["cloth_color_index"])]), CLOTH_COLORS[int(profile["cloth_color_index"])])
	profile["skin_color"] = _color_from_value(profile.get("skin_color", SKIN_COLORS[int(profile["skin_color_index"])]), SKIN_COLORS[int(profile["skin_color_index"])])
	profile["hair_color"] = _color_from_value(profile.get("hair_color", HAIR_COLORS[int(profile["hair_color_index"])]), HAIR_COLORS[int(profile["hair_color_index"])])
	profile["likes"] = _ensure_dict(profile.get("likes", fallback.get("likes", {})))
	profile["relationships"] = _ensure_dict(profile.get("relationships", {}))
	profile["inventory"] = _ensure_inventory(profile.get("inventory", {}))
	if not profile.has("current_problem"):
		profile["current_problem"] = {}
	return profile


func _profile_from_save(raw_profile: Dictionary) -> Dictionary:
	var profile := raw_profile.duplicate(true)
	profile["cloth_color"] = _color_from_value(profile.get("cloth_color", CLOTH_COLORS[0]), CLOTH_COLORS[0])
	profile["skin_color"] = _color_from_value(profile.get("skin_color", SKIN_COLORS[0]), SKIN_COLORS[0])
	profile["hair_color"] = _color_from_value(profile.get("hair_color", HAIR_COLORS[0]), HAIR_COLORS[0])
	return profile


func _profile_to_save(profile: Dictionary) -> Dictionary:
	var saved := profile.duplicate(true)
	saved["cloth_color"] = _color_to_html(profile.get("cloth_color", CLOTH_COLORS[0]))
	saved["skin_color"] = _color_to_html(profile.get("skin_color", SKIN_COLORS[0]))
	saved["hair_color"] = _color_to_html(profile.get("hair_color", HAIR_COLORS[0]))
	return saved


func _save_residents() -> void:
	# Node 参照は保存せず、住人のプロフィール、外見、好み、関係値、所持品だけを JSON 化する。
	var save_data := []
	for resident in residents:
		var profile: Dictionary = resident["profile"]
		save_data.append(_profile_to_save(profile))

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(save_data, "\t"))


func _color_to_html(value) -> String:
	if typeof(value) == TYPE_COLOR:
		var color: Color = value
		return "#" + color.to_html(false)
	return String(value)


func _color_from_value(value, fallback: Color) -> Color:
	if typeof(value) == TYPE_COLOR:
		return value
	if typeof(value) == TYPE_STRING:
		var text := String(value)
		if text.is_empty():
			return fallback
		return Color.html(text)
	return fallback


func _ensure_dict(value) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


func _ensure_inventory(value) -> Dictionary:
	var inventory := _ensure_dict(value)
	for category in GIFT_CATEGORY_KEYS:
		if not inventory.has(category) or not (inventory[category] is Array):
			inventory[category] = []
	return inventory


func _ensure_all_relationships() -> void:
	for index in range(residents.size()):
		var profile: Dictionary = residents[index]["profile"]
		var relationships: Dictionary = profile.get("relationships", {})
		for other in range(residents.size()):
			if other == index:
				continue
			var other_name := String(residents[other]["profile"].get("name", "Resident"))
			if not relationships.has(other_name):
				relationships[other_name] = rng.randi_range(0, 12)
		profile["relationships"] = relationships
		residents[index]["profile"] = profile


func _relationship_score(profile: Dictionary, other_name: String) -> int:
	var relationships: Dictionary = profile.get("relationships", {})
	return int(relationships.get(other_name, 0))


func _adjust_relationship(a: int, b: int, amount: int, announce := false) -> int:
	var a_profile: Dictionary = residents[a]["profile"]
	var b_profile: Dictionary = residents[b]["profile"]
	var a_name := String(a_profile.get("name", "Resident"))
	var b_name := String(b_profile.get("name", "Resident"))
	var a_relationships: Dictionary = a_profile.get("relationships", {})
	var b_relationships: Dictionary = b_profile.get("relationships", {})
	var old_score := int(a_relationships.get(b_name, 0))
	var new_score := clampi(old_score + amount, -100, 100)
	a_relationships[b_name] = new_score
	b_relationships[a_name] = clampi(int(b_relationships.get(a_name, 0)) + amount, -100, 100)
	a_profile["relationships"] = a_relationships
	b_profile["relationships"] = b_relationships
	residents[a]["profile"] = a_profile
	residents[b]["profile"] = b_profile

	if announce:
		if old_score < 30 and new_score >= 30:
			_record_event("%s と %s は友達らしくなってきた。" % [a_name, b_name])
		elif amount > 0:
			_record_event("%s と %s は少し仲良くなった。" % [a_name, b_name])
		elif amount < 0:
			_record_event("%s と %s は少し気まずくなった。" % [a_name, b_name])
	_save_residents()
	return new_score


func _update_problem_timer(index: int, delta: float) -> void:
	# 悩みは住人ごとに自然発生する。未解決の間は頭上の印を残す。
	var resident: Dictionary = residents[index]
	var profile: Dictionary = resident["profile"]
	var current_problem: Dictionary = profile.get("current_problem", {})
	if not current_problem.is_empty():
		_set_problem_marker(index, true)
		return

	resident["problem_timer"] = float(resident.get("problem_timer", 8.0)) - delta
	if float(resident["problem_timer"]) <= 0.0:
		_assign_problem(index)
		resident["problem_timer"] = rng.randf_range(13.0, 24.0)
	residents[index] = resident


func _assign_problem(index: int) -> void:
	var resident: Dictionary = residents[index]
	var profile: Dictionary = resident["profile"]
	var height: float = float(profile.get("height", DEFAULT_HEIGHT))
	var options: Array[Dictionary] = [
		{"type": "hungry", "category": "food", "text": "なにか食べたい"},
		{"type": "want_clothes", "category": "clothes", "text": "服を変えてみたい"},
		{"type": "want_furniture", "category": "furniture", "text": "部屋に合う物がほしい"},
		{"type": "want_tool", "category": "tools", "text": "小さな道具がほしい"},
		{"type": "make_friend", "category": "relationship", "text": "誰かと仲良くなりたい"}
	]

	if height > DEFAULT_DOOR_HEIGHT:
		options.append({"type": "high_door", "category": "height", "text": "ドアの通り方を少し考えたい"})
	if height >= 1.90:
		options.append({"type": "tall_help", "category": "height", "text": "高い棚を手伝えそう"})
	if height <= 1.52:
		options.append({"type": "shelf_help", "category": "height", "text": "棚の上段を取ってほしい"})

	var problem: Dictionary = options[rng.randi_range(0, options.size() - 1)]
	profile["current_problem"] = problem
	resident["profile"] = profile
	residents[index] = resident
	_set_problem_marker(index, true)
	_record_event("%s は「%s」と思っている。" % [String(profile.get("name", "Resident")), String(problem.get("text", "相談がある"))])
	_save_residents()


func _try_solve_selected_problem() -> bool:
	var resident: Dictionary = residents[selected_index]
	var profile: Dictionary = resident["profile"]
	var problem: Dictionary = profile.get("current_problem", {})
	if problem.is_empty():
		return false

	var name := String(profile.get("name", "Resident"))
	var problem_type := String(problem.get("type", ""))
	var message := ""
	var satisfaction_gain := 8.0

	match problem_type:
		"hungry":
			var food := _best_item_for_profile("food", profile)
			_add_inventory_item(profile, "food", String(food.get("name", "食べ物")))
			message = "%s に %s を渡した。満足そうだ。" % [name, String(food.get("name", "食べ物"))]
		"want_clothes":
			var clothes := _best_item_for_profile("clothes", profile)
			_apply_clothes_item(profile, clothes)
			_add_inventory_item(profile, "clothes", String(clothes.get("name", "服")))
			message = "%s は %s に着替えた。" % [name, String(clothes.get("name", "服"))]
		"want_furniture":
			var furniture := _best_item_for_profile("furniture", profile)
			_add_inventory_item(profile, "furniture", String(furniture.get("name", "家具")))
			message = "%s の部屋に %s を置くことにした。" % [name, String(furniture.get("name", "家具"))]
		"want_tool":
			var tool := _best_item_for_profile("tools", profile)
			_add_inventory_item(profile, "tools", String(tool.get("name", "道具")))
			message = "%s は %s を受け取った。" % [name, String(tool.get("name", "道具"))]
		"make_friend":
			var partner := _find_any_partner(selected_index)
			if partner != -1:
				_adjust_relationship(selected_index, partner, 12, true)
				message = "%s は %s と話すきっかけを作った。" % [name, String(residents[partner]["profile"].get("name", "Resident"))]
			else:
				message = "%s は少し気持ちを整理した。" % name
		"make_up":
			var target_name := String(problem.get("target", ""))
			var target_index := _find_resident_by_name(target_name)
			if target_index != -1:
				_adjust_relationship(selected_index, target_index, 30, true)
				message = "%s は %s と仲直りした。" % [name, target_name]
			else:
				message = "%s は仲直りの言葉を考えた。" % name
		"high_door":
			message = "%s はドアの前で頭を少し下げる癖をつかんだ。" % name
			satisfaction_gain = 7.0
		"tall_help":
			var helped := _find_short_resident()
			if helped != -1:
				_adjust_relationship(selected_index, helped, 10, true)
				message = "%s は %s の代わりに棚の上段を取った。" % [name, String(residents[helped]["profile"].get("name", "Resident"))]
			else:
				message = "%s は棚の上段を整えた。" % name
		"shelf_help":
			var helper := _find_tall_resident()
			if helper != -1:
				_adjust_relationship(selected_index, helper, 10, true)
				message = "%s は %s に棚の上段を取ってもらった。" % [name, String(residents[helper]["profile"].get("name", "Resident"))]
			else:
				_add_inventory_item(profile, "furniture", "踏み台")
				message = "%s は踏み台を使うことにした。" % name
		_:
			message = "%s の相談を聞いた。" % name

	_apply_satisfaction(profile, satisfaction_gain)
	profile["current_problem"] = {}
	resident["profile"] = profile
	residents[selected_index] = resident
	_rebuild_resident_avatar(selected_index)
	_set_problem_marker(selected_index, false)
	_record_event(message)
	_save_residents()
	return true


func _best_item_for_profile(category: String, profile: Dictionary) -> Dictionary:
	var likes: Dictionary = profile.get("likes", {})
	var liked_tag := String(likes.get(category, ""))
	var items := _gift_items_for_category(category)
	for item in items:
		if String(item.get("tag", "")) == liked_tag:
			return item
	return items[0]


func _find_any_partner(index: int) -> int:
	for other in range(residents.size()):
		if other != index:
			return other
	return -1


func _find_resident_by_name(target_name: String) -> int:
	for index in range(residents.size()):
		var profile: Dictionary = residents[index]["profile"]
		if String(profile.get("name", "Resident")) == target_name:
			return index
	return -1


func _find_tall_resident() -> int:
	for index in range(residents.size()):
		if index == selected_index:
			continue
		var profile: Dictionary = residents[index]["profile"]
		if float(profile.get("height", DEFAULT_HEIGHT)) >= 1.90:
			return index
	return -1


func _find_short_resident() -> int:
	for index in range(residents.size()):
		if index == selected_index:
			continue
		var profile: Dictionary = residents[index]["profile"]
		if float(profile.get("height", DEFAULT_HEIGHT)) <= 1.55:
			return index
	return -1


func _cycle_gift_category() -> void:
	gift_category_index = _wrap_index(gift_category_index + 1, GIFT_CATEGORY_KEYS.size())
	gift_item_index = 0


func _cycle_gift_item() -> void:
	gift_item_index = _wrap_index(gift_item_index + 1, _gift_items_for_current_category().size())


func _give_selected_gift() -> void:
	var category := _current_gift_category()
	var item := _current_gift_item()
	var resident: Dictionary = residents[selected_index]
	var profile: Dictionary = resident["profile"]
	var name := String(profile.get("name", "Resident"))
	var item_name := String(item.get("name", "贈り物"))
	var item_tag := String(item.get("tag", ""))
	var likes: Dictionary = profile.get("likes", {})
	var liked := String(likes.get(category, "")) == item_tag
	var gain := 12.0 if liked else 5.0

	_add_inventory_item(profile, category, item_name)
	if category == "clothes":
		_apply_clothes_item(profile, item)
		_rebuild_resident_avatar(selected_index)

	var problem: Dictionary = profile.get("current_problem", {})
	if not problem.is_empty() and String(problem.get("category", "")) == category:
		profile["current_problem"] = {}
		gain += 6.0
		_set_problem_marker(selected_index, false)

	_apply_satisfaction(profile, gain)
	resident["profile"] = profile
	residents[selected_index] = resident
	_record_event("%s に %s を渡した。%s" % [name, item_name, "好みに合った。" if liked else "少しうれしそうだ。"])
	_save_residents()


func _current_gift_category() -> String:
	return String(GIFT_CATEGORY_KEYS[gift_category_index % GIFT_CATEGORY_KEYS.size()])


func _current_gift_item() -> Dictionary:
	var items := _gift_items_for_current_category()
	return items[gift_item_index % items.size()]


func _gift_items_for_current_category() -> Array:
	return _gift_items_for_category(_current_gift_category())


func _gift_items_for_category(category: String) -> Array:
	match category:
		"food":
			return FOOD_ITEMS
		"clothes":
			return CLOTHES_ITEMS
		"furniture":
			return FURNITURE_ITEMS
		"tools":
			return TOOL_ITEMS
	return FOOD_ITEMS


func _add_inventory_item(profile: Dictionary, category: String, item_name: String) -> void:
	var inventory := _ensure_inventory(profile.get("inventory", {}))
	var list: Array = inventory.get(category, [])
	list.append(item_name)
	inventory[category] = list
	profile["inventory"] = inventory


func _apply_clothes_item(profile: Dictionary, item: Dictionary) -> void:
	profile["outfit_type"] = String(item.get("outfit", "casual"))
	profile["cloth_color"] = item.get("color", profile.get("cloth_color", CLOTH_COLORS[0]))
	var color_index := _nearest_color_index(profile["cloth_color"], CLOTH_COLORS)
	profile["cloth_color_index"] = color_index


func _nearest_color_index(color: Color, palette: Array) -> int:
	var best_index := 0
	var best_distance := 9999.0
	for index in range(palette.size()):
		var other: Color = palette[index]
		var distance := absf(color.r - other.r) + absf(color.g - other.g) + absf(color.b - other.b)
		if distance < best_distance:
			best_distance = distance
			best_index = index
	return best_index


func _apply_satisfaction(profile: Dictionary, amount: float) -> void:
	profile["satisfaction"] = clampf(float(profile.get("satisfaction", 0.0)) + amount, 0.0, 100.0)


func _add_lights() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Soft Window Light"
	sun.light_energy = 1.4
	sun.rotation_degrees = Vector3(-42.0, -10.0, 0.0)
	add_child(sun)

	var room_light := OmniLight3D.new()
	room_light.name = "Shared Soft Light"
	room_light.position = Vector3(0.0, 3.8, 1.4)
	room_light.light_energy = 2.2
	room_light.omni_range = 8.5
	add_child(room_light)


func _add_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Front Dollhouse Camera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	add_child(camera)


func _update_camera() -> void:
	if camera == null:
		return

	var target := Vector3(0.0, 0.90, -0.25)
	if current_place == "room":
		target = Vector3(0.0, 1.15, -0.05)

	var offset := Vector3(sin(camera_yaw) * camera_distance, camera_height, cos(camera_yaw) * camera_distance)
	camera.position = target + offset
	camera.size = camera_size
	camera.look_at(target, Vector3.UP)


func _add_island() -> void:
	_add_box("Sea", Vector3(10.0, 0.05, 8.0), Vector3(0.0, -0.10, 0.0), Color(0.20, 0.48, 0.70))

	var island := _add_cylinder("Oval Island", 1.0, 0.16, Vector3(0.0, -0.02, 0.0), Color(0.42, 0.68, 0.40))
	island.scale = Vector3(ISLAND_RADIUS_X, 1.0, ISLAND_RADIUS_Z)

	_add_box("Front Dock", Vector3(0.95, 0.08, 0.90), Vector3(0.0, 0.04, 2.42), Color(0.62, 0.46, 0.28))
	_add_box("Main Path", Vector3(0.42, 0.035, 3.20), Vector3(0.0, 0.075, 0.50), Color(0.78, 0.70, 0.52))
	_add_box("Cross Path", Vector3(4.50, 0.035, 0.38), Vector3(0.0, 0.08, -0.25), Color(0.78, 0.70, 0.52))
	_add_box("Home Door Mat", Vector3(0.72, 0.032, 0.46), HOUSE_ENTRY_POINT + Vector3(0.0, 0.035, 0.0), Color(0.88, 0.62, 0.28))

	_add_house("Center Home", Vector3(0.0, 0.0, -1.52), Color(0.86, 0.62, 0.48), Color(0.54, 0.20, 0.22), true)
	_add_house("Left Home", Vector3(-2.25, 0.0, -0.92), Color(0.52, 0.70, 0.82), Color(0.24, 0.28, 0.50), false)
	_add_house("Right Home", Vector3(2.24, 0.0, -0.74), Color(0.82, 0.72, 0.45), Color(0.45, 0.25, 0.12), false)


func _add_house(label: String, base_position: Vector3, wall_color: Color, roof_color: Color, active: bool) -> void:
	var size_scale := 1.10 if active else 0.86
	_add_box(label + " Body", Vector3(1.28, 1.02, 0.82) * size_scale, base_position + Vector3(0.0, 0.51 * size_scale, 0.0), wall_color)
	_add_box(label + " Roof", Vector3(1.56, 0.32, 1.00) * size_scale, base_position + Vector3(0.0, 1.12 * size_scale, 0.0), roof_color)
	_add_box(label + " Door", Vector3(0.34, 0.66, 0.035) * size_scale, base_position + Vector3(0.0, 0.35 * size_scale, 0.43 * size_scale), Color(0.36, 0.22, 0.15))
	_add_box(label + " Left Window", Vector3(0.24, 0.24, 0.035) * size_scale, base_position + Vector3(-0.40 * size_scale, 0.61 * size_scale, 0.435 * size_scale), Color(0.85, 0.94, 1.00))
	_add_box(label + " Right Window", Vector3(0.24, 0.24, 0.035) * size_scale, base_position + Vector3(0.40 * size_scale, 0.61 * size_scale, 0.435 * size_scale), Color(0.85, 0.94, 1.00))


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
	_add_box("Exit Mat", Vector3(0.80, 0.022, 0.42), ROOM_EXIT_POINT + Vector3(0.0, 0.030, 0.0), Color(0.82, 0.58, 0.34))


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
	for i in range(1, 8):
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
	var visual_scale: float = node.scale.x
	selection_marker.position = Vector3(node.position.x, 0.018, node.position.z)
	selection_marker.scale = Vector3(maxf(height * visual_scale * 0.34, 0.30), 1.0, maxf(height * visual_scale * 0.34, 0.30))


func _add_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "Resident HUD"
	resident_label = Label.new()
	resident_label.position = Vector2(16.0, 14.0)
	var japanese_font := SystemFont.new()
	japanese_font.font_names = ["Yu Gothic", "Meiryo", "Noto Sans CJK JP", "Noto Sans JP"]
	resident_label.add_theme_font_override("font", japanese_font)
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
	var node: Node3D = resident["node"] as Node3D
	var place_label := "部屋" if current_place == "room" else "島"
	var door_hint := ""
	if current_place == "island" and node.position.distance_to(HOUSE_ENTRY_POINT) <= 0.78:
		door_hint = "E: 家に入る"
	elif current_place == "room" and node.position.distance_to(ROOM_EXIT_POINT) <= 0.78:
		door_hint = "E: 家から出る"
	elif current_place == "room":
		door_hint = "E: 近くの家具/相談"
	else:
		door_hint = "E: 相談"

	var problem: Dictionary = profile.get("current_problem", {})
	var problem_text := String(problem.get("text", "なし")) if not problem.is_empty() else "なし"
	var gift_item := _current_gift_item()
	var gift_text := "%s / %s" % [String(GIFT_CATEGORY_LABELS.get(_current_gift_category(), "贈り物")), String(gift_item.get("name", "贈り物"))]

	var edit_hint := "F: 編集  R: 種類切替  Z/X: 調整  T/U/Y: 贈り物"
	if edit_mode:
		edit_hint = "編集中 %s %d %s %.2f | R:種類 1-6:項目 Z/X:調整 F:終了" % [
			_edit_section_name(edit_section),
			edit_axis + 1,
			_edit_axis_name(),
			_edit_axis_value(profile)
		]

	resident_label.text = "%s  %s\n身長 %.2fm  頭 %.2f  胴 %.2f  脚補正 %.2f  幅 %.2f  厚み %.2f\n性格: %s  満足度: %.0f  状態: %s\n相談: %s\n贈り物: %s\n%s\n%s\n%s" % [
		String(profile.get("name", "Resident")),
		place_label,
		float(profile.get("height", DEFAULT_HEIGHT)),
		float(profile.get("head_ratio", 0.24)),
		float(profile.get("torso_ratio", 0.50)),
		float(profile.get("leg_bias", 0.0)),
		float(profile.get("shoulder_scale", 1.0)),
		float(profile.get("body_depth_scale", 1.0)),
		String(profile.get("personality", "ふつう")),
		float(profile.get("satisfaction", 0.0)),
		_state_label(String(resident.get("state", "idle"))),
		problem_text,
		gift_text,
		door_hint,
		edit_hint,
		event_log
	]


func _edit_section_name(section: int) -> String:
	match section:
		EDIT_SECTION_BODY:
			return "体型"
		EDIT_SECTION_FACE:
			return "顔"
		EDIT_SECTION_HAIR:
			return "髪"
		EDIT_SECTION_CLOTHES:
			return "服"
	return "編集"


func _edit_axis_name() -> String:
	match edit_section:
		EDIT_SECTION_BODY:
			match edit_axis:
				BODY_AXIS_HEIGHT:
					return "身長"
				BODY_AXIS_HEAD:
					return "頭"
				BODY_AXIS_TORSO:
					return "胴"
				BODY_AXIS_LEGS:
					return "脚"
				BODY_AXIS_WIDTH:
					return "横幅"
				BODY_AXIS_DEPTH:
					return "厚み"
		EDIT_SECTION_FACE:
			match edit_axis:
				FACE_AXIS_EYE_SPACING:
					return "目の間隔"
				FACE_AXIS_EYE_HEIGHT:
					return "目の高さ"
				FACE_AXIS_EYE_SIZE:
					return "目の大きさ"
				FACE_AXIS_MOUTH_WIDTH:
					return "口の幅"
				FACE_AXIS_MOUTH_HEIGHT:
					return "口の高さ"
		EDIT_SECTION_HAIR:
			match edit_axis:
				HAIR_AXIS_STYLE:
					return "髪型"
				HAIR_AXIS_COLOR:
					return "髪色"
				HAIR_AXIS_VOLUME:
					return "髪の量"
		EDIT_SECTION_CLOTHES:
			match edit_axis:
				CLOTHES_AXIS_STYLE:
					return "服の種類"
				CLOTHES_AXIS_COLOR:
					return "服の色"
				CLOTHES_AXIS_SKIN:
					return "肌の色"
	return "項目"


func _edit_axis_value(profile: Dictionary) -> float:
	match edit_section:
		EDIT_SECTION_BODY:
			match edit_axis:
				BODY_AXIS_HEIGHT:
					return float(profile.get("height", DEFAULT_HEIGHT))
				BODY_AXIS_HEAD:
					return float(profile.get("head_ratio", 0.24))
				BODY_AXIS_TORSO:
					return float(profile.get("torso_ratio", 0.50))
				BODY_AXIS_LEGS:
					return float(profile.get("leg_bias", 0.0))
				BODY_AXIS_WIDTH:
					return float(profile.get("shoulder_scale", 1.0))
				BODY_AXIS_DEPTH:
					return float(profile.get("body_depth_scale", 1.0))
		EDIT_SECTION_FACE:
			match edit_axis:
				FACE_AXIS_EYE_SPACING:
					return float(profile.get("eye_spacing", 0.40))
				FACE_AXIS_EYE_HEIGHT:
					return float(profile.get("eye_height", 0.04))
				FACE_AXIS_EYE_SIZE:
					return float(profile.get("eye_size", 0.052))
				FACE_AXIS_MOUTH_WIDTH:
					return float(profile.get("mouth_width", 0.24))
				FACE_AXIS_MOUTH_HEIGHT:
					return float(profile.get("mouth_y", -0.20))
		EDIT_SECTION_HAIR:
			match edit_axis:
				HAIR_AXIS_STYLE:
					return float(profile.get("hair_style", 0))
				HAIR_AXIS_COLOR:
					return float(profile.get("hair_color_index", 0))
				HAIR_AXIS_VOLUME:
					return float(profile.get("hair_volume", 1.0))
		EDIT_SECTION_CLOTHES:
			match edit_axis:
				CLOTHES_AXIS_STYLE:
					return float(OUTFIT_ORDER.find(String(profile.get("outfit_type", "casual"))))
				CLOTHES_AXIS_COLOR:
					return float(profile.get("cloth_color_index", 0))
				CLOTHES_AXIS_SKIN:
					return float(profile.get("skin_color_index", 0))
	return 0.0


func _state_label(state: String) -> String:
	match state:
		"selected":
			return "操作中"
		"idle":
			return "待機"
		"wander":
			return "散歩"
		"meet":
			return "近づく"
		"chat":
			return "会話"
		"manual":
			return "移動中"
		"fight":
			return "けんか"
		"visit":
			return "訪問"
	return "待機"


func _record_event(message: String) -> void:
	event_log = message


func _refresh_resident_markers(index: int) -> void:
	var resident: Dictionary = residents[index]
	var state := String(resident.get("state", "idle"))
	_set_chat_marker(index, state == "chat")
	var profile: Dictionary = resident["profile"]
	var problem: Dictionary = profile.get("current_problem", {})
	_set_problem_marker(index, not problem.is_empty())


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


func _set_problem_marker(index: int, enabled: bool) -> void:
	if index < 0 or index >= residents.size():
		return

	var resident: Dictionary = residents[index]
	var node: Node3D = resident["node"] as Node3D
	var existing := node.get_node_or_null("Problem Marker")
	if existing != null:
		existing.queue_free()

	if not enabled:
		return

	var profile: Dictionary = resident["profile"]
	var problem: Dictionary = profile.get("current_problem", {})
	var color := Color(0.95, 0.36, 0.24)
	if String(problem.get("category", "")) == "height":
		color = Color(0.44, 0.66, 0.95)
	elif String(problem.get("category", "")) == "relationship":
		color = Color(0.90, 0.52, 0.82)

	var marker := MeshInstance3D.new()
	marker.name = "Problem Marker"
	marker.mesh = _sphere_mesh(0.095)
	marker.position = Vector3(0.0, float(profile.get("height", DEFAULT_HEIGHT)) + 0.40, 0.0)
	marker.material_override = _material(color)
	node.add_child(marker)


func _add_box(node_name: String, size: Vector3, position: Vector3, color: Color, transparent := false) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = _box_mesh(size)
	instance.position = position
	instance.material_override = _material(color, transparent)
	if build_root == null:
		add_child(instance)
	else:
		build_root.add_child(instance)
	return instance


func _add_cylinder(node_name: String, radius: float, height: float, position: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = _cylinder_mesh(radius, height)
	instance.position = position
	instance.material_override = _material(color)
	if build_root == null:
		add_child(instance)
	else:
		build_root.add_child(instance)
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


func _cylinder_mesh(radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 48
	return mesh


func _material(color: Color, transparent := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	if transparent or color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = minf(color.a, 0.56)
	return material
