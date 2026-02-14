extends Panel
class_name CardSlot

var card_data: CardData

func set_card_data(data: CardData) -> void:
	card_data = data
	
	$VBoxContainer/Label_Name.text = card_data.name
	$VBoxContainer/Label_Effect.text = card_data.effect
	$VBoxContainer/Label_Power.text = str(card_data.power)
	$VBoxContainer/Label_Cost.text = str(card_data.cost)
	$VBoxContainer/Label_Info.text = card_data.info
	$TextureRect_Image.texture = load(card_data.image_path)

	# デッキデータ で表示
	print("【set_card_data】%s / %s / %s / %s / %s / %s" % [card_data.name, card_data.effect, str(card_data.power), str(card_data.cost), card_data.info, card_data.image_path])
