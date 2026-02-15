extends Control

@onready var node_container = $ScrollContainer/ViewportContent/NodeContainer
@onready var path_drawer = $ScrollContainer/ViewportContent/PathDrawer
@onready var background = $ScrollContainer/ViewportContent/Background
@onready var deck_button := $StatusPanel/DeckViewButton
@onready var hp_label := $StatusPanel/HPLabel
@onready var gold_label := $StatusPanel/GoldLabel

func _ready():
	load_node_types_from_csv("res://data/map_nodes.csv")
	Global.node_links.clear()
	load_paths_from_csv("res://data/map_paths.csv")

	# ← 最初の選択可能ノード
	if Global.unlocked_nodes.is_empty():
		Global.unlocked_nodes = ["1-A", "1-B", "1-C"]  # ←最初は全部開放
	update_node_interactability()
	deck_button.pressed.connect(_on_deck_view_pressed)
	update_status_display()

func update_status_display():
	hp_label.text = "❤️ HP: %d / %d" % [Global.player_hp, Global.player_max_hp]
	gold_label.text = "💰 Gold: %d" % Global.player_gold

func _on_deck_view_pressed():
	var popup = preload("res://scenes/DeckPopup.tscn").instantiate()
	add_child(popup)
	popup.show_cards(Global.player_deck)
	popup.visibility_changed.connect(func(): if not popup.visible: popup.queue_free())

# ノード種別をCSVから読み込み、ランダムにセット
func load_node_types_from_csv(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("CSVファイル読み込み失敗: %s" % path)
		return

	file.get_csv_line() # ヘッダーを読み飛ばす

	while not file.eof_reached():
		var cols: PackedStringArray = file.get_csv_line()
		if cols.size() < 2:
			continue

		var node_id = String(cols[0]).strip_edges()
		if node_id == "":
			continue

		var chosen_type := ""
		if Global.node_types.has(node_id):
			chosen_type = String(Global.node_types[node_id])

		var type_candidates: Array[String] = []
		for raw_type in cols.slice(1, cols.size()):
			var t = String(raw_type).strip_edges().to_lower()
			if t != "":
				type_candidates.append(t)

		if chosen_type == "":
			if type_candidates.is_empty():
				continue
			# shop 候補を含むノードは shop を優先
			chosen_type = "shop" if type_candidates.has("shop") else type_candidates[randi() % type_candidates.size()]
			Global.node_types[node_id] = chosen_type

		var map_node = node_container.get_node_or_null(node_id)
		if map_node and map_node.has_method("set_type"):
			map_node.set_type(chosen_type)
		else:
			print("ノードID %s が存在しないか set_type が未定義です" % node_id)

# ノード接続をCSVから読み込み、線でつなぐ
func load_paths_from_csv(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("CSVファイル読み込み失敗: %s" % path)
		return

	file.get_line()  # ヘッダーを読み飛ばす

	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line == "":
			continue

		var cols = line.split(",")
		if cols.size() < 2:
			continue

		var from_id = cols[0]
		var to_id = cols[1]
		
		# 接続情報を保存
		# Global.node_links をセット
		if not Global.node_links.has(from_id):
			Global.node_links[from_id] = []
		Global.node_links[from_id].append(to_id)

		# 線を引く
		var from_node = node_container.get_node_or_null(from_id)
		var to_node = node_container.get_node_or_null(to_id)

		if from_node and to_node:
			draw_line_between_nodes(from_node, to_node)
		else:
			print("ノードが見つかりません: %s → %s" % [from_id, to_id])

# 2つのノードの中心位置を線でつなぐ
func draw_line_between_nodes(node_a: Control, node_b: Control) -> void:
	var start_pos = node_a.global_position + node_a.size * 0.5
	var end_pos = node_b.global_position + node_b.size * 0.5

	var line = Line2D.new()
	line.width = 4
	line.default_color = Color.WHITE
	line.add_point(start_pos)
	line.add_point(end_pos)

	path_drawer.add_child(line)

func update_node_interactability():
	print("UI更新中:", Global.unlocked_nodes)
	for node in node_container.get_children():
		if node is Button:
			var node_name = node.name
			var is_unlocked = Global.is_node_unlocked(node_name)
			var is_passed = Global.passed_nodes.has(node_name)

			# 押せるかどうかを制御
			node.disabled = not is_unlocked or is_passed

			# 通過済みはグレー表示
			if node.has_method("set_passed_visual"):
				node.set_passed_visual(is_passed)

			# 🔸注目アニメーションの再生：次に進めるノードのみ
			if is_unlocked and not is_passed:
				if node.has_method("play_attention_animation"):
					node.play_attention_animation()
