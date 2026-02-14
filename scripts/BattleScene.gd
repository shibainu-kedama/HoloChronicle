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
@onready var end_turn_button = $EndTurnButton

const MAX_ENERGY = 3
const MAX_HAND_SIZE = 10

enum TurnState { PLAYER_TURN, ENEMY_TURN, BATTLE_END }
var turn_state: TurnState = TurnState.PLAYER_TURN

var player_hp: int
var player_max_hp: int
var player_block = 0
var player_energy = MAX_ENERGY
var energy_penalty_next_turn = false
var enemy_buff_active = false  # 敵バフ: 次の攻撃1.5倍

var deck: Array[CardData] = []
var discard_pile: Array[CardData] = []
var card_scene = preload("res://scenes/CardButton.tscn")
var popup_scene = preload("res://scenes/PopupDamage.tscn")

var enemy_data: EnemyData
var enemy_hp: int
var next_enemy_action = {}

# 追加: 終了多重防止
var battle_over := false

func _ready():
	print("バトル開始")
	# キャラ選択シーンで設定されたデッキを受け取る
	deck = Global.player_deck.duplicate()
	# デッキをシャッフルする
	deck.shuffle()

	# プレイヤーHP設定（Globalから復元）
	player_max_hp = Global.player_max_hp
	if Global.player_hp > 0:
		player_hp = Global.player_hp
	else:
		player_hp = player_max_hp

	# 敵データ読み込み
	_setup_enemy()

	# デッキから3枚引く
	draw_cards(3)

	player_hp_bar.max_value = player_max_hp
	player_hp_bar.value = player_hp

	decide_enemy_action()
	update_ui()
	setup_buttons()

func _setup_enemy():
	# Global.current_enemy_id が設定されていればそれを使う
	if Global.current_enemy_id != "":
		enemy_data = EnemyLoader.get_enemy_by_id(Global.current_enemy_id)

	# IDが未設定 or 見つからない場合はステージに応じてランダム選択
	if enemy_data == null:
		var stage = _get_current_stage_number()
		var is_boss = Global.is_boss_stage()
		enemy_data = EnemyLoader.get_random_enemy_for_stage(stage, is_boss)

	if enemy_data == null:
		push_error("敵データが見つかりません。デフォルト敵を使用します。")
		enemy_data = EnemyData.new()
		enemy_data.id = "default"
		enemy_data.name = "スライム"
		enemy_data.hp = 20
		enemy_data.image_path = "res://images/enemy_fubura.png"
		enemy_data.actions = [{"type": "attack", "power": 6, "weight": 1}]

	enemy_hp = enemy_data.hp
	enemy_ui.initialize_hp(enemy_data.hp)
	enemy_ui.set_enemy_name(enemy_data.name)

	# 敵画像セット
	if ResourceLoader.exists(enemy_data.image_path):
		enemy_image.texture = load(enemy_data.image_path)

func _get_current_stage_number() -> int:
	# ノードIDから階層番号を取得（例: "2-A" → 2）
	var node_id = Global.current_node_id
	if node_id.length() > 0 and node_id[0].is_valid_int():
		return int(node_id[0])
	return 1

func setup_buttons():
	discard_button.pressed.connect(_on_DiscardZone_pressed)
	deck_button.pressed.connect(_on_DeckZone_pressed)

func update_ui():
	player_block_label.text = "ブロック: %d" % player_block
	energy_label.text = "エナジー: %d" % player_energy
	_update_end_turn_button()

func _update_end_turn_button():
	if end_turn_button:
		end_turn_button.disabled = turn_state != TurnState.PLAYER_TURN

func draw_cards(count):
	print("draw_cards", str(deck.size()))
	for i in range(count):
		if card_container.get_child_count() >= MAX_HAND_SIZE:
			return
		if deck.is_empty():
			reshuffle_deck()
		if deck.is_empty():
			return
		var card_data = deck.pop_front()
		deck_zone.update_deck_count()
		send_deck_to_zone()
		var card = card_scene.instantiate()

		card.update_card_display(card_data)

		card.use_card.connect(_on_card_used)
		card_container.add_child(card)

func reshuffle_deck():
	deck = discard_pile.duplicate()
	discard_pile.clear()
	discard_label.text = str(discard_pile.size())
	deck.shuffle()

func decide_enemy_action():
	if enemy_data == null or enemy_data.actions.is_empty():
		next_enemy_action = {"type": "attack", "power": 6}
		enemy_ui.set_intent(next_enemy_action)
		return

	# 重み付きランダム選択
	var total_weight = 0
	for action in enemy_data.actions:
		total_weight += action.get("weight", 1)

	var roll = randi() % total_weight
	var cumulative = 0
	for action in enemy_data.actions:
		cumulative += action.get("weight", 1)
		if roll < cumulative:
			next_enemy_action = action.duplicate()
			break

	enemy_ui.set_intent(next_enemy_action)

func Discard_update(card):
	discard_pile.append(card.card_data)
	discard_label.text = str(discard_pile.size())

func _on_card_used(card):
	if not is_player_turn():
		return

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
	if turn_state != TurnState.BATTLE_END:
		start_player_turn()

func is_player_turn() -> bool:
	return turn_state == TurnState.PLAYER_TURN

func end_player_turn():
	turn_state = TurnState.ENEMY_TURN
	label.text = "ターン終了… 敵の行動中..."
	_update_end_turn_button()
	for card in card_container.get_children():
		discard_pile.append(card.card_data)
		card.queue_free()

func start_player_turn():
	turn_state = TurnState.PLAYER_TURN
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
			if enemy_buff_active:
				damage = int(damage * 1.5)
				enemy_buff_active = false
			apply_damage(damage)
			label.text = "%sの攻撃！ %d ダメージ！" % [enemy_data.name, damage]

		"multi_attack":
			var hits = next_enemy_action.get("times", 2)
			var dmg = next_enemy_action.power
			if enemy_buff_active:
				dmg = int(dmg * 1.5)
				enemy_buff_active = false
			for i in range(hits):
				await get_tree().create_timer(0.3).timeout
				apply_damage(dmg)
			label.text = "%sの連続攻撃！" % enemy_data.name

		"buff":
			enemy_buff_active = true
			label.text = "%sは力を溜めている…次の攻撃が強化！" % enemy_data.name

		"debuff":
			energy_penalty_next_turn = true
			label.text = "%sの邪悪な気配… 次ターンのエナジーが減少！" % enemy_data.name

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
		push_error("DeckZoneが見つからない、または set_cards が定義されていません")

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
	turn_state = TurnState.BATTLE_END
	_update_end_turn_button()

	# HPをGlobalに書き戻し
	Global.player_hp = player_hp

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
	turn_state = TurnState.BATTLE_END
	_update_end_turn_button()

	# HPをGlobalに書き戻し
	Global.player_hp = player_hp

	print("敗北！タイトル画面へ")
	get_tree().change_scene_to_file("res://scenes/TitleScene.tscn")
