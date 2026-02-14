# scripts/EventLoader.gd
extends Node

const EventData = preload("res://scripts/EventData.gd")

static func load_events(path: String) -> Array[EventData]:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("CSV読み込み失敗: " + path)
		return []
	if file.eof_reached():
		return []

	var _headers: PackedStringArray = file.get_csv_line()
	var events: Array[EventData] = []
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() == 1 and row[0] == "":
			continue
		var ev = EventData.from_csv_row(row)
		events.append(ev)
	return events
