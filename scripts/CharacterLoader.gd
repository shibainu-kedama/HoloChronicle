# CharacterLoader.gd
extends Node
class_name CharacterLoader

static func load_characters(csv_path: String = "res://data/characters.csv") -> Array[CharacterData]:
	var result: Array[CharacterData] = []

	var file := FileAccess.open(csv_path, FileAccess.READ)
	if file == null:
		push_error("[CharacterLoader] CSVが開けません: %s" % csv_path)
		return result

	if file.eof_reached():
		push_error("[CharacterLoader] 空のCSVです: %s" % csv_path)
		return result

	# 1行目をヘッダーとして取得
	var headers: PackedStringArray = file.get_csv_line()
	var required: PackedStringArray = [
		"id", "name", "description", "hp", "gold",
		"talent_name", "talent_desc", "talent_icon_path", "image_path"
	]
	for col in required:
		if not headers.has(col):
			push_error("[CharacterLoader] 必須列が見つかりません: %s" % col)

	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() == 1 and row[0] == "": # 空行スキップ
			continue

		var d: Dictionary = {}
		var count: int = min(headers.size(), row.size())
		for i in range(count):
			d[headers[i]] = row[i]

		# 数値に変換
		d.hp = int(d.get("hp", "0"))
		d.gold = int(d.get("gold", "0"))

		# id のバリデーション
		if not d.has("id") or String(d.id).is_empty():
			push_error("[CharacterLoader] id が空です。行をスキップしました。")
			continue

		# Dictionary → CharacterData に変換
		var ch: CharacterData = CharacterData.from_dict(d)
		result.append(ch)

	file.close()
	return result


static func get_by_id(id: String, list: Array[CharacterData]) -> CharacterData:
	for ch in list:
		if ch.id == id:
			return ch

	push_warning("[CharacterLoader] get_by_id: 見つかりません: %s" % id)
	return CharacterData.new()
