extends Control

var card_buttons = []
var reward_cards: Array[CardData] = []
var reward_goods: GoodsData = null

func _ready():
	# HBoxContainer 内の CardButton ノードを自動収集（名前が "CardButton" で始まるノードのみ）
	var container = $VBoxContainer/HBoxContainer
	if container == null:
		print("HBoxContainer が見つかりません。ノード名やシーン構造を確認してください。")
		return

	for child in container.get_children():
		if child.name.begins_with("CardButton"):
			card_buttons.append(child)

	# null チェック（トラブル時用）
	if card_buttons.size() < 3:
		print("カードボタンが3つ未満です。シーン構成を確認してください。")
		return

	# ゴールド獲得
	var gold_reward = _calc_gold_reward()
	Global.player_gold += gold_reward
	var gold_label = $VBoxContainer/Label_Gold
	if gold_label:
		gold_label.text = "+%d ゴールド（所持: %d）" % [gold_reward, Global.player_gold]

	# スキップボタン接続
	var skip_btn = $VBoxContainer/Btn_Skip
	if skip_btn:
		skip_btn.pressed.connect(_on_skip_pressed)

	# グッズ報酬UIのボタン接続
	$VBoxContainer/GoodsRewardPanel/Btn_GoodsAccept.pressed.connect(_on_goods_accept)
	$VBoxContainer/GoodsRewardPanel/Btn_GoodsSkip.pressed.connect(_on_goods_skip)

	# すでにロード済みのカードからランダムに最大3枚抽選
	var offer_count = min(3, CardLoader.all_cards.size(), card_buttons.size())
	reward_cards = pick_random_cards(CardLoader.all_cards, offer_count)
	show_reward_cards(offer_count)

func show_reward_cards(count: int):
	for i in range(count):
		var btn = card_buttons[i]
		if btn == null:
			push_error("card_buttons[%d] が null です。" % i)
			continue

		var data = reward_cards[i]
		print("【show_reward_cards】%s / %s / %s / %s / %s / %s" % [data.name, data.effect, str(data.power), str(data.cost), data.info, data.image_path])

		# UI更新
		btn.update_card_display(data)
		# カードが押された時の処理を接続
		btn.connect("use_card", Callable(self, "_on_card_selected"))

func _on_card_selected(btn: TextureButton):
	var index = card_buttons.find(btn)
	if index == -1:
		push_error("選択されたボタンが card_buttons に見つかりません")
		return

	var selected_card = reward_cards[index]
	print("選択されたカード: ", selected_card.name)

	# プレイヤーデッキに追加（グローバル変数などに保存）
	Global.player_deck.append(selected_card)

	_try_goods_reward()

func _on_skip_pressed():
	_try_goods_reward()

func _try_goods_reward():
	# 未所持グッズプールから候補取得
	var owned_ids = Global.player_goods.map(func(g): return g.id)
	var unowned = CardLoader.all_goods.filter(func(g): return g.id not in owned_ids)

	# プールが空 or 50%で不発 → マップへ
	if unowned.is_empty() or randf() < 0.5:
		get_tree().change_scene_to_file("res://scenes/MapScene.tscn")
		return

	# ランダムに1つ選んでグッズ報酬UI表示
	unowned.shuffle()
	reward_goods = unowned[0]
	_show_goods_reward(reward_goods)

func _show_goods_reward(goods: GoodsData):
	# カード報酬UIを非表示
	$VBoxContainer/Label_Gold.visible = false
	$VBoxContainer/Label.visible = false
	$VBoxContainer/HBoxContainer.visible = false
	$VBoxContainer/Btn_Skip.visible = false

	# グッズ報酬UIを表示
	var panel = $VBoxContainer/GoodsRewardPanel
	panel.visible = true
	$VBoxContainer/GoodsRewardPanel/Label_GoodsName.text = goods.name
	$VBoxContainer/GoodsRewardPanel/Label_GoodsDesc.text = goods.description

func _on_goods_accept():
	if reward_goods:
		Global.player_goods.append(reward_goods)
		print("🎁 バトル報酬グッズ: %s" % reward_goods.name)
	get_tree().change_scene_to_file("res://scenes/MapScene.tscn")

func _on_goods_skip():
	get_tree().change_scene_to_file("res://scenes/MapScene.tscn")

func _calc_gold_reward() -> int:
	var stage = _get_stage_number()
	match stage:
		1: return randi_range(15, 25)
		2: return randi_range(20, 30)
		3: return randi_range(25, 35)
		_: return randi_range(15, 25)

func _get_stage_number() -> int:
	var node_id = Global.current_node_id
	var num_str := ""
	for i in range(node_id.length()):
		if node_id[i].is_valid_int():
			num_str += node_id[i]
		else:
			break
	if num_str != "":
		return int(num_str)
	return 1

# 推しタグによる重み付きランダム抽選
func pick_random_cards(array: Array[CardData], count: int) -> Array[CardData]:
	var oshi_tag := ""
	if Global.selected_character:
		oshi_tag = Global.selected_character.tag

	# 重み付きプールを構築（推しタグカードは3倍の出現率）
	var weighted_pool: Array[CardData] = []
	for card in array:
		var weight := 3 if oshi_tag != "" and card.has_tag(oshi_tag) else 1
		for i in range(weight):
			weighted_pool.append(card)

	weighted_pool.shuffle()

	# 重複なしでcount枚選ぶ
	var result: Array[CardData] = []
	for card in weighted_pool:
		if card not in result:
			result.append(card)
		if result.size() >= count:
			break
	return result
