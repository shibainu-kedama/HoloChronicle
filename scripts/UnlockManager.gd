extends Node

const UNLOCK_PATH := "user://unlocks.cfg"
const ACHIEVEMENTS_CSV_PATH := "res://data/achievements.csv"
const CHARACTER_UNLOCKS_CSV_PATH := "res://data/character_unlocks.csv"

# 実績定義（ID → 表示名・説明）CSVから読み込む
var ACHIEVEMENTS: Dictionary = {}

# キャラクターIDごとのクリアアンロック（カードID・グッズID）CSVから読み込む
var CHAR_CLEAR_UNLOCKS: Dictionary = {}

var _cfg: ConfigFile


func _ready() -> void:
	_cfg = ConfigFile.new()
	_cfg.load(UNLOCK_PATH)
	_load_achievements_from_csv()
	_load_character_unlocks_from_csv()


func _load_achievements_from_csv() -> void:
	ACHIEVEMENTS.clear()
	var file: FileAccess = FileAccess.open(ACHIEVEMENTS_CSV_PATH, FileAccess.READ)
	if file == null:
		push_error("実績CSVが開けませんでした: " + ACHIEVEMENTS_CSV_PATH)
		return
	if file.eof_reached():
		push_warning("実績CSVにデータがありません")
		return
	var headers: PackedStringArray = file.get_csv_line()
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() == 1 and row[0] == "":
			continue
		var id_col: int = headers.find("id")
		var name_col: int = headers.find("name")
		var desc_col: int = headers.find("desc")
		if id_col < 0 or name_col < 0 or desc_col < 0:
			push_error("実績CSVに id / name / desc 列がありません")
			return
		var ach_id: String = row[id_col] if id_col < row.size() else ""
		if ach_id.is_empty():
			continue
		ACHIEVEMENTS[ach_id] = {
			"name": row[name_col] if name_col < row.size() else ach_id,
			"desc": row[desc_col] if desc_col < row.size() else "",
		}


func _load_character_unlocks_from_csv() -> void:
	CHAR_CLEAR_UNLOCKS.clear()
	var file: FileAccess = FileAccess.open(CHARACTER_UNLOCKS_CSV_PATH, FileAccess.READ)
	if file == null:
		push_error("キャラアンロックCSVが開けませんでした: " + CHARACTER_UNLOCKS_CSV_PATH)
		return
	var headers: PackedStringArray = file.get_csv_line()
	var char_col: int = headers.find("char_id")
	var type_col: int = headers.find("unlock_type")
	var id_col: int = headers.find("unlock_id")
	if char_col < 0 or type_col < 0 or id_col < 0:
		push_error("character_unlocks.csv に char_id / unlock_type / unlock_id 列がありません")
		return
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() == 1 and row[0] == "":
			continue
		var cid: String = row[char_col] if char_col < row.size() else ""
		var utype: String = row[type_col] if type_col < row.size() else ""
		var uid: String = row[id_col] if id_col < row.size() else ""
		if cid.is_empty() or utype.is_empty() or uid.is_empty():
			continue
		if not CHAR_CLEAR_UNLOCKS.has(cid):
			CHAR_CLEAR_UNLOCKS[cid] = {"cards": [], "goods": []}
		var arr: Array = CHAR_CLEAR_UNLOCKS[cid].get(utype, [])
		if uid not in arr:
			arr.append(uid)
		CHAR_CLEAR_UNLOCKS[cid][utype] = arr


# === 実績チェック ===

func is_achievement_earned(id: String) -> bool:
	return _cfg.get_value("achievements", id, false)


# === アンロック済みカード/グッズIDリスト ===

func get_unlocked_card_ids() -> Array:
	return Array(_cfg.get_value("unlocks", "card_ids", PackedStringArray()))


func get_unlocked_goods_ids() -> Array:
	return Array(_cfg.get_value("unlocks", "goods_ids", PackedStringArray()))


# === クリア時処理。新たに解放した内容のDictionaryを返す ===

func process_clear(char_id: String, gold: int, deck_size: int) -> Dictionary:
	var new_achievements: Array = []
	var new_cards: Array = []
	var new_goods: Array = []

	# 初クリア
	if not is_achievement_earned("first_clear"):
		_earn_achievement("first_clear")
		new_achievements.append("first_clear")

	# 大富豪（300G以上）
	if gold >= 300 and not is_achievement_earned("rich_clear"):
		_earn_achievement("rich_clear")
		new_achievements.append("rich_clear")

	# 精鋭デッキ（15枚以下）
	if deck_size <= 15 and not is_achievement_earned("small_deck"):
		_earn_achievement("small_deck")
		new_achievements.append("small_deck")

	# キャラ別クリア実績
	var char_ach := char_id + "_clear"
	if ACHIEVEMENTS.has(char_ach) and not is_achievement_earned(char_ach):
		_earn_achievement(char_ach)
		new_achievements.append(char_ach)

	# キャラ別アンロック（カード・グッズ）
	if CHAR_CLEAR_UNLOCKS.has(char_id):
		var unlocks: Dictionary = CHAR_CLEAR_UNLOCKS[char_id]
		var unlocked_card_ids := get_unlocked_card_ids()
		for card_id in unlocks.get("cards", []):
			if card_id not in unlocked_card_ids:
				_unlock_card(card_id)
				new_cards.append(card_id)
		var unlocked_goods_ids := get_unlocked_goods_ids()
		for goods_id in unlocks.get("goods", []):
			if goods_id not in unlocked_goods_ids:
				_unlock_goods(goods_id)
				new_goods.append(goods_id)

	# 全キャラ制覇チェック
	if is_achievement_earned("lui_clear") and is_achievement_earned("miko_clear") \
			and is_achievement_earned("suisei_clear"):
		if not is_achievement_earned("all_chars_clear"):
			_earn_achievement("all_chars_clear")
			new_achievements.append("all_chars_clear")

	_cfg.save(UNLOCK_PATH)

	return {
		"new_achievements": new_achievements,
		"new_cards": new_cards,
		"new_goods": new_goods,
	}


# === 全実績リスト取得（達成済みフラグ付き）===

func get_all_achievements() -> Array:
	var result := []
	for id in ACHIEVEMENTS:
		var ach: Dictionary = ACHIEVEMENTS[id].duplicate()
		ach["id"] = id
		ach["earned"] = is_achievement_earned(id)
		result.append(ach)
	return result


# === 内部ヘルパー ===

func _earn_achievement(id: String) -> void:
	_cfg.set_value("achievements", id, true)


func _unlock_card(card_id: String) -> void:
	var ids := PackedStringArray(_cfg.get_value("unlocks", "card_ids", PackedStringArray()))
	if card_id not in ids:
		ids.append(card_id)
		_cfg.set_value("unlocks", "card_ids", ids)


func _unlock_goods(goods_id: String) -> void:
	var ids := PackedStringArray(_cfg.get_value("unlocks", "goods_ids", PackedStringArray()))
	if goods_id not in ids:
		ids.append(goods_id)
		_cfg.set_value("unlocks", "goods_ids", ids)
