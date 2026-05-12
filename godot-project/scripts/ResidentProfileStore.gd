extends RefCounted
class_name ResidentProfileStore

const GameDataScript := preload("res://scripts/GameData.gd")


static func load_profiles(starting_count: int) -> Array[Dictionary]:
	var profiles: Array[Dictionary] = []
	if FileAccess.file_exists(GameDataScript.SAVE_PATH):
		var text := FileAccess.get_file_as_string(GameDataScript.SAVE_PATH)
		var parsed = JSON.parse_string(text)
		if parsed is Array:
			for raw_profile in parsed:
				if raw_profile is Dictionary:
					profiles.append(profile_from_save(raw_profile))

	if profiles.is_empty():
		profiles = default_profiles()
		if profiles.size() > starting_count:
			profiles.resize(starting_count)

	for index in range(profiles.size()):
		profiles[index] = ensure_profile_defaults(profiles[index], index)
	return profiles


static func save_residents(residents: Array[Dictionary]) -> void:
	var save_data := []
	for resident in residents:
		var profile: Dictionary = resident["profile"]
		save_data.append(profile_to_save(profile))

	var file := FileAccess.open(GameDataScript.SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(save_data, "\t"))


static func new_profile(index: int) -> Dictionary:
	var defaults := default_profiles()
	var profile: Dictionary = defaults[index % defaults.size()].duplicate(true)
	profile["relationships"] = {}
	profile["inventory"] = {}
	profile["current_problem"] = {}
	return ensure_profile_defaults(profile, index)


static func default_profiles() -> Array[Dictionary]:
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
			"cloth_color": GameDataScript.CLOTH_COLORS[1],
			"skin_color_index": 0,
			"skin_color": GameDataScript.SKIN_COLORS[0],
			"hair_color_index": 0,
			"hair_color": GameDataScript.HAIR_COLORS[0],
			"hair_style": 1,
			"hair_volume": 1.0,
			"eye_spacing": 0.42,
			"eye_height": 0.05,
			"eye_size": 0.055,
			"eye_style": 0,
			"mouth_width": 0.26,
			"mouth_y": -0.22,
			"mouth_style": 0,
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
			"cloth_color": GameDataScript.CLOTH_COLORS[0],
			"skin_color_index": 1,
			"skin_color": GameDataScript.SKIN_COLORS[1],
			"hair_color_index": 1,
			"hair_color": GameDataScript.HAIR_COLORS[1],
			"hair_style": 0,
			"hair_volume": 1.0,
			"eye_spacing": 0.38,
			"eye_height": 0.02,
			"eye_size": 0.052,
			"eye_style": 1,
			"mouth_width": 0.22,
			"mouth_y": -0.20,
			"mouth_style": 0,
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
			"cloth_color": GameDataScript.CLOTH_COLORS[2],
			"skin_color_index": 2,
			"skin_color": GameDataScript.SKIN_COLORS[2],
			"hair_color_index": 3,
			"hair_color": GameDataScript.HAIR_COLORS[3],
			"hair_style": 2,
			"hair_volume": 1.0,
			"eye_spacing": 0.46,
			"eye_height": 0.07,
			"eye_size": 0.062,
			"eye_style": 0,
			"mouth_width": 0.20,
			"mouth_y": -0.18,
			"mouth_style": 2,
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
			"cloth_color": GameDataScript.CLOTH_COLORS[3],
			"skin_color_index": 0,
			"skin_color": GameDataScript.SKIN_COLORS[0],
			"hair_color_index": 0,
			"hair_color": GameDataScript.HAIR_COLORS[0],
			"hair_style": 0,
			"hair_volume": 0.94,
			"eye_spacing": 0.34,
			"eye_height": 0.04,
			"eye_size": 0.050,
			"eye_style": 2,
			"mouth_width": 0.28,
			"mouth_y": -0.25,
			"mouth_style": 1,
			"outfit_type": "formal",
			"personality": "元気",
			"likes": {"food": "米", "clothes": "きれいな服", "furniture": "椅子", "tools": "読書"},
			"satisfaction": 20.0,
			"relationships": {},
			"inventory": {}
		}
	]


