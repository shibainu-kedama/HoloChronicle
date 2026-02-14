# scripts/EventLoader.gd
extends Node

const EventData = preload("res://scripts/EventData.gd")

static func load_events(path: String) -> Array:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("CSV読み込み失敗: " + path)
		return []
	var lines = file.get_as_text().split("\n", false)
	var events: Array = []
	for i in range(1, lines.size()):
		var line = lines[i].strip_edges()
		if line == "":
			continue
		var row = line.split(",", false)
		var ev = EventData.from_csv_row(row)
		events.append(ev)
	return events
