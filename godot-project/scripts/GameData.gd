extends RefCounted
class_name GameData

const SAVE_PATH := "user://residents.json"

const ROOM_WIDTH := 5.0
const ROOM_DEPTH := 4.0
const ROOM_HEIGHT := 2.4

const ISLAND_RADIUS_X := 6.20
const ISLAND_RADIUS_Z := 4.15

const DEFAULT_HEIGHT := 1.60
const DEFAULT_DOOR_HEIGHT := 2.00
const HEIGHT_MIN := 1.35
const HEIGHT_MAX := 3.20
const STARTING_RESIDENT_COUNT := 1
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
const CLOTHES_AXIS_SHOES := 3

const HOUSE_ENTRY_POINT := Vector3(0.0, 0.0, -0.82)
const ROOM_EXIT_POINT := Vector3(1.45, 0.0, -1.43)
const ISLAND_HOUSE_BLOCKERS := [
	{"center": Vector2(0.0, -1.52), "half_extents": Vector2(0.86, 0.64)},
	{"center": Vector2(-3.35, -1.10), "half_extents": Vector2(0.72, 0.56)},
	{"center": Vector2(3.35, -0.96), "half_extents": Vector2(0.72, 0.56)}
]

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
const SHOE_COLORS := [
	Color(0.10, 0.10, 0.12),
	Color(0.34, 0.22, 0.14),
	Color(0.86, 0.82, 0.72),
	Color(0.18, 0.24, 0.36),
	Color(0.62, 0.22, 0.28)
]
const HAIR_STYLE_LABELS := ["短め", "長め", "おだんご", "ポニーテール", "ボブ"]
const HAIR_COLOR_LABELS := ["黒髪", "こげ茶", "栗色", "濃い黒", "赤みブラウン"]
const CLOTH_COLOR_LABELS := ["青", "赤", "緑", "茶", "紺", "くすみ緑"]
const SKIN_COLOR_LABELS := ["明るめ", "自然", "健康的", "褐色", "淡い"]
const SHOE_COLOR_LABELS := ["黒", "茶", "生成り", "紺", "赤茶"]
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
