extends Node

const HISTORY_PATH := "user://run_history.cfg"
const MAX_RUNS := 20

func record_run(result: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load(HISTORY_PATH)

	# 既存履歴を1つずつ後ろにシフト（古い順に処理）
	var old_total := 0
	while cfg.has_section("run_%d" % old_total):
		old_total += 1

	# 後ろからシフト
	for i in range(mini(old_total, MAX_RUNS - 1) - 1, -1, -1):
		var src := "run_%d" % i
		var dst := "run_%d" % (i + 1)
		for key in cfg.get_section_keys(src):
			cfg.set_value(dst, key, cfg.get_value(src, key))

	# MAX_RUNS を超えた分を削除
	for i in range(MAX_RUNS, old_total + 1):
		if cfg.has_section("run_%d" % i):
			cfg.erase_section("run_%d" % i)

	# run_0 に最新を書き込み
	var char_name := ""
	if Global.selected_character:
		char_name = Global.selected_character.name
	var stage := _get_stage_number()
	var deck_size := Global.player_deck.size()
	var gold: int = Global.player_gold if Global.player_gold >= 0 else 0
	var date := Time.get_datetime_string_from_system(false, true).substr(0, 16)

	cfg.set_value("run_0", "character", char_name)
	cfg.set_value("run_0", "result", result)
	cfg.set_value("run_0", "stage", stage)
	cfg.set_value("run_0", "deck_size", deck_size)
	cfg.set_value("run_0", "gold", gold)
	cfg.set_value("run_0", "date", date)

	# 累計統計を更新
	var total_runs: int = cfg.get_value("stats", "total_runs", 0) + 1
	var total_clears: int = cfg.get_value("stats", "total_clears", 0)
	if result == "clear":
		total_clears += 1
	cfg.set_value("stats", "total_runs", total_runs)
	cfg.set_value("stats", "total_clears", total_clears)

	cfg.save(HISTORY_PATH)

func get_history() -> Array[Dictionary]:
	var cfg := ConfigFile.new()
	cfg.load(HISTORY_PATH)
	var history: Array[Dictionary] = []
	var i := 0
	while cfg.has_section("run_%d" % i):
		var section := "run_%d" % i
		history.append({
			"character": cfg.get_value(section, "character", ""),
			"result": cfg.get_value(section, "result", ""),
			"stage": cfg.get_value(section, "stage", 0),
			"deck_size": cfg.get_value(section, "deck_size", 0),
			"gold": cfg.get_value(section, "gold", 0),
			"date": cfg.get_value(section, "date", ""),
		})
		i += 1
	return history

func get_stats() -> Dictionary:
	var cfg := ConfigFile.new()
	cfg.load(HISTORY_PATH)
	return {
		"total_runs": cfg.get_value("stats", "total_runs", 0),
		"total_clears": cfg.get_value("stats", "total_clears", 0),
	}

func _get_stage_number() -> int:
	var node_id := Global.current_node_id
	if node_id == "":
		return 1
	var num_str := ""
	for i in range(node_id.length()):
		if node_id[i].is_valid_int():
			num_str += node_id[i]
		else:
			break
	if num_str != "":
		return num_str.to_int()
	return 1
