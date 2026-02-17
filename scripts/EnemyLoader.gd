extends Node

var all_enemies: Array[EnemyData] = []

func _ready():
	load_enemies_from_csv("res://data/enemies.csv")

func load_enemies_from_csv(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("敵データCSV読み込み失敗: %s" % path)
		return

	var header = file.get_line()
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line == "":
			continue
		var cols = line.split(",")
		if cols.size() < 8:
			continue

		var enemy = EnemyData.new()
		enemy.id = cols[0]
		enemy.name = cols[1]
		enemy.hp = int(cols[2])
		enemy.stage = int(cols[3])
		enemy.is_boss = cols[4].strip_edges().to_lower() == "true"
		enemy.is_elite = cols[5].strip_edges().to_lower() == "true"
		enemy.image_path = cols[6]
		enemy.actions = _parse_actions(cols[7])
		if cols.size() >= 9:
			enemy.count = int(cols[8])
		all_enemies.append(enemy)

func _parse_actions(actions_str: String) -> Array:
	var actions: Array = []
	var parts = actions_str.split("|")
	for part in parts:
		var tokens = part.split(":")
		if tokens.size() < 3:
			continue
		var action = {}
		action["type"] = tokens[0]
		var power_str = tokens[1]
		if "x" in power_str:
			var px = power_str.split("x")
			action["power"] = int(px[0])
			action["times"] = int(px[1])
		else:
			action["power"] = int(power_str)
		action["weight"] = int(tokens[2])
		actions.append(action)
	return actions

func get_enemy_by_id(id: String) -> EnemyData:
	for enemy in all_enemies:
		if enemy.id == id:
			return enemy
	push_error("敵ID '%s' が見つかりません" % id)
	return null

func get_random_enemy_for_stage(stage: int, is_boss: bool = false, is_elite: bool = false) -> EnemyData:
	var candidates: Array[EnemyData] = []
	for enemy in all_enemies:
		if enemy.is_boss == is_boss and enemy.is_elite == is_elite and enemy.stage == stage:
			candidates.append(enemy)
	# 該当stageの敵がなければ、最も近いstageの敵を返す
	if candidates.is_empty():
		for enemy in all_enemies:
			if enemy.is_boss == is_boss and enemy.is_elite == is_elite:
				candidates.append(enemy)
	if candidates.is_empty():
		return null
	return candidates[randi() % candidates.size()]
