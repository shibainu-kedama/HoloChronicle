extends Control

@onready var label_info: Label = $VBoxContainer/Label_Info
@onready var btn_rest: Button = $VBoxContainer/Btn_Rest
@onready var btn_skip: Button = $VBoxContainer/Btn_Skip

var healed := false

func _ready() -> void:
	var current_hp = Global.player_hp
	var max_hp = Global.player_max_hp
	var heal_amount = _get_heal_amount()
	label_info.text = "休憩所 — HPを %d 回復できます（現在HP: %d / %d）" % [heal_amount, current_hp, max_hp]
	btn_rest.pressed.connect(_on_rest)
	btn_skip.pressed.connect(_on_skip)

func _get_heal_amount() -> int:
	return int(Global.player_max_hp * 0.3)

func _on_rest() -> void:
	if healed:
		return
	healed = true
	btn_rest.disabled = true
	var heal_amount = _get_heal_amount()
	var old_hp = Global.player_hp
	Global.player_hp = min(Global.player_hp + heal_amount, Global.player_max_hp)
	label_info.text = "HP を %d 回復しました！（%d → %d / %d）" % [Global.player_hp - old_hp, old_hp, Global.player_hp, Global.player_max_hp]
	await get_tree().create_timer(1.0).timeout
	_return_to_map()

func _on_skip() -> void:
	_return_to_map()

func _return_to_map() -> void:
	get_tree().change_scene_to_file("res://scenes/MapScene.tscn")
