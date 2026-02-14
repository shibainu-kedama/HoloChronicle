extends Control

const CARD_PRICES = {0: 30, 1: 50, 2: 75}
const UPGRADE_COST = 75

@onready var gold_label: Label = $VBoxContainer/Label_Gold
@onready var btn_upgrade: Button = $VBoxContainer/Btn_Upgrade
@onready var btn_leave: Button = $VBoxContainer/Btn_Leave
@onready var upgrade_popup: Panel = $UpgradePopup
@onready var upgrade_card_list: VBoxContainer = $UpgradePopup/VBox/ScrollContainer/CardList
@onready var btn_cancel_upgrade: Button = $UpgradePopup/VBox/Btn_CancelUpgrade

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
	_update_upgrade_button()

	btn_upgrade.pressed.connect(_on_upgrade_pressed)
	btn_leave.pressed.connect(_on_leave)
	btn_cancel_upgrade.pressed.connect(_on_cancel_upgrade)

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
	_update_upgrade_button()

func _update_gold_label() -> void:
	gold_label.text = "所持ゴールド: %d" % Global.player_gold

func _update_buy_buttons() -> void:
	for i in range(min(shop_cards.size(), buy_buttons.size())):
		if buy_buttons[i].text == "売り切れ":
			continue
		var price = _get_price(shop_cards[i])
		buy_buttons[i].disabled = Global.player_gold < price

# === カード強化 ===

func _update_upgrade_button() -> void:
	var has_upgradable = _has_upgradable_cards()
	btn_upgrade.disabled = Global.player_gold < UPGRADE_COST or not has_upgradable
	btn_upgrade.text = "カード強化（%dG）" % UPGRADE_COST

func _has_upgradable_cards() -> bool:
	for card in Global.player_deck:
		if not card.upgraded:
			return true
	return false

func _on_upgrade_pressed() -> void:
	if Global.player_gold < UPGRADE_COST:
		return
	_show_upgrade_popup()

func _show_upgrade_popup() -> void:
	for child in upgrade_card_list.get_children():
		child.queue_free()

	for i in range(Global.player_deck.size()):
		var card = Global.player_deck[i]
		var btn = Button.new()
		if card.upgraded:
			btn.text = "%s（強化済み）" % card.name
			btn.disabled = true
		else:
			var preview_power = card.power
			match card.effect:
				"attack", "self_attack", "multi_attack", "block", "heal":
					preview_power += 3
				"energy", "draw", "energy_burst":
					preview_power += 1
			btn.text = "%s（%s / パワー:%d → %d / コスト:%d）" % [card.name, card.effect, card.power, preview_power, card.cost]
		btn.custom_minimum_size = Vector2(0, 35)
		btn.pressed.connect(_on_upgrade_card_selected.bind(i))
		upgrade_card_list.add_child(btn)

	upgrade_popup.visible = true

func _on_upgrade_card_selected(index: int) -> void:
	var card = Global.player_deck[index]
	if card.upgraded or Global.player_gold < UPGRADE_COST:
		return

	Global.player_gold -= UPGRADE_COST
	card.upgrade()

	upgrade_popup.visible = false
	_update_gold_label()
	_update_buy_buttons()
	_update_upgrade_button()

func _on_cancel_upgrade() -> void:
	upgrade_popup.visible = false

func _on_leave() -> void:
	get_tree().change_scene_to_file("res://scenes/MapScene.tscn")
