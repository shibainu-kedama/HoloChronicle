# CharacterData.gd
extends Resource
class_name CharacterData

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var hp: int = 0
@export var gold: int = 0

@export var image_path: String = ""        # 立ち絵 or 背景用
@export var talent_name: String = ""
@export var talent_desc: String = ""
@export var talent_icon_path: String = ""  # タレントアイコン用
@export var tag: String = ""               # 推しタグ（例: "miko", "suisei"）
@export var starting_goods_id: String = "" # 初期グッズID

static func from_dict(d: Dictionary) -> CharacterData:
	var c := CharacterData.new()
	c.id               = d.get("id", "")
	c.name             = d.get("name", "")
	c.description      = d.get("description", "")
	c.hp               = int(d.get("hp", "0"))
	c.gold             = int(d.get("gold", "0"))
	c.image_path       = d.get("image_path", "")
	c.talent_name      = d.get("talent_name", "")
	c.talent_desc      = d.get("talent_desc", "")
	c.talent_icon_path = d.get("talent_icon_path", "")
	c.tag              = d.get("tag", "")
	c.starting_goods_id = d.get("starting_goods_id", "")
	return c
