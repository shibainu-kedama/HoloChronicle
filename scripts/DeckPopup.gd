extends Panel

@onready var card_list := $ScrollContainer/CardList
@onready var close_button := $CloseButton

# カードスロットプレハブを読み込み
var card_scene: PackedScene = preload("res://scenes/CardSlot.tscn")

func _ready():
	$CloseButton.pressed.connect(_on_close_button_pressed)

func _on_close_button_pressed():
	hide()

func show_cards(deck_data: Array):
	print("🃏 show_cards() 呼び出し - デッキ枚数: ", deck_data.size())

	# 一度既存のカード表示を削除
	for child in card_list.get_children():
		print("🗑️ 削除中の子ノード: ", child)
		child.queue_free()

	# 各カードを CardSlot で表示
	for i in deck_data.size():
		var card_data = deck_data[i]
		print("➕ 表示カード[%d]: %s / コスト: %d" % [i, card_data.name, card_data.cost])
		
		var card := card_scene.instantiate()
		card.set_card_data(card_data)
		card_list.add_child(card)
