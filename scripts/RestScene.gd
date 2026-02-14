extends Control

@onready var label_info: Label = $VBoxContainer/Label_Info
@onready var btn_rest: Button = $VBoxContainer/Btn_Rest
@onready var btn_remove: Button = $VBoxContainer/Btn_Remove
@onready var btn_skip: Button = $VBoxContainer/Btn_Skip
@onready var card_remove_popup: Panel = $CardRemovePopup
@onready var card_list: VBoxContainer = $CardRemovePopup/VBox/ScrollContainer/CardList
@onready var btn_cancel_remove: Button = $CardRemovePopup/VBox/Btn_CancelRemove

var action_taken := false

func _ready() -> void:
	var current_hp = Global.player_hp
	var max_hp = Global.player_max_hp
	var heal_amount = _get_heal_amount()
	label_info.text = "休憩所 — HPを %d 回復できます（現在HP: %d / %d）" % [heal_amount, current_hp, max_hp]
	btn_rest.pressed.connect(_on_rest)
	btn_remove.pressed.connect(_on_remove_pressed)
	btn_skip.pressed.connect(_on_skip)
	btn_cancel_remove.pressed.connect(_on_cancel_remove)

	# デッキが1枚以下ならカード削除不可
	if Global.player_deck.size() <= 1:
		btn_remove.disabled = true

func _get_heal_amount() -> int:
	return int(Global.player_max_hp * 0.3)

func _on_rest() -> void:
	if action_taken:
		return
	action_taken = true
	btn_rest.disabled = true
	btn_remove.disabled = true
	var heal_amount = _get_heal_amount()
	var old_hp = Global.player_hp
	Global.player_hp = min(Global.player_hp + heal_amount, Global.player_max_hp)
	label_info.text = "HP を %d 回復しました！（%d → %d / %d）" % [Global.player_hp - old_hp, old_hp, Global.player_hp, Global.player_max_hp]
	await get_tree().create_timer(1.0).timeout
	_return_to_map()

func _on_remove_pressed() -> void:
	if action_taken:
		return
	_show_card_remove_popup()

func _show_card_remove_popup() -> void:
	# 既存のリストをクリア
	for child in card_list.get_children():
		child.queue_free()

	# デッキの各カードをボタンとして表示
	for i in range(Global.player_deck.size()):
		var card = Global.player_deck[i]
		var btn = Button.new()
		btn.text = "%s（%s / パワー:%d / コスト:%d）" % [card.name, card.effect, card.power, card.cost]
		btn.custom_minimum_size = Vector2(0, 35)
		btn.pressed.connect(_on_card_remove_selected.bind(i))
		card_list.add_child(btn)

	card_remove_popup.visible = true

func _on_card_remove_selected(index: int) -> void:
	if action_taken:
		return
	action_taken = true

	var removed_card = Global.player_deck[index]
	Global.player_deck.remove_at(index)
	card_remove_popup.visible = false

	btn_rest.disabled = true
	btn_remove.disabled = true
	label_info.text = "「%s」をデッキから削除しました！（残り%d枚）" % [removed_card.name, Global.player_deck.size()]
	await get_tree().create_timer(1.0).timeout
	_return_to_map()

func _on_cancel_remove() -> void:
	card_remove_popup.visible = false

func _on_skip() -> void:
	_return_to_map()

func _return_to_map() -> void:
	get_tree().change_scene_to_file("res://scenes/MapScene.tscn")
