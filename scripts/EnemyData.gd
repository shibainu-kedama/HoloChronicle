extends RefCounted
class_name EnemyData

var id: String
var name: String
var hp: int
var stage: int
var is_boss: bool
var image_path: String
var actions: Array = []  # [{"type": "attack", "power": 8, "weight": 2}, ...]
