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

	# ツールチップ構築（デッキ確認用）
	var tip := "%s\nコスト: %d / 威力: %d" % [card_data.name, card_data.cost, card_data.power]
	# キーワード（カードタグ）
	var tags_text := ""
	for i in range(card_data.tags.size()):
		if i > 0:
			tags_text += ", "
		tags_text += card_data.tags[i]
	if tags_text != "":
		tip += "\nキーワード: " + tags_text
	# カード説明
	if card_data.info != "":
		tip += "\n" + card_data.info
	# 効果種別の説明（CSV参照）
	var desc: String = CardLoader.get_effect_description(card_data.effect)
	if desc != "":
		tip += "\n\n【%s】" % desc
	tooltip_text = tip

	# デッキデータ で表示
	print("【set_card_data】%s / %s / %s / %s / %s / %s" % [card_data.name, card_data.effect, str(card_data.power), str(card_data.cost), card_data.info, card_data.image_path])
