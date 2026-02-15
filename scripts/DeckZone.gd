extends Panel

@onready var deck_count_label: Label = $DeckImage/DeckCountLabel
@export var card_scene: PackedScene
@export var deck_data: Array[CardData] = []  # 外部からも編集可能に

# DeckPopup のプレハブをロード（パスに注意）
@onready var deck_popup_scene: PackedScene = preload("res://scenes/DeckPopup.tscn")

func _ready():
	update_deck_count()

func update_deck_count():
	print("update_deck_count:", str(deck_data.size()))
	deck_count_label.text = str(deck_data.size())

# デッキデータをコピーして保持
func set_cards(new_deck_data: Array[CardData]) -> void:
	deck_data = new_deck_data.duplicate() as Array[CardData]
	print("✅ DeckZone: deck_data を受け取りました")

# ポップアップでデッキを表示
func show_deck_popup() -> void:
	print("🃏 show_deck_popup() 呼び出し開始")

	if not deck_popup_scene:
		push_error("❌ DeckPopup.tscn の読み込みに失敗しました（deck_popup_scene が null）")
		return
	else:
		print("✅ DeckPopup.tscn の読み込み成功")

	var popup = deck_popup_scene.instantiate()
	print("📦 DeckPopup インスタンス化完了: ", popup)
	
	# DeckPopup を「画面基準の親ノード」に追加する
	get_tree().get_root().add_child(popup)
	print("✅ DeckPopup をシーンに追加しました")

	if popup.has_method("show_cards"):
		print("📨 show_cards() メソッドあり。カード表示処理を呼び出します")
		popup.show_cards(deck_data)
	else:
		print("⚠️ DeckPopup に show_cards() が存在しません")
