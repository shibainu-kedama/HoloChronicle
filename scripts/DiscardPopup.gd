extends Panel

var card_list: FlowContainer
var CardSlotScene := preload("res://scenes/CardSlot.tscn")

func _ready():
	card_list = get_node("ScrollContainer/CardList")
	if card_list == null:
		printerr("❌ CardList が見つかりません。ノード構成・タイミングを確認してください。")
	else:
		print("✅ CardList 取得成功")

	$CloseButton.pressed.connect(func(): hide())

func show_discard(cards: Array[CardData]) -> void:
	if card_list == null:
		printerr("❌ card_list が null のままです。")
		return

	for child in card_list.get_children():
		child.queue_free()

	for card_data in cards:
		var slot = CardSlotScene.instantiate()
		slot.set_card_data(card_data)
		card_list.add_child(slot)

	show()
