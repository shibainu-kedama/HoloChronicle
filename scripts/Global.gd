extends Node

# === 追加: ステージ種別 ===
enum StageType { BATTLE, REST, EVENT, BOSS }
var current_stage_type: int = StageType.BATTLE

# プレイヤーHP（-1 = 未初期化）
var player_hp: int = -1
var player_max_hp: int = 100

# プレイヤーのデッキ
var player_deck: Array[CardData] = []

# 直前の戦闘報酬候補
var last_battle_reward_candidates: Array[CardData] = []

# 選択中のキャラ（CharacterDataに統一）
var selected_character: CharacterData

# マップ関連
var unlocked_nodes: Array[String] = []
var node_links: Dictionary = {}      # ここは { String: Array[String] } のような構造想定

# 現在のマップノードID（通過中）
var current_node_id: String = ""
# すでに通過したノードの記録
var passed_nodes: Array[String] = []

# 現在のバトルで戦う敵ID
var current_enemy_id: String = ""


func is_node_unlocked(node_id: String) -> bool:
	return unlocked_nodes.has(node_id)


func unlock_start_node(start_id: String) -> void:
	unlocked_nodes = [start_id]
	current_node_id = start_id


func unlock_next_nodes(from_id: String) -> void:
	print("🔓 unlock_next_nodes:", from_id)
	if node_links.has(from_id):
		for next_id in node_links[from_id]:
			print(" → 解放候補:", next_id)
			if not unlocked_nodes.has(next_id):
				unlocked_nodes.append(next_id)
				print(" ✅ 解放:", next_id)
	print("🧭 unlocked_nodes:", unlocked_nodes)


# === 追加: 便利ヘルパー（任意）===
func set_stage_type_from_string(t: String) -> void:
	match t:
		"battle":
			current_stage_type = StageType.BATTLE
		"rest":
			current_stage_type = StageType.REST
		"event":
			current_stage_type = StageType.EVENT
		"boss":
			current_stage_type = StageType.BOSS
		_:
			current_stage_type = StageType.BATTLE


func is_boss_stage() -> bool:
	return current_stage_type == StageType.BOSS
