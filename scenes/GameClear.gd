extends Control

@onready var btn_title: Button = $Panel/VBox/BtnTitle
@onready var title_label: Label = $Panel/VBox/Title
@onready var sub_label: Label = $Panel/VBox/Sub

const TITLE_SCENE_PATH := "res://scenes/TitleScene.tscn"

func _ready() -> void:
	title_label.text = "GAME CLEAR!"
	sub_label.text = "おめでとうございます！"

	# クリアフラグ保存（任意）
	_save_clear_flag()

	# ボタン
	btn_title.text = "タイトルへ戻る"
	btn_title.pressed.connect(_on_btn_title)

	# 軽いフェードイン（任意）
	self.modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)

func _on_btn_title() -> void:
	_reset_run_state()
	get_tree().change_scene_to_file(TITLE_SCENE_PATH)

func _save_clear_flag() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://save.cfg") # 既存でも新規でもOK
	cfg.set_value("progress", "cleared_once", true)
	cfg.save("user://save.cfg")

# 1ラン終了後の状態初期化（タイトルに戻る前提）
func _reset_run_state() -> void:
	# マップ進行系
	Global.passed_nodes.clear()
	Global.unlocked_nodes.clear()
	Global.current_node_id = ""
	Global.last_battle_reward_candidates.clear()

	# デッキ/キャラ選択
	Global.player_deck.clear()
	Global.selected_character = {}

	# ステージ種別を使っている場合（あれば安全に初期化）
	if "StageType" in Global and "current_stage_type" in Global:
		Global.current_stage_type = Global.StageType.BATTLE

	# ラン統計などを使っている場合（存在チェックで安全に）
	if "run_stats" in Global:
		Global.run_stats = {}
