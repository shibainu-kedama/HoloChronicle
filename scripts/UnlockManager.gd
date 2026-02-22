extends Node

const UNLOCK_PATH := "user://unlocks.cfg"

# 実績定義（ID → 表示名・説明）
const ACHIEVEMENTS: Dictionary = {
	"first_clear": {
		"name": "初クリア",
		"desc": "初めてゲームをクリアした"
	},
	"lui_clear": {
		"name": "鷹の覇道",
		"desc": "Luiでゲームをクリアした"
	},
	"miko_clear": {
		"name": "巫女の神通力",
		"desc": "Mikoでゲームをクリアした"
	},
	"suisei_clear": {
		"name": "彗星の軌跡",
		"desc": "Suiseiでゲームをクリアした"
	},
	"all_chars_clear": {
		"name": "全員制覇",
		"desc": "全キャラクターでゲームをクリアした"
	},
	"rich_clear": {
		"name": "大富豪",
		"desc": "300ゴールド以上で勝利した"
	},
	"small_deck": {
		"name": "精鋭デッキ",
		"desc": "デッキ15枚以下でクリアした"
	},
}

# キャラクターIDごとのクリアアンロック（カードID・グッズID）
const CHAR_CLEAR_UNLOCKS: Dictionary = {
	"lui": {
		"cards": ["lui_kessen"],
		"goods": ["lui_talon"],
	},
	"miko": {
		"cards": ["miko_oracle"],
		"goods": ["miko_purification"],
	},
	"suisei": {
		"cards": ["suisei_orbit"],
		"goods": ["suisei_comet_core"],
	},
}

var _cfg: ConfigFile


func _ready() -> void:
	_cfg = ConfigFile.new()
	_cfg.load(UNLOCK_PATH)


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
