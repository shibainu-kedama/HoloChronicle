extends Control

@onready var start_button: Button = $StartButton
@onready var quit_button: Button = $QuitButton

func _ready() -> void:
	# フェードイン
	FadeLayer.fade_in()
	
	start_button.pressed.connect(_on_start_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed() -> void:
	print("ゲーム開始")
	# フェード付きでシーン遷移
	await FadeLayer.change_scene_with_fade("res://scenes/CharacterSelectScene.tscn")
	# get_tree().change_scene_to_file("res://scenes/CharacterSelectScene.tscn")

func _on_quit_button_pressed() -> void:
	print("ゲーム終了")
	get_tree().quit()
