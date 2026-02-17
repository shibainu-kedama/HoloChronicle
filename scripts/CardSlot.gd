extends Panel
class_name CardSlot

var card_data: CardData

const EFFECT_DESCRIPTIONS := {
	"attack": "単体攻撃",
	"self_attack": "自傷攻撃：敵にダメージを与え自分も受ける",
	"multi_attack": "複数回攻撃",
	"block": "ブロックを得る（被ダメージを軽減）",
	"energy": "エナジーを回復する",
	"energy_burst": "エナジーを大量回復（副作用あり）",
	"draw": "デッキからカードを引く",
	"heal": "HPを回復する",
	"weak": "敵に脱力を付与（与ダメージ25%減少）",
	"aoe_attack": "全体攻撃",
	"vulnerable": "敵に脆弱を付与（被ダメージ50%増加）",
	"poison": "敵に毒を付与（毎ターンダメージ）",
	"aoe_poison": "全敵に毒を付与",
	"block_draw": "ブロック獲得＋カードを引く",
	"strength": "筋力を得る（攻撃ダメージ増加）",
	"curse": "呪い：使用不可。手札を圧迫する",
	"curse_damage": "呪い：使用不可。ターン開始時ダメージ",
}

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
	# 効果種別の説明
	var desc = EFFECT_DESCRIPTIONS.get(card_data.effect, "")
	if desc != "":
		tip += "\n\n【%s】" % desc
	tooltip_text = tip

	# デッキデータ で表示
	print("【set_card_data】%s / %s / %s / %s / %s / %s" % [card_data.name, card_data.effect, str(card_data.power), str(card_data.cost), card_data.info, card_data.image_path])
