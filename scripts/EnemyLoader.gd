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

# === アクションパターン解析 ===
#
# 対応フォーマット:
#   SEQ|type:power|type:power:times|...
#       → 固定順序ループ。weight不要。
#   PHASE|threshold|type:power:weight|...;threshold|...
#       → HP閾値別ランダムプール。;区切りで複数フェーズ。
#       thresholdはHP%（整数）。高→低の順で照合。
#   type:power:weight|type:power:weight|...
#       → 従来の重み付きランダム（後方互換）。

func _parse_actions(actions_str: String) -> Dictionary:
	var s := actions_str.strip_edges()

	# ── SEQ パターン ──
	if s.begins_with("SEQ|"):
		var steps: Array = []
		for step in s.substr(4).split("|"):
			step = step.strip_edges()
			if step != "":
				var a := _parse_action(step)
				if not a.is_empty():
					steps.append(a)
		return {"type": "seq", "steps": steps}

	# ── PHASE パターン ──
	elif s.begins_with("PHASE|"):
		var phases: Array = []
		for seg in s.substr(6).split(";"):
			seg = seg.strip_edges()
			if seg == "":
				continue
			var parts := seg.split("|")
			if parts.size() < 2:
				continue
			var threshold := int(parts[0].strip_edges())
			var pool: Array = []
			for j in range(1, parts.size()):
				var step := parts[j].strip_edges()
				if step != "":
					var a := _parse_action(step)
					if not a.is_empty():
						pool.append(a)
			phases.append({"threshold": threshold, "pool": pool})
		# 閾値降順ソート（高いほど先に判定）
		phases.sort_custom(func(a, b): return a.threshold > b.threshold)
		return {"type": "phase", "phases": phases}

	# ── RANDOM パターン（従来互換）──
	else:
		var pool: Array = []
		for part in s.split("|"):
			part = part.strip_edges()
			if part != "":
				var a := _parse_action(part)
				if not a.is_empty():
					pool.append(a)
		return {"type": "random", "pool": pool}

## "type:power[:times][:weight]" → Dictionary
## weight は省略時 1。times は multi_attack 用。
func _parse_action(s: String) -> Dictionary:
	var tokens := s.split(":")
	if tokens.is_empty() or tokens[0].strip_edges() == "":
		return {}
	var a := {"type": tokens[0].strip_edges(), "power": 0, "weight": 1}
	if tokens.size() >= 2:
		var p := tokens[1].strip_edges()
		if "x" in p:
			var px := p.split("x")
			a["power"] = int(px[0])
			a["times"] = int(px[1])
		else:
			a["power"] = int(p)
	if tokens.size() >= 3:
		a["weight"] = int(tokens[2].strip_edges())
	return a

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
