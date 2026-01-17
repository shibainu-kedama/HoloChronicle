extends Control

@onready var label_name: Label = $NameLabel
@onready var label_cost: Label = $CostLabel
@onready var label_effect: Label = $EffectLabel
@onready var texture_rect: TextureRect = $TextureRect

# カード情報をUIに表示
func show_card(card_data: Dictionary) -> void:
	label_name.text = card_data.get("name", "カード名不明")
	label_cost.text = "コスト: %d" % card_data.get("cost", 0)
	label_effect.text = format_effect_text(card_data)
	
	var image_path = card_data.get("image", "")
	if image_path != "":
		var texture = load(image_path)
		if texture:
			texture_rect.texture = texture
		else:
			texture_rect.texture = null
	else:
		texture_rect.texture = null

# 効果説明テキストのフォーマット
func format_effect_text(card_data: Dictionary) -> String:
	var effect_type = card_data.get("effect", "")
	var power = card_data.get("power", 0)

	match effect_type:
		"attack":
			return "攻撃 %d ダメージ" % power
		"block":
			return "ブロック %d" % power
		"multi_attack":
			var times = card_data.get("times", 2)
			return "連続攻撃 %d × %d" % [power, times]
		"heal":
			return "回復 %d" % power
		_:
			return "不明な効果"
