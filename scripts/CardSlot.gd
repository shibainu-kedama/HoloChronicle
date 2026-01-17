extends Panel
class_name CardSlot

@export var card_name_label: Label
@export var card_effect_label: Label
@export var card_power_label: Label
@export var card_cost_label: Label
@export var card_image: TextureRect

var card_data: CardData

func set_card_data(data: CardData) -> void:
	card_data = data
	
	$VBoxContainer/Label_Name.text = card_data.name
	$VBoxContainer/Label_Effect.text = card_data.effect
	$VBoxContainer/Label_Power.text = str(card_data.power)
	$VBoxContainer/Label_Cost.text = str(card_data.cost)
	$VBoxContainer/Label_Info.text = card_data.info
	$TextureRect_Image.texture = load(card_data.image_path)
	
	if card_name_label:
		card_name_label.text = card_data.name
	
	if card_effect_label:
		card_effect_label.text = card_data.effect
	
	if card_power_label:
		card_power_label.text = str(card_data.power)
	
	if card_cost_label:
		card_cost_label.text = str(card_data.cost)
	
	if card_image and card_data.image != "":
		var tex = load(card_data.image)
		if tex is Texture2D:
			card_image.texture = tex
		else:
			push_error("❌ 指定されたパスが Texture2D ではありません: " + card_data.image)
	
	# デッキデータ で表示
	print("【set_card_data】%s / %s / %s / %s / %s / %s" % [card_data.name, card_data.effect, str(card_data.power), str(card_data.cost), card_data.info, card_data.image_path])
