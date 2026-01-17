# scripts/CardLoader.gd
extends Node

# 外部からアクセスできるようにグローバル変数にする
var all_cards: Array[CardData] = []

func _ready():
	load_cards_from_csv("res://data/cards.csv")

func load_cards_from_csv(path: String):
	all_cards.clear()

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("カードCSVが開けませんでした: " + path)
		return

	var text = file.get_as_text()
	var lines = text.split("\n", false)

	if lines.size() <= 1:
		push_warning("カードCSVにデータがありません")
		return

	var headers = lines[0].strip_edges().split(",")

	for i in range(1, lines.size()):
		var line = lines[i].strip_edges()
		if line == "":
			continue

		var cols = line.split(",", false)
		var dict := {}

		for j in range(min(headers.size(), cols.size())):
			dict[headers[j]] = cols[j]

		var card = CardData.from_dict(dict)
		all_cards.append(card)
	
	return all_cards

# ID検索用
func get_card_by_id(id: String) -> CardData:
	for card in all_cards:
		if card.id == id:
			return card
	return null
