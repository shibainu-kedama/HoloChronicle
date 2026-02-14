extends Control

@onready var card_container = $CardContainer
@onready var player_hp_bar = $PlayerHPBar
@onready var label = $InfoLabel
@onready var player_block_label = $BlockLabel
@onready var energy_label = $EnergyLabel
@onready var discard_button = $DiscardZone
@onready var discard_label = $DiscardZone/DiscardCountLabel
@onready var deck_button = $DeckZone/DeckImage
@onready var deck_zone := $DeckZone
@onready var enemy_ui = $EnemyUI
@onready var enemy_image = $EnemyImage

const MAX_ENERGY = 3
const MAX_HP = 100

var player_hp = MAX_HP
var player_block = 0
var player_energy = MAX_ENERGY
var energy_penalty_next_turn = false

var deck: Array[CardData] = []
var discard_pile: Array[CardData] = []
var card_scene = preload("res://scenes/CardButton.tscn")
var popup_scene = preload("res://scenes/PopupDamage.tscn")

var enemy_hp = 5
var next_enemy_action = {}

# 追加: 終了多重防止
var battle_over := false

func _ready():
	print("バトル開始")
	# キャラ選択シーンで設定されたデッキを受け取る
	deck = Global.player_deck.duplicate()
	# デッキをシャッフルする
	deck.shuffle()
	# デッキから3枚引くする
	draw_cards(3)
	
	player_hp_bar.max_value = MAX_HP
	player_hp_bar.value = player_hp

	enemy_ui.set_hp(enemy_hp)
	decide_enemy_action()

	update_ui()
	setup_buttons()

func setup_buttons():
	discard_button.pressed.connect(_on_DiscardZone_pressed)
	deck_button.pressed.connect(_on_DeckZone_pressed)

func update_ui():
	player_block_label.text = "ブロック: %d" % player_block
	energy_label.text = "エナジー: %d" % player_energy

func draw_cards(count):
	print("draw_cards", str(deck.size()))
	for i in range(count):
		if deck.is_empty():
			reshuffle_deck()
		if deck.is_empty():
			return
		var card_data = deck.pop_front()
		deck_zone.update_deck_count()
		send_deck_to_zone()
		var card = card_scene.instantiate()

		card.setup(card_data.name, card_data.effect, card_data.power, card_data.cost, card_data.image_path)
		# UI更新
		card.update_card_display(card_data)
		
		card.use_card.connect(_on_card_used)
		card_container.add_child(card)

func reshuffle_deck():
	deck = discard_pile.duplicate()
	discard_pile.clear()
	discard_label.text = str(discard_pile.size())
	deck.shuffle()

func decide_enemy_action():
	var r = randi() % 4
	match r:
		0:
			next_enemy_action = {"type": "attack", "power": 8}
		1:
			next_enemy_action = {"type": "multi_attack", "power": 4, "times": 2}
		2:
			next_enemy_action = {"type": "buff"}
		_:
			next_enemy_action = {"type": "debuff"}

	enemy_ui.set_intent(next_enemy_action)
	
func Discard_update(card):
	discard_pile.append(card.card_data)
	discard_label.text = str(discard_pile.size())

func _on_card_used(card):
	if card.cost > player_energy:
		label.text = "エナジーが足りない！"
		return

	player_energy -= card.cost
	card_container.remove_child(card)
	Discard_update(card)

	match card.effect_type:
		"attack":
			label.text = "攻撃カード使用: %d ダメージ！" % card.power
			apply_damage_to_enemy(card.power)
		"block":
			player_block += card.power
			label.text = "防御カード使用: ブロック +%d" % card.power
		"energy":
			player_energy = min(player_energy + card.power, MAX_ENERGY)
			label.text = "エナジー回復: +%d" % card.power

	update_ui()
	card.queue_free()

func apply_damage_to_enemy(amount):
	enemy_hp = max(enemy_hp - amount, 0)
	enemy_ui.set_hp(enemy_hp)
	show_popup_damage(amount)

	check_battle_result()

func _on_EndTurnButton_pressed():
	if not is_player_turn():
		return

	end_player_turn()
	await play_enemy_turn()
	start_player_turn()

func is_player_turn() -> bool:
	return true  # 状態管理を導入する場合ここで判定

func end_player_turn():
	label.text = "ターン終了… 敵の行動中..."
	for card in card_container.get_children():
		discard_pile.append(card.card_data)
		card.queue_free()

func start_player_turn():
	player_block = 0
	player_energy = MAX_ENERGY - 1 if energy_penalty_next_turn else MAX_ENERGY
	energy_penalty_next_turn = false
	decide_enemy_action()
	draw_cards(3)
	update_ui()
	label.text = "プレイヤーのターン！カードを選んでください"

func play_enemy_turn():
	await get_tree().create_timer(1.0).timeout
	match next_enemy_action.type:
		"attack":
			var damage = next_enemy_action.power
			apply_damage(damage)
			label.text = "敵の攻撃！ %d ダメージ！" % damage

		"multi_attack":
			var hits = next_enemy_action.times
			var dmg = next_enemy_action.power
			for i in range(hits):
				await get_tree().create_timer(0.3).timeout
				apply_damage(dmg)
			label.text = "敵の連続攻撃！"

		"buff":
			label.text = "敵は力を溜めている（バフ）"

		"debuff":
			energy_penalty_next_turn = true
			label.text = "敵の邪悪な気配… 次ターンのエナジーが減少！"

	update_ui()

func apply_damage(amount):
	var blocked = min(player_block, amount)
	var dmg = amount - blocked
	player_block -= blocked
	player_hp = max(player_hp - dmg, 0)
	player_hp_bar.value = player_hp
	print("被ダメ: %d (ブロック: %d → %d), 残HP: %d" % [amount, blocked, player_block, player_hp])

	check_battle_result()

func _on_DiscardZone_pressed():
	var popup = preload("res://scenes/DiscardPopup.tscn").instantiate()
	add_child(popup)
	await get_tree().process_frame
	popup.show_discard(discard_pile)

func _on_DeckZone_pressed():
	deck_zone.show_deck_popup()

func _on_card_selected(card):
	if "card_data" in card:
		discard_pile.append(card.card_data)
	else:
		push_error("選択された card に 'card_data' が存在しません。スクリプトがアタッチされているか確認してください。")

func send_deck_to_zone():
	if deck_zone and deck_zone.has_method("set_cards"):
		deck_zone.set_cards(deck)
	else:
		push_error("❌ DeckZoneが見つからない、または set_cards が定義されていません")

func show_popup_damage(amount: int):
	var popup = popup_scene.instantiate()
	add_child(popup)
	popup.global_position = enemy_image.global_position
	popup.show_damage(amount)

func check_battle_result():
	if enemy_hp <= 0:
		on_victory()
	elif player_hp <= 0:
		on_defeat()

func on_victory():
	
	if battle_over:
		return
	battle_over = true
	
	# データを一時的に保存したい場合はここでGlobalなどにセット
	if Global.is_boss_stage():
		print("勝利！ボス戦なのでゲームクリアへ")
		get_tree().change_scene_to_file("res://scenes/GameClear.tscn")
	else:
		print("勝利！報酬画面へ")
		get_tree().change_scene_to_file("res://scenes/RewardScene.tscn")
	

func on_defeat():
	
	if battle_over:
		return
	battle_over = true
	
	print("敗北！タイトル画面へ")
	# データを一時的に保存したい場合はここでGlobalなどにセット
	get_tree().change_scene_to_file("res://scenes/TitleScene.tscn")