static func ensure_profile_defaults(profile: Dictionary, index: int) -> Dictionary:
	var defaults := default_profiles()
	var fallback: Dictionary = defaults[index % defaults.size()]
	for key in fallback.keys():
		if not profile.has(key):
			profile[key] = fallback[key]

	profile["height"] = clampf(float(profile.get("height", GameDataScript.DEFAULT_HEIGHT)), GameDataScript.HEIGHT_MIN, GameDataScript.HEIGHT_MAX)
	profile["head_ratio"] = clampf(float(profile.get("head_ratio", 0.24)), 0.18, 0.30)
	profile["torso_ratio"] = clampf(float(profile.get("torso_ratio", 0.50)), 0.44, 0.56)
	profile["leg_bias"] = clampf(float(profile.get("leg_bias", 0.0)), -0.08, 0.08)
	profile["eye_style"] = wrap_index(int(profile.get("eye_style", 0)), GameDataScript.FACE_EYE_STYLE_LABELS.size())
	profile["mouth_style"] = wrap_index(int(profile.get("mouth_style", 0)), GameDataScript.FACE_MOUTH_STYLE_LABELS.size())
	profile["hair_style"] = wrap_index(int(profile.get("hair_style", 0)), GameDataScript.HAIR_STYLE_LABELS.size())
	profile["hair_volume"] = clampf(float(profile.get("hair_volume", 1.0)), 0.82, 1.20)
	profile["cloth_color_index"] = wrap_index(int(profile.get("cloth_color_index", 0)), GameDataScript.CLOTH_COLORS.size())
	profile["skin_color_index"] = wrap_index(int(profile.get("skin_color_index", 0)), GameDataScript.SKIN_COLORS.size())
	profile["hair_color_index"] = wrap_index(int(profile.get("hair_color_index", 0)), GameDataScript.HAIR_COLORS.size())
	profile["shoe_color_index"] = wrap_index(int(profile.get("shoe_color_index", 0)), GameDataScript.SHOE_COLORS.size())
	profile["cloth_color"] = color_from_value(profile.get("cloth_color", GameDataScript.CLOTH_COLORS[int(profile["cloth_color_index"])]), GameDataScript.CLOTH_COLORS[int(profile["cloth_color_index"])])
	profile["skin_color"] = color_from_value(profile.get("skin_color", GameDataScript.SKIN_COLORS[int(profile["skin_color_index"])]), GameDataScript.SKIN_COLORS[int(profile["skin_color_index"])])
	profile["hair_color"] = color_from_value(profile.get("hair_color", GameDataScript.HAIR_COLORS[int(profile["hair_color_index"])]), GameDataScript.HAIR_COLORS[int(profile["hair_color_index"])])
	profile["shoe_color"] = color_from_value(profile.get("shoe_color", GameDataScript.SHOE_COLORS[int(profile["shoe_color_index"])]), GameDataScript.SHOE_COLORS[int(profile["shoe_color_index"])])
	profile["likes"] = ensure_dict(profile.get("likes", fallback.get("likes", {})))
	profile["relationships"] = ensure_dict(profile.get("relationships", {}))
	profile["inventory"] = ensure_inventory(profile.get("inventory", {}))
	if not profile.has("current_problem"):
		profile["current_problem"] = {}
	return profile


static func profile_from_save(raw_profile: Dictionary) -> Dictionary:
	var profile := raw_profile.duplicate(true)
	profile["cloth_color"] = color_from_value(profile.get("cloth_color", GameDataScript.CLOTH_COLORS[0]), GameDataScript.CLOTH_COLORS[0])
	profile["skin_color"] = color_from_value(profile.get("skin_color", GameDataScript.SKIN_COLORS[0]), GameDataScript.SKIN_COLORS[0])
	profile["hair_color"] = color_from_value(profile.get("hair_color", GameDataScript.HAIR_COLORS[0]), GameDataScript.HAIR_COLORS[0])
	profile["shoe_color"] = color_from_value(profile.get("shoe_color", GameDataScript.SHOE_COLORS[0]), GameDataScript.SHOE_COLORS[0])
	return profile


static func profile_to_save(profile: Dictionary) -> Dictionary:
	var saved := profile.duplicate(true)
	saved["cloth_color"] = color_to_html(profile.get("cloth_color", GameDataScript.CLOTH_COLORS[0]))
	saved["skin_color"] = color_to_html(profile.get("skin_color", GameDataScript.SKIN_COLORS[0]))
	saved["hair_color"] = color_to_html(profile.get("hair_color", GameDataScript.HAIR_COLORS[0]))
	saved["shoe_color"] = color_to_html(profile.get("shoe_color", GameDataScript.SHOE_COLORS[0]))
	return saved


static func ensure_inventory(value) -> Dictionary:
	var inventory := ensure_dict(value)
	for category in GameDataScript.GIFT_CATEGORY_KEYS:
		if not inventory.has(category) or not (inventory[category] is Array):
			inventory[category] = []
	return inventory


static func color_to_html(value) -> String:
	if typeof(value) == TYPE_COLOR:
		var color: Color = value
		return "#" + color.to_html(false)
	return String(value)


static func color_from_value(value, fallback: Color) -> Color:
	if typeof(value) == TYPE_COLOR:
		return value
	if typeof(value) == TYPE_STRING:
		var text := String(value)
		if text.is_empty():
			return fallback
		return Color.html(text)
	return fallback


static func ensure_dict(value) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


static func wrap_index(value: int, count: int) -> int:
	if count <= 0:
		return 0
	return (value % count + count) % count
