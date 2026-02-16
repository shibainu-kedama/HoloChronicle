extends Resource
class_name PotionData

@export var id: String = ""
@export var name: String = ""
@export var effect: String = ""    # "heal" / "energy" / "strength" / "aoe_poison"
@export var value: int = 0
@export var price: int = 0
@export var description: String = ""

static func from_dict(d: Dictionary) -> PotionData:
	var p := PotionData.new()
	p.id          = d.get("id", "")
	p.name        = d.get("name", "")
	p.effect      = d.get("effect", "")
	p.value       = int(d.get("value", "0"))
	p.price       = int(d.get("price", "0"))
	p.description = d.get("description", "")
	return p
