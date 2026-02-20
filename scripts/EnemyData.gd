extends RefCounted
class_name EnemyData

var id: String
var name: String
var hp: int
var stage: int
var is_boss: bool
var is_elite: bool
var image_path: String
## パターン辞書。キー "type" が "random" / "seq" / "phase" のいずれか。
## random: {"type":"random", "pool":[{type,power,weight,...}]}
## seq:    {"type":"seq",    "steps":[{type,power,...}]}  ← ループ再生
## phase:  {"type":"phase",  "phases":[{"threshold":int, "pool":[...]}]}
var actions: Dictionary = {}
var count: int = 1
