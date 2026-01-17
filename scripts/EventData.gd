# scripts/EventData.gd
class_name EventData

var id: int
var title: String
var image_path: String
var body: String
var choices: Array = [] # [{text, result, next_event_id, condition}]

static func parse_result(text: String) -> Dictionary:
	var result = {}
	for part in text.split(";"):
		var kv = part.strip_edges().split(":")
		if kv.size() == 2:
			result[kv[0]] = int(kv[1])
	return result

static func from_csv_row(row: PackedStringArray) -> EventData:
	var ev = EventData.new()
	ev.id = int(row[0])
	ev.title = row[1]
	ev.image_path = row[2]
	ev.body = row[3]

	var i = 4
	while i + 3 < row.size():
		var text = row[i].strip_edges()
		if text != "":
			ev.choices.append({
				"text": text,
				"result": parse_result(row[i+1]),
				"next_event_id": row[i+2].strip_edges(),
				"condition": row[i+3].strip_edges()
			})
		i += 4
	return ev
