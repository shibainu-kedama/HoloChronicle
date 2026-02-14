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
	Global.reset_run_state()
	get_tree().change_scene_to_file(TITLE_SCENE_PATH)

func _save_clear_flag() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://save.cfg") # 既存でも新規でもOK
	cfg.set_value("progress", "cleared_once", true)
	cfg.save("user://save.cfg")
