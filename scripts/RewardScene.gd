extends Control

var card_buttons = []
var reward_cards: Array[CardData] = []

func _ready():
	# HBoxContainer 内の CardButton ノードを自動収集（名前が "CardButton" で始まるノードのみ）
	var container = $VBoxContainer/HBoxContainer
	if container == null:
		print("HBoxContainer が見つかりません。ノード名やシーン構造を確認してください。")
		return

	for child in container.get_children():
		if child.name.begins_with("CardButton"):
			card_buttons.append(child)

	# null チェック（トラブル時用）
	if card_buttons.size() < 3:
		print("カードボタンが3つ未満です。シーン構成を確認してください。")
		return

	# スキップボタン接続
	var skip_btn = $VBoxContainer/Btn_Skip
	if skip_btn:
		skip_btn.pressed.connect(_on_skip_pressed)

	# すでにロード済みのカードからランダムに最大3枚抽選
	var offer_count = min(3, CardLoader.all_cards.size(), card_buttons.size())
	reward_cards = pick_random_cards(CardLoader.all_cards, offer_count)
	show_reward_cards(offer_count)

func show_reward_cards(count: int):
	for i in range(count):
		var btn = card_buttons[i]
		if btn == null:
			push_error("card_buttons[%d] が null です。" % i)
			continue

		var data = reward_cards[i]
		print("【show_reward_cards】%s / %s / %s / %s / %s / %s" % [data.name, data.effect, str(data.power), str(data.cost), data.info, data.image_path])

		# UI更新
		btn.update_card_display(data)
		# カードが押された時の処理を接続
		btn.connect("use_card", Callable(self, "_on_card_selected"))

func _on_card_selected(btn: TextureButton):
	var index = card_buttons.find(btn)
	if index == -1:
		push_error("選択されたボタンが card_buttons に見つかりません")
		return
	
	var selected_card = reward_cards[index]
	print("選択されたカード: ", selected_card.name)

	# プレイヤーデッキに追加（グローバル変数などに保存）
	Global.player_deck.append(selected_card)

	# 次のシーンへ遷移（マップ画面など）
	get_tree().change_scene_to_file("res://scenes/MapScene.tscn")

func _on_skip_pressed():
	get_tree().change_scene_to_file("res://scenes/MapScene.tscn")

# ユーティリティ：ランダムにN枚選ぶ
func pick_random_cards(array: Array, count: int) -> Array:
	var shuffled = array.duplicate()
	shuffled.shuffle()
	return shuffled.slice(0, count)
