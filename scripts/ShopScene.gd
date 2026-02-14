extends Control

const CARD_PRICES = {0: 30, 1: 50, 2: 75}

@onready var gold_label: Label = $VBoxContainer/Label_Gold
@onready var btn_leave: Button = $VBoxContainer/Btn_Leave

var shop_cards: Array[CardData] = []
var card_nodes: Array = []
var buy_buttons: Array[Button] = []

func _ready() -> void:
	# カード表示ノード取得
	var card_container = $VBoxContainer/HBoxCards
	for child in card_container.get_children():
		card_nodes.append(child)

	# 購入ボタン取得
	var buy_container = $VBoxContainer/HBoxBuy
	for child in buy_container.get_children():
		if child is Button:
			buy_buttons.append(child)

	# ランダムに3枚抽選
	shop_cards = _pick_shop_cards(3)
	_setup_card_display()
	_update_gold_label()

	btn_leave.pressed.connect(_on_leave)

func _pick_shop_cards(count: int) -> Array[CardData]:
	var all = CardLoader.all_cards.duplicate()
	all.shuffle()
	var result: Array[CardData] = []
	for i in range(min(count, all.size())):
		result.append(all[i])
	return result

func _setup_card_display() -> void:
	for i in range(min(shop_cards.size(), card_nodes.size())):
		var card = shop_cards[i]
		var node = card_nodes[i]
		node.update_card_display(card)

		var price = _get_price(card)
		if i < buy_buttons.size():
			buy_buttons[i].text = "購入 (%dG)" % price
			buy_buttons[i].pressed.connect(_on_buy.bind(i))
			if Global.player_gold < price:
				buy_buttons[i].disabled = true

func _get_price(card: CardData) -> int:
	return CARD_PRICES.get(card.cost, 50)

func _on_buy(index: int) -> void:
	if index >= shop_cards.size():
		return
	var card = shop_cards[index]
	var price = _get_price(card)
	if Global.player_gold < price:
		return

	Global.player_gold -= price
	Global.player_deck.append(card)

	buy_buttons[index].disabled = true
	buy_buttons[index].text = "売り切れ"

	_update_gold_label()
	_update_buy_buttons()

func _update_gold_label() -> void:
	gold_label.text = "所持ゴールド: %d" % Global.player_gold

func _update_buy_buttons() -> void:
	for i in range(min(shop_cards.size(), buy_buttons.size())):
		if buy_buttons[i].text == "売り切れ":
			continue
		var price = _get_price(shop_cards[i])
		buy_buttons[i].disabled = Global.player_gold < price

func _on_leave() -> void:
	get_tree().change_scene_to_file("res://scenes/MapScene.tscn")
