# scripts/CardLoader.gd
extends Node

# 外部からアクセスできるようにグローバル変数にする
var all_cards: Array[CardData] = []
var all_goods: Array[GoodsData] = []
var all_potions: Array[PotionData] = []

# CSVから読み込む説明・設定
var effect_descriptions: Dictionary = {}
var status_descriptions: Dictionary = {}
var shop_config: Dictionary = {}

func _ready():
	load_cards_from_csv("res://data/cards.csv")
	load_goods_from_csv("res://data/goods.csv")
	load_potions_from_csv("res://data/potions.csv")
	_load_effect_descriptions("res://data/effect_descriptions.csv")
	_load_status_descriptions("res://data/status_descriptions.csv")
	_load_shop_config("res://data/shop_config.csv")

func load_cards_from_csv(path: String):
	all_cards.clear()

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("カードCSVが開けませんでした: " + path)
		return
	if file.eof_reached():
		push_warning("カードCSVにデータがありません")
		return

	var headers: PackedStringArray = file.get_csv_line()
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() == 1 and row[0] == "":
			continue
		var dict := {}
		var count: int = min(headers.size(), row.size())
		for i in range(count):
			dict[headers[i]] = row[i]
		var card = CardData.from_dict(dict)
		all_cards.append(card)
	
	return all_cards

# アンロック済みカードのみ返す（unlock_keyが空 or 実績取得済み）
func get_available_cards() -> Array[CardData]:
	return all_cards.filter(func(c: CardData) -> bool:
		return c.unlock_key == "" or UnlockManager.is_achievement_earned(c.unlock_key)
	)

# ID検索用
func get_card_by_id(id: String) -> CardData:
	for card in all_cards:
		if card.id == id:
			return card
	push_error("カードID '%s' が見つかりません" % id)
	return null

# === グッズ読み込み ===
func load_goods_from_csv(path: String):
	all_goods.clear()

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("グッズCSVが開けませんでした: " + path)
		return
	if file.eof_reached():
		push_warning("グッズCSVにデータがありません")
		return

	var headers: PackedStringArray = file.get_csv_line()
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() == 1 and row[0] == "":
			continue
		var dict := {}
		var count: int = min(headers.size(), row.size())
		for i in range(count):
			dict[headers[i]] = row[i]
		var goods = GoodsData.from_dict(dict)
		all_goods.append(goods)

# アンロック済みグッズのみ返す
func get_available_goods() -> Array[GoodsData]:
	return all_goods.filter(func(g: GoodsData) -> bool:
		return g.unlock_key == "" or UnlockManager.is_achievement_earned(g.unlock_key)
	)

func get_goods_by_id(id: String) -> GoodsData:
	for goods in all_goods:
		if goods.id == id:
			return goods
	push_error("グッズID '%s' が見つかりません" % id)
	return null

# === ポーション読み込み ===
func load_potions_from_csv(path: String):
	all_potions.clear()

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ポーションCSVが開けませんでした: " + path)
		return
	if file.eof_reached():
		push_warning("ポーションCSVにデータがありません")
		return

	var headers: PackedStringArray = file.get_csv_line()
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() == 1 and row[0] == "":
			continue
		var dict := {}
		var count: int = min(headers.size(), row.size())
		for i in range(count):
			dict[headers[i]] = row[i]
		var potion = PotionData.from_dict(dict)
		all_potions.append(potion)

func get_potion_by_id(id: String) -> PotionData:
	for potion in all_potions:
		if potion.id == id:
			return potion
	push_error("ポーションID '%s' が見つかりません" % id)
	return null

# === 効果・ステータス説明（CSV）===
func _load_effect_descriptions(path: String) -> void:
	effect_descriptions.clear()
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("効果説明CSVが開けませんでした: " + path)
		return
	var headers: PackedStringArray = file.get_csv_line()
	var id_col: int = headers.find("id")
	var desc_col: int = headers.find("description")
	if id_col < 0 or desc_col < 0:
		push_error("effect_descriptions.csv に id / description 列がありません")
		return
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() == 1 and row[0] == "":
			continue
		var eid: String = row[id_col] if id_col < row.size() else ""
		if eid.is_empty():
			continue
		effect_descriptions[eid] = row[desc_col] if desc_col < row.size() else ""
	return

func _load_status_descriptions(path: String) -> void:
	status_descriptions.clear()
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ステータス説明CSVが開けませんでした: " + path)
		return
	var headers: PackedStringArray = file.get_csv_line()
	var id_col: int = headers.find("id")
	var desc_col: int = headers.find("description")
	if id_col < 0 or desc_col < 0:
		push_error("status_descriptions.csv に id / description 列がありません")
		return
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() == 1 and row[0] == "":
			continue
		var sid: String = row[id_col] if id_col < row.size() else ""
		if sid.is_empty():
			continue
		status_descriptions[sid] = row[desc_col] if desc_col < row.size() else ""
	return

func get_effect_description(effect_id: String) -> String:
	return effect_descriptions.get(effect_id, "")

func get_status_description(status_id: String) -> String:
	return status_descriptions.get(status_id, "")

# === ショップ設定（CSV）===
func _load_shop_config(path: String) -> void:
	shop_config.clear()
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ショップ設定CSVが開けませんでした: " + path)
		return
	var headers: PackedStringArray = file.get_csv_line()
	var key_col: int = headers.find("key")
	var val_col: int = headers.find("value")
	if key_col < 0 or val_col < 0:
		push_error("shop_config.csv に key / value 列がありません")
		return
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() == 1 and row[0] == "":
			continue
		var k: String = row[key_col] if key_col < row.size() else ""
		if k.is_empty():
			continue
		var v: String = row[val_col] if val_col < row.size() else ""
		shop_config[k] = int(v) if v.is_valid_int() else v
	return

func get_card_price(cost: int) -> int:
	var key: String = "cost_%d" % cost
	return int(shop_config.get(key, 50))

func get_upgrade_cost() -> int:
	return int(shop_config.get("upgrade_cost", 75))

func get_goods_price() -> int:
	return int(shop_config.get("goods_price", 100))
