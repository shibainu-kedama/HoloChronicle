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

static func from_dict(data: Dictionary) -> CardData:
	var card = CardData.new()
	card.id = data.get("id", "")
	card.name = data.get("name", "")
	card.effect = data.get("effect", "")
	card.power = int(data.get("power", "0"))
	card.cost = int(data.get("cost", "0"))
	card.info = data.get("info", "")
	card.image_path = data.get("image_path", "")
	return card
