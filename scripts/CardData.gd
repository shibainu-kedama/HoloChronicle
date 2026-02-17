# CardData.gd
extends Resource
class_name CardData

var id: String = ""
@export var name: String
@export var effect: String
@export var power: int
@export var cost: int
@export var info: String
@export var image_path: String
@export var tags: PackedStringArray = []
var upgraded: bool = false

func has_tag(tag: String) -> bool:
	return tag in tags

func is_curse() -> bool:
	return has_tag("curse")

func upgrade() -> void:
	if upgraded:
		return
	upgraded = true
	match effect:
		"attack", "self_attack", "multi_attack":
			power += 3
		"block":
			power += 3
		"energy", "draw", "energy_burst":
			power += 1
		"heal":
			power += 3
		"aoe_attack":
			power += 3
		"vulnerable", "poison", "aoe_poison":
			power += 1
		"block_draw":
			power += 2
		"strength":
			power += 1
	name = name + "+"

static func from_dict(data: Dictionary) -> CardData:
	var card = CardData.new()
	card.id = data.get("id", "")
	card.name = data.get("name", "")
	card.effect = data.get("effect", "")
	card.power = int(data.get("power", "0"))
	card.cost = int(data.get("cost", "0"))
	card.info = data.get("info", "")
	card.image_path = data.get("image_path", "")
	var tags_str: String = data.get("tags", "")
	if tags_str != "":
		card.tags = PackedStringArray(tags_str.split("|"))
	return card
