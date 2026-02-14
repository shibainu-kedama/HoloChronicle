extends Control

@onready var label_info: Label = $VBoxContainer/Label_Info
@onready var btn_rest: Button = $VBoxContainer/Btn_Rest
@onready var btn_skip: Button = $VBoxContainer/Btn_Skip

var heal_amount: int = 20
var healed := false

func _ready() -> void:
	var max_hp = 100
	if Global.selected_character:
		max_hp = Global.selected_character.hp
	label_info.text = "休憩所 — HPを %d 回復できます（現在HP不明）" % heal_amount
	btn_rest.pressed.connect(_on_rest)
	btn_skip.pressed.connect(_on_skip)

func _on_rest() -> void:
	if healed:
		return
	healed = true
	btn_rest.disabled = true
	label_info.text = "HP を %d 回復しました！" % heal_amount
	# HP回復はバトルシーン側で参照する仕組みが必要
	# 現時点では表示のみ（TODO: Globalにplayer_hpを持たせて反映）
	await get_tree().create_timer(1.0).timeout
	_return_to_map()

func _on_skip() -> void:
	_return_to_map()

func _return_to_map() -> void:
	get_tree().change_scene_to_file("res://scenes/MapScene.tscn")
