extends Node

func load_starting_deck(character_id: String) -> Array[CardData]:
	var deck: Array[CardData] = []  # ← 型を明示
	var file = FileAccess.open("res://data/starting_decks.csv", FileAccess.READ)
	if not file:
		push_error("starting_decks.csv が開けませんでした")
		return deck
	
	file.get_line()  # ヘッダーをスキップ
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line == "":
			continue
		var parts = line.split(",")
		if parts.size() < 2:
			continue
		if parts[0] == character_id:
			var card_id = parts[1]
			var card = CardLoader.get_card_by_id(card_id)
			if card:
				deck.append(card)
	return deck
