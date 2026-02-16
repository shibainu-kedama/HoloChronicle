# scripts/CardLoader.gd
extends Node

# 外部からアクセスできるようにグローバル変数にする
var all_cards: Array[CardData] = []
var all_goods: Array[GoodsData] = []
var all_potions: Array[PotionData] = []

func _ready():
	load_cards_from_csv("res://data/cards.csv")
	load_goods_from_csv("res://data/goods.csv")
	load_potions_from_csv("res://data/potions.csv")

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
