extends Control

# 遷移先のシーンパス（自分のタイトルシーンに合わせて変えてOK）
@export var next_scene_path: String = "res://scenes/TitleScene.tscn"

# スプラッシュを表示しておく秒数
@export var wait_time: float = 2.5

var _is_changing_scene: bool = false

func _ready() -> void:
	# ここで共通フェードを利用
	FadeLayer.fade_in()
	# Timer の設定とスタート
	var timer: Timer = $Timer
	timer.wait_time = wait_time
	timer.start()

# Timer の timeout シグナルから呼ばれる
func _on_Timer_timeout() -> void:
	_go_to_next_scene()


# クリック / キー入力でスキップ
func _input(event: InputEvent) -> void:
	if _is_changing_scene:
		return

	if event is InputEventMouseButton and event.pressed:
		_go_to_next_scene()
	elif event is InputEventKey and event.pressed:
		_go_to_next_scene()


func _go_to_next_scene() -> void:
	if _is_changing_scene:
		return
	_is_changing_scene = true

	await FadeLayer.change_scene_with_fade(next_scene_path)
