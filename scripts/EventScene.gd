# scripts/EventScene.gd
extends Control

@onready var label_title = $VBoxContainer/Title
@onready var event_image = $VBoxContainer/HBoxContainer/Image
@onready var label_body = $VBoxContainer/HBoxContainer/VBoxContainer/Body
@onready var choice_container = $VBoxContainer/HBoxContainer/VBoxContainer/Choices

var events = []
var current_event: EventData
var player_stats: Dictionary = {}

const ConditionEvaluator = preload("res://scripts/ConditionEvaluator.gd")
const EventLoader = preload("res://scripts/EventLoader.gd")

func _ready():
	# Globalのキャラデータからステータスを初期化
	var ch = Global.selected_character
	if ch:
		player_stats = {
			"hp": Global.player_hp if Global.player_hp > 0 else ch.hp,
			"gold": Global.player_gold if Global.player_gold >= 0 else ch.gold,
			"atk": Global.player_atk_bonus
		}
	else:
		player_stats = {"hp": 100, "gold": 50, "atk": 0}

	events = EventLoader.load_events("res://data/event_data.csv")
	if events.is_empty():
		push_error("イベントデータが空です")
		return_to_map()
		return
	show_event(events[0])

func show_event(ev: EventData):
	print("▶ イベントID:", ev.id, ev.title)
	print("▶ choices:", ev.choices)
	
	current_event = ev
	label_title.text = ev.title
	label_body.text = ev.body
	if ev.image_path != "" and ResourceLoader.exists(ev.image_path):
		event_image.texture = load(ev.image_path)
	else:
		event_image.texture = null
		push_warning("[EventScene] 画像が見つかりません: %s" % ev.image_path)

	# ボタン生成
	for child in choice_container.get_children():
		child.queue_free()
	
	for choice in ev.choices:
		print("  - 選択肢:", choice.text, "next:", choice.next_event_id)
		if choice.text.strip_edges() == "":
			continue
		var btn = Button.new()
		btn.text = choice.text
		btn.pressed.connect(func():
			apply_result_and_continue(choice)
		)
		choice_container.add_child(btn)

func apply_result_and_continue(choice: Dictionary):
	# 結果適用
	for key in choice.result.keys():
		player_stats[key] += choice.result[key]
		print("player", key, "→", player_stats[key])
	_sync_stats_to_global()

	var next_id = null
	if choice.next_event_id == "MAP":
		return_to_map()
		return

	var condition = choice.condition
	if choice.next_event_id.find(",") >= 0 and condition != "":
		var ids = choice.next_event_id.split(",")
		next_id = int(ids[0]) if ConditionEvaluator.evaluate(condition, player_stats) else int(ids[1])
	elif choice.next_event_id != "":
		next_id = int(choice.next_event_id)

	if next_id != null:
		var filtered = events.filter(func(e): return e.id == next_id)
		if filtered.is_empty():
			push_error("イベントID %d が見つかりません" % next_id)
			return_to_map()
			return
		show_event(filtered[0])

func return_to_map():
	print("マップに戻ります")
	get_tree().change_scene_to_file("res://scenes/MapScene.tscn")

func _sync_stats_to_global() -> void:
	var max_hp = max(Global.player_max_hp, 1)
	Global.player_hp = clamp(int(player_stats.get("hp", Global.player_hp)), 0, max_hp)
	Global.player_gold = max(int(player_stats.get("gold", Global.player_gold)), 0)
	Global.player_atk_bonus = max(int(player_stats.get("atk", 0)), 0)
