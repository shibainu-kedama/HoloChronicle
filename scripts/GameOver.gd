extends Control

@onready var title_label: Label = $Panel/VBox/Title
@onready var label_character: Label = $Panel/VBox/Label_Character
@onready var label_stage: Label = $Panel/VBox/Label_Stage
@onready var label_deck: Label = $Panel/VBox/Label_Deck
@onready var label_gold: Label = $Panel/VBox/Label_Gold
@onready var btn_title: Button = $Panel/VBox/BtnTitle
@onready var label_stats: Label = $Panel/VBox/Label_Stats

const TITLE_SCENE_PATH := "res://scenes/TitleScene.tscn"

func _ready() -> void:
	# 敗北記録
	RunHistory.record_run("defeat")

	# 結果表示（リセット前のGlobal情報を使う）
	var char_name = ""
	if Global.selected_character:
		char_name = Global.selected_character.name
	label_character.text = "キャラクター: %s" % char_name

	var stage = _get_stage_display()
	label_stage.text = "到達ステージ: %s" % stage

	label_deck.text = "デッキ枚数: %d" % Global.player_deck.size()

	var gold = Global.player_gold if Global.player_gold >= 0 else 0
	label_gold.text = "所持ゴールド: %d" % gold

	# 累計統計
	var stats := RunHistory.get_stats()
	label_stats.text = "総プレイ回数: %d / クリア回数: %d" % [stats.total_runs, stats.total_clears]

	btn_title.pressed.connect(_on_btn_title)

	# フェードイン
	self.modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)

func _get_stage_display() -> String:
	var node_id = Global.current_node_id
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
