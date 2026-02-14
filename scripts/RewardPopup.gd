extends Panel

@onready var card_container: Node = $CardContainer
@onready var confirm_button: Button = $ConfirmButton

var card_scene := preload("res://scenes/CardButton.tscn")
var selected_card: Node = null

# 報酬としてカードを表示
func show_rewards(cards: Array) -> void:
	# 前の報酬カードを削除
	for child in card_container.get_children():
		child.queue_free()

	# 新しいカードを生成して追加
	for card_data in cards:
		var card = card_scene.instantiate()
		card.setup(card_data.name, card_data.effect, card_data.power, card_data.cost, card_data.image)
		card.pressed.connect(func():
			select_card(card)
		)
		card_container.add_child(card)

	selected_card = null
	confirm_button.disabled = true

# カードを選択したときの処理
func select_card(card: Node) -> void:
	# すでに選択されているカードをリセット
	for c in card_container.get_children():
		c.modulate = Color.WHITE

	card.modulate = Color.YELLOW
	selected_card = card
	confirm_button.disabled = false

# 確定ボタン押下時
func _on_ConfirmButton_pressed() -> void:
	if selected_card == null:
		return

	print("選択されたカード:", selected_card.card_name)
	queue_free()  # ポップアップを閉じる
	# TODO: プレイヤーデッキに追加するなどの処理は外側で呼び出す
