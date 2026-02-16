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

	# クリアフラグ保存（任意）
	_save_clear_flag()

	# クリア記録
	RunHistory.record_run("clear")

	# 結果詳細表示
	var char_name := ""
	if Global.selected_character:
		char_name = Global.selected_character.name
	label_character.text = "キャラクター: %s" % char_name
	label_stage.text = "到達ステージ: %s" % _get_stage_display()
	label_deck.text = "デッキ枚数: %d" % Global.player_deck.size()
	var gold: int = Global.player_gold if Global.player_gold >= 0 else 0
	label_gold.text = "所持ゴールド: %d" % gold

	# 累計統計
	var stats := RunHistory.get_stats()
	label_stats.text = "総プレイ回数: %d / クリア回数: %d" % [stats.total_runs, stats.total_clears]

	# ボタン
	btn_title.text = "タイトルへ戻る"
	btn_title.pressed.connect(_on_btn_title)

	# 軽いフェードイン（任意）
	self.modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)

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

func _save_clear_flag() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://save.cfg") # 既存でも新規でもOK
	cfg.set_value("progress", "cleared_once", true)
	cfg.save("user://save.cfg")
