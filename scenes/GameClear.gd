extends Control

@onready var btn_title: Button = $Panel/VBox/BtnTitle
@onready var title_label: Label = $Panel/VBox/Title
@onready var sub_label: Label = $Panel/VBox/Sub
@onready var label_character: Label = $Panel/VBox/Label_Character
@onready var label_stage: Label = $Panel/VBox/Label_Stage
@onready var label_deck: Label = $Panel/VBox/Label_Deck
@onready var label_gold: Label = $Panel/VBox/Label_Gold
@onready var label_stats: Label = $Panel/VBox/Label_Stats

const TITLE_SCENE_PATH := "res://scenes/TitleScene.tscn"

func _ready() -> void:
	title_label.text = "GAME CLEAR!"
	sub_label.text = "おめでとうございます！"

	# クリア記録
	RunHistory.record_run("clear")

	# 結果詳細表示
	var char_name := ""
	var char_id := ""
	if Global.selected_character:
		char_name = Global.selected_character.name
		char_id = Global.selected_character.id
	label_character.text = "キャラクター: %s" % char_name
	label_stage.text = "到達ステージ: %s" % _get_stage_display()
	var deck_size := Global.player_deck.size()
	label_deck.text = "デッキ枚数: %d" % deck_size
	var gold: int = Global.player_gold if Global.player_gold >= 0 else 0
	label_gold.text = "所持ゴールド: %d" % gold

	# 累計統計
	var stats := RunHistory.get_stats()
	label_stats.text = "総プレイ回数: %d / クリア回数: %d" % [stats.total_runs, stats.total_clears]

	# === アンロック・実績処理 ===
	var unlock_result := UnlockManager.process_clear(char_id, gold, deck_size)
	_show_unlock_results(unlock_result)

	# ボタン
	btn_title.text = "タイトルへ戻る"
	btn_title.pressed.connect(_on_btn_title)

	# 実績ボタン追加
	var btn_ach := Button.new()
	btn_ach.text = "実績を見る"
	btn_ach.pressed.connect(_on_btn_achievements)
	$Panel/VBox.add_child(btn_ach)

	# フェードイン
	self.modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)


func _show_unlock_results(result: Dictionary) -> void:
	var vbox := $Panel/VBox
	var new_achievements: Array = result.get("new_achievements", [])
	var new_cards: Array = result.get("new_cards", [])
	var new_goods: Array = result.get("new_goods", [])

	if new_achievements.is_empty() and new_cards.is_empty() and new_goods.is_empty():
		return

	# セパレーター
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# 新実績
	for ach_id in new_achievements:
		var ach_info: Dictionary = UnlockManager.ACHIEVEMENTS.get(ach_id, {})
		var lbl := Label.new()
		lbl.text = "★ 実績解除：%s — %s" % [ach_info.get("name", ach_id), ach_info.get("desc", "")]
		lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl)

	# 新カード
	for card_id in new_cards:
		var card := CardLoader.get_card_by_id(card_id)
		var card_name: String = card.name if card else card_id
		var lbl := Label.new()
		lbl.text = "NEW カード解放：%s" % card_name
		lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl)

	# 新グッズ
	for goods_id in new_goods:
		var goods := CardLoader.get_goods_by_id(goods_id)
		var goods_name: String = goods.name if goods else goods_id
		var lbl := Label.new()
		lbl.text = "NEW グッズ解放：%s" % goods_name
		lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl)


func _on_btn_achievements() -> void:
	_show_achievement_popup()


func _show_achievement_popup() -> void:
	# 既存のポップアップがあれば削除
	var existing := get_node_or_null("AchievementPopup")
	if existing:
		existing.queue_free()

	var popup := PopupPanel.new()
	popup.name = "AchievementPopup"
	popup.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
	popup.size = Vector2i(480, 400)
	add_child(popup)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	popup.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "実績一覧"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	for ach in UnlockManager.get_all_achievements():
		var lbl := Label.new()
		if ach.earned:
			lbl.text = "★ %s — %s" % [ach.name, ach.desc]
			lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		else:
			lbl.text = "  %s — %s" % [ach.name, ach.desc]
			lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(lbl)

	var btn_close := Button.new()
	btn_close.text = "閉じる"
	btn_close.pressed.connect(func(): popup.hide())
	vbox.add_child(btn_close)

	popup.popup_centered()


func _get_stage_display() -> String:
	var node_id := Global.current_node_id
	if node_id == "":
		return "1"
	var num_str := ""
	for i in range(node_id.length()):
		if node_id[i].is_valid_int():
			num_str += node_id[i]
		else:
			break
	if num_str != "":
		return num_str
	return "1"


func _on_btn_title() -> void:
	Global.reset_run_state()
	get_tree().change_scene_to_file(TITLE_SCENE_PATH)
