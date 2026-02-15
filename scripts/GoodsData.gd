# GoodsData.gd
extends Resource
class_name GoodsData

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var trigger: String = ""   # "battle_start" / "turn_start" / "on_tagged_card" / "battle_end"
@export var effect: String = ""    # "heal" / "block" / "energy" / "gold"
@export var value: int = 0
@export var tag: String = ""

static func from_dict(d: Dictionary) -> GoodsData:
	var g := GoodsData.new()
	g.id          = d.get("id", "")
	g.name        = d.get("name", "")
	g.description = d.get("description", "")
	g.trigger     = d.get("trigger", "")
	g.effect      = d.get("effect", "")
	g.value       = int(d.get("value", "0"))
	g.tag         = d.get("tag", "")
	return g
