extends Control

@onready var card_container = $CardContainer
@onready var player_hp_bar = $PlayerHPBar
@onready var player_hp_label = $PlayerHPLabel
@onready var label = $InfoLabel
@onready var player_block_label = $BlockLabel
@onready var player_status_label = $PlayerStatusLabel
@onready var energy_label = $EnergyLabel
@onready var discard_button = $DiscardZone
@onready var discard_label = $DiscardZone/DiscardCountLabel
@onready var deck_button = $DeckZone/DeckImage
@onready var deck_zone := $DeckZone
@onready var enemy_container = $EnemyContainer
@onready var end_turn_button = $EndTurnButton
@onready var talent_button = $TalentButton
@onready var potion_buttons: Array[Button] = [
	$PotionContainer/PotionBtn0,
	$PotionContainer/PotionBtn1,
	$PotionContainer/PotionBtn2,
]

# 敵スロットUI参照（最大3体）
@onready var enemy_slots: Array = [
	$EnemyContainer/EnemySlot0,
	$EnemyContainer/EnemySlot1,
	$EnemyContainer/EnemySlot2,
]
@onready var enemy_images: Array = [
	$EnemyContainer/EnemySlot0/EnemyImage0,
	$EnemyContainer/EnemySlot1/EnemyImage1,
	$EnemyContainer/EnemySlot2/EnemyImage2,
]
@onready var enemy_uis: Array = [
	$EnemyContainer/EnemySlot0/EnemyUI0,
	$EnemyContainer/EnemySlot1/EnemyUI1,
	$EnemyContainer/EnemySlot2/EnemyUI2,
]

const MAX_ENERGY = 3
const MAX_HAND_SIZE = 10
const MAX_ENEMIES = 3

enum TurnState { PLAYER_TURN, ENEMY_TURN, BATTLE_END }
var turn_state: TurnState = TurnState.PLAYER_TURN

var player_hp: int
var player_max_hp: int
var player_block = 0
var player_energy = MAX_ENERGY
var player_statuses: Dictionary = {}

var deck: Array[CardData] = []
var discard_pile: Array[CardData] = []
var card_scene = preload("res://scenes/CardButton.tscn")
var popup_scene = preload("res://scenes/PopupDamage.tscn")

var enemy_data: EnemyData  # 元の敵データ（共通）

# 複数敵配列: [{data, hp, block, statuses, action}]
var enemies: Array = []
var target_index: int = 0

# 追加: 終了多重防止
var battle_over := false
var talent_used_this_turn := false

func _ready():
	print("バトル開始")
	deck = Global.player_deck.duplicate() as Array[CardData]
	deck.shuffle()

	player_max_hp = Global.player_max_hp
	if Global.player_hp > 0:
		player_hp = Global.player_hp
	else:
		player_hp = player_max_hp

	_setup_enemies()

	player_hp_bar.max_value = player_max_hp
	player_hp_bar.value = player_hp

	if Global.selected_character and talent_button:
		talent_button.text = Global.selected_character.talent_name

	setup_buttons()
	_setup_potion_buttons()
	start_player_turn()
	_apply_goods_effects("battle_start", null)
	update_ui()

func _setup_enemies():
	# 敵データ取得
	if Global.current_enemy_id != "":
		enemy_data = EnemyLoader.get_enemy_by_id(Global.current_enemy_id)

	if enemy_data == null:
		var stage = _get_current_stage_number()
		var is_boss = Global.is_boss_stage()
		var is_elite = Global.is_elite_stage()
		enemy_data = EnemyLoader.get_random_enemy_for_stage(stage, is_boss, is_elite)

	if enemy_data == null:
		push_error("敵データが見つかりません。デフォルト敵を使用します。")
		enemy_data = EnemyData.new()
		enemy_data.id = "default"
		enemy_data.name = "スライム"
		enemy_data.hp = 20
		enemy_data.image_path = "res://images/enemy_fubura.png"
		enemy_data.actions = [{"type": "attack", "power": 6, "weight": 1}]
		enemy_data.count = 1

	var count = clampi(enemy_data.count, 1, MAX_ENEMIES)

	# 全スロット非表示にしてから必要数だけ表示
	for i in range(MAX_ENEMIES):
		enemy_slots[i].visible = false

	enemies.clear()
	for i in range(count):
		var enemy_dict = {
			"data": enemy_data,
			"hp": enemy_data.hp,
			"block": 0,
			"statuses": {},
			"action": {},
		}
		enemies.append(enemy_dict)

		# スロット表示・初期化
		enemy_slots[i].visible = true
		enemy_uis[i].initialize_hp(enemy_data.hp)
		enemy_uis[i].set_enemy_name(enemy_data.name)

		if ResourceLoader.exists(enemy_data.image_path):
			enemy_images[i].texture_normal = load(enemy_data.image_path)

		# クリックでターゲット選択
		enemy_images[i].pressed.connect(_on_enemy_clicked.bind(i))

	# デフォルトターゲット: 最初の敵
	target_index = 0
	_update_target_highlight()

func _get_current_stage_number() -> int:
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

# === ターゲット選択 ===

func _on_enemy_clicked(index: int):
	if index < 0 or index >= enemies.size():
		return
	if enemies[index].hp <= 0:
		return
	target_index = index
	_update_target_highlight()

func _update_target_highlight():
	for i in range(enemies.size()):
		if not enemy_slots[i].visible:
			continue
		if i == target_index and enemies[i].hp > 0:
			enemy_images[i].modulate = Color(1.3, 1.3, 1.3, 1.0)
		else:
			enemy_images[i].modulate = Color(1.0, 1.0, 1.0, 1.0)

func _select_next_alive_target():
	# 現在のターゲットが生存中ならそのまま
	if target_index >= 0 and target_index < enemies.size() and enemies[target_index].hp > 0:
		return
	# 次の生存敵を探す
	for i in range(enemies.size()):
		if enemies[i].hp > 0:
			target_index = i
			_update_target_highlight()
			return

# === ボタンセットアップ ===

func setup_buttons():
	discard_button.pressed.connect(_on_DiscardZone_pressed)
	deck_button.pressed.connect(_on_DeckZone_pressed)

# === UI更新 ===

func update_ui():
	if player_hp_label:
		player_hp_label.text = "HP: %d / %d" % [player_hp, player_max_hp]
	player_block_label.text = "ブロック: %d" % player_block
	energy_label.text = "エナジー: %d" % player_energy

	# 各敵のUI更新
	for i in range(enemies.size()):
		if enemies[i].hp <= 0:
			continue
		enemy_uis[i].set_block(enemies[i].block)
		enemy_uis[i].set_statuses(enemies[i].statuses)

	# プレイヤーステータス
	if player_status_label:
		player_status_label.text = _format_statuses(player_statuses)
	_update_end_turn_button()
	_update_talent_button()
	_update_potion_buttons()

# === ステータス効果システム ===

func _format_statuses(statuses: Dictionary) -> String:
	var parts: Array[String] = []
	for key in statuses:
		var val = statuses[key]
		if val <= 0:
			continue
		match key:
			"weak":
				parts.append("脱力%d" % val)
			"vulnerable":
				parts.append("脆弱%d" % val)
			"strength":
				parts.append("筋力+%d" % val)
			"poison":
				parts.append("毒%d" % val)
	return " ".join(parts)

func add_status(target: String, status: String, stacks: int, enemy_idx: int = -1) -> void:
	if target == "player":
		player_statuses[status] = player_statuses.get(status, 0) + stacks
	else:
		var idx = enemy_idx if enemy_idx >= 0 else target_index
		if idx >= 0 and idx < enemies.size():
			var dict = enemies[idx].statuses
			dict[status] = dict.get(status, 0) + stacks

func get_status(target: String, status: String, enemy_idx: int = -1) -> int:
	if target == "player":
		return player_statuses.get(status, 0)
	else:
		var idx = enemy_idx if enemy_idx >= 0 else target_index
		if idx >= 0 and idx < enemies.size():
			return enemies[idx].statuses.get(status, 0)
		return 0

func decay_statuses(target: String, enemy_idx: int = -1) -> void:
	var dict: Dictionary
	if target == "player":
		dict = player_statuses
	else:
		var idx = enemy_idx if enemy_idx >= 0 else target_index
		if idx < 0 or idx >= enemies.size():
			return
		dict = enemies[idx].statuses

	var to_remove: Array[String] = []
	for key in dict:
		if key == "strength" or key == "poison":
			continue
		dict[key] -= 1
		if dict[key] <= 0:
			to_remove.append(key)
	for key in to_remove:
		dict.erase(key)

func calc_attack_damage(base: int, attacker: String, attacker_idx: int = -1, defender_idx: int = -1) -> int:
	var dmg = base + get_status(attacker, "strength", attacker_idx)
	if get_status(attacker, "weak", attacker_idx) > 0:
		dmg = int(dmg * 0.75)
	var defender = "enemy" if attacker == "player" else "player"
	var def_idx = defender_idx if defender_idx >= 0 else target_index
	if get_status(defender, "vulnerable", def_idx) > 0:
		dmg = int(dmg * 1.5)
	return max(dmg, 0)

func _update_end_turn_button():
	if end_turn_button:
		end_turn_button.disabled = turn_state != TurnState.PLAYER_TURN

# === カード処理 ===

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
		send_deck_to_zone()
		deck_zone.update_deck_count()
		var card = card_scene.instantiate()
		card.update_card_display(card_data)
		card.use_card.connect(_on_card_used)
		card_container.add_child(card)

func reshuffle_deck():
	deck = discard_pile.duplicate() as Array[CardData]
	discard_pile.clear()
	discard_label.text = str(discard_pile.size())
	deck.shuffle()

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
			var base = card.power + Global.player_atk_bonus
			if card.card_data.id == "elite_strike" and (get_status("enemy", "weak") > 0 or get_status("enemy", "vulnerable") > 0):
				base = 12 + Global.player_atk_bonus
			elif card.card_data.id == "suisei_axe" and get_status("enemy", "vulnerable") > 0:
				base = card.power + 5 + Global.player_atk_bonus
			var dealt = calc_attack_damage(base, "player")
			label.text = "攻撃カード使用: %d ダメージ！" % dealt
			apply_damage_to_enemy(dealt)
		"self_attack":
			var dealt = calc_attack_damage(card.power + Global.player_atk_bonus, "player")
			apply_damage_to_enemy(dealt)
			apply_damage(5)
			label.text = "捨て身！ %dダメージ！ 反動で5ダメージ！" % dealt
		"multi_attack":
			var hit_dmg = calc_attack_damage(card.power + Global.player_atk_bonus, "player")
			for i in range(3):
				apply_damage_to_enemy(hit_dmg)
				if battle_over:
					break
			label.text = "連撃！ %d×3 ダメージ！" % hit_dmg
		"block":
			player_block += card.power
			label.text = "防御カード使用: ブロック +%d" % card.power
		"energy":
			player_energy = min(player_energy + card.power, MAX_ENERGY)
			label.text = "エナジー回復: +%d" % card.power
		"energy_burst":
			player_energy += card.power
			add_status("player", "weak", 1)
			label.text = "覚醒！ エナジー +%d（脱力1付与）" % card.power
		"draw":
			draw_cards(card.power)
			label.text = "ドロー！ %d枚引いた！" % card.power
		"heal":
			player_hp = min(player_hp + card.power, player_max_hp)
			player_hp_bar.value = player_hp
			label.text = "回復！ HP +%d" % card.power
		"weak":
			add_status("enemy", "weak", card.power)
			label.text = "敵に脱力を%d付与！" % card.power
		"aoe_attack":
			var total_dmg = 0
			for i in range(enemies.size()):
				if enemies[i].hp > 0:
					var dealt = calc_attack_damage(card.power + Global.player_atk_bonus, "player", -1, i)
					apply_damage_to_enemy(dealt, i)
					total_dmg += dealt
					if battle_over:
						break
			label.text = "全体攻撃！ 合計%dダメージ！" % total_dmg
		"vulnerable":
			add_status("enemy", "vulnerable", card.power)
			label.text = "敵に脆弱を%d付与！" % card.power
		"poison":
			add_status("enemy", "poison", card.power)
			label.text = "敵に毒を%d付与！" % card.power
		"aoe_poison":
			for i in range(enemies.size()):
				if enemies[i].hp > 0:
					add_status("enemy", "poison", card.power, i)
			label.text = "全敵に毒を%d付与！" % card.power
		"block_draw":
			player_block += card.power
			draw_cards(1)
			label.text = "ブロック +%d＋1枚ドロー！" % card.power
		"strength":
			add_status("player", "strength", card.power)
			label.text = "筋力 +%d！" % card.power

	_apply_goods_effects("on_tagged_card", card)
	update_ui()
	card.queue_free()

# === 敵へのダメージ ===

func apply_damage_to_enemy(amount: int, index: int = -1):
	var idx = index if index >= 0 else target_index
	if idx < 0 or idx >= enemies.size():
		return
	var e = enemies[idx]
	var blocked = min(e.block, amount)
	var actual = amount - blocked
	e.block -= blocked
	e.hp = max(e.hp - actual, 0)
	enemy_uis[idx].set_hp(e.hp)
	show_popup_damage(actual, idx)

	if e.hp <= 0:
		# 撃破 → スロット非表示化
		enemy_slots[idx].visible = false
		_select_next_alive_target()

	check_battle_result()

# === ターン管理 ===

func _on_EndTurnButton_pressed():
	if not is_player_turn():
		return

	end_player_turn()
	await play_enemy_turn()
	if battle_over or not is_inside_tree():
		return
	if turn_state != TurnState.BATTLE_END:
		start_player_turn()

func is_player_turn() -> bool:
	return turn_state == TurnState.PLAYER_TURN

func end_player_turn():
	turn_state = TurnState.ENEMY_TURN
	label.text = "ターン終了… 敵の行動中..."
	decay_statuses("player")
	_update_end_turn_button()
	for card in card_container.get_children():
		discard_pile.append(card.card_data)
		card.queue_free()

func start_player_turn():
	turn_state = TurnState.PLAYER_TURN
	talent_used_this_turn = false
	player_block = 0
	player_energy = MAX_ENERGY

	_apply_poison_damage()

	# 全生存敵のブロックリセット＆行動決定
	for i in range(enemies.size()):
		if enemies[i].hp > 0:
			enemies[i].block = 0
			decide_enemy_action(i)

	draw_cards(3)
	_apply_goods_effects("turn_start", null)
	update_ui()
	label.text = "プレイヤーのターン！カードを選んでください"

# === 毒ダメージ処理 ===

func _apply_poison_damage():
	for i in range(enemies.size()):
		if enemies[i].hp <= 0:
			continue
		var stacks = enemies[i].statuses.get("poison", 0)
		if stacks <= 0:
			continue
		# 毒ダメージはブロック無視でHP直接適用
		enemies[i].hp = max(enemies[i].hp - stacks, 0)
		enemy_uis[i].set_hp(enemies[i].hp)
		show_popup_damage(stacks, i)
		print("毒ダメージ: 敵%d に %d ダメージ" % [i, stacks])
		# スタック1減少、0なら除去
		stacks -= 1
		if stacks <= 0:
			enemies[i].statuses.erase("poison")
		else:
			enemies[i].statuses["poison"] = stacks
		# 撃破判定
		if enemies[i].hp <= 0:
			enemy_slots[i].visible = false
			_select_next_alive_target()
			check_battle_result()
			if battle_over:
				return

# === 敵行動決定 ===

func decide_enemy_action(index: int):
	var e = enemies[index]
	var data = e.data
	if data == null or data.actions.is_empty():
		e.action = {"type": "attack", "power": 6}
		enemy_uis[index].set_intent(e.action)
		return

	var total_weight = 0
	for action in data.actions:
		total_weight += action.get("weight", 1)

	var roll = randi() % total_weight
	var cumulative = 0
	for action in data.actions:
		cumulative += action.get("weight", 1)
		if roll < cumulative:
			e.action = action.duplicate()
			break

	enemy_uis[index].set_intent(e.action)

# === 敵ターン（全敵が順番に行動） ===

func play_enemy_turn():
	for i in range(enemies.size()):
		if battle_over or not is_inside_tree():
			return
		if enemies[i].hp <= 0:
			continue

		await get_tree().create_timer(0.8).timeout
		if battle_over or not is_inside_tree():
			return

		var e = enemies[i]
		var e_name = e.data.name if e.data else "敵"

		match e.action.get("type", ""):
			"attack":
				var damage = calc_attack_damage(e.action.power, "enemy", i)
				apply_damage(damage)
				if battle_over or not is_inside_tree():
					return
				label.text = "%sの攻撃！ %d ダメージ！" % [e_name, damage]

			"multi_attack":
				var hits = e.action.get("times", 2)
				var dmg = calc_attack_damage(e.action.power, "enemy", i)
				for h in range(hits):
					await get_tree().create_timer(0.3).timeout
					if battle_over or not is_inside_tree():
						return
					apply_damage(dmg)
					if battle_over or not is_inside_tree():
						return
				label.text = "%sの連続攻撃！" % e_name

			"buff":
				add_status("enemy", "strength", 3, i)
				label.text = "%sは力を溜めている…筋力+3！" % e_name

			"debuff":
				add_status("player", "weak", 1)
				label.text = "%sの邪悪な気配… プレイヤーに脱力付与！" % e_name

			"block":
				var gain = e.action.get("power", 0)
				e.block += gain
				label.text = "%sは防御を固めた（ブロック +%d）" % [e_name, gain]

		if battle_over or not is_inside_tree():
			return
		decay_statuses("enemy", i)
		update_ui()

# === プレイヤーへのダメージ ===

func apply_damage(amount):
	var blocked = min(player_block, amount)
	var dmg = amount - blocked
	player_block -= blocked
	player_hp = max(player_hp - dmg, 0)
	player_hp_bar.value = player_hp
	print("被ダメ: %d (ブロック: %d → %d), 残HP: %d" % [amount, blocked, player_block, player_hp])

	check_battle_result()

# === ポップアップダメージ ===

func show_popup_damage(amount: int, index: int = -1):
	var idx = index if index >= 0 else target_index
	var popup = popup_scene.instantiate()
	add_child(popup)
	if idx >= 0 and idx < enemy_images.size():
		popup.global_position = enemy_images[idx].global_position
	popup.show_damage(amount)

# === バトル結果判定 ===

func check_battle_result():
	# 全敵撃破で勝利
	var all_dead = true
	for e in enemies:
		if e.hp > 0:
			all_dead = false
			break
	if all_dead:
		on_victory()
	elif player_hp <= 0:
		on_defeat()

func on_victory():
	if battle_over:
		return
	battle_over = true
	turn_state = TurnState.BATTLE_END
	_update_end_turn_button()

	_apply_goods_effects("battle_end", null)
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

	print("敗北！ゲームオーバー画面へ")
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

# === その他UI ===

func _on_DiscardZone_pressed():
	var popup = preload("res://scenes/DiscardPopup.tscn").instantiate()
	add_child(popup)
	await get_tree().process_frame
	popup.show_discard(discard_pile)

func _on_DeckZone_pressed():
	deck_zone.show_deck_popup()

func send_deck_to_zone():
	if deck_zone and deck_zone.has_method("set_cards"):
		deck_zone.set_cards(deck)
	else:
		push_error("DeckZoneが見つからない、または set_cards が定義されていません")

# === タレント（固有スキル） ===

func _on_TalentButton_pressed():
	if not is_player_turn() or talent_used_this_turn or battle_over:
		return

	var cost = _get_talent_cost()
	if player_energy < cost:
		label.text = "エナジーが足りない！"
		return

	if not Global.selected_character:
		return

	player_energy -= cost
	talent_used_this_turn = true

	match Global.selected_character.id:
		"lui":  # 鷹の眼: 3ダメ×3回
			for i in range(3):
				apply_damage_to_enemy(3)
				if battle_over:
					break
			label.text = "鷹の眼！ 3×3 = 9ダメージ！"
		"miko":  # エリート巫女ビーム: 6ダメージ
			apply_damage_to_enemy(6)
			label.text = "エリート巫女ビーム！ 6ダメージ！"
		"suisei":  # スターダストブレイク: 15ダメージ
			apply_damage_to_enemy(15)
			label.text = "スターダストブレイク！ 15ダメージ！"

	update_ui()

func _get_talent_cost() -> int:
	if Global.selected_character and Global.selected_character.id == "suisei":
		return 2
	return 1

func _update_talent_button():
	if not talent_button:
		return
	talent_button.disabled = (
		turn_state != TurnState.PLAYER_TURN
		or talent_used_this_turn
		or battle_over
		or player_energy < _get_talent_cost()
	)

# === グッズ（パッシブ効果） ===

func _apply_goods_effects(trigger: String, card) -> void:
	var char_tag := ""
	if Global.selected_character:
		char_tag = Global.selected_character.tag

	for goods in Global.player_goods:
		if goods.trigger != trigger:
			continue

		if trigger == "on_tagged_card":
			if card == null or not card.card_data.has_tag(char_tag):
				continue

		match goods.effect:
			"heal":
				player_hp = min(player_hp + goods.value, player_max_hp)
				player_hp_bar.value = player_hp
				print("🎁 グッズ[%s]: HP +%d" % [goods.name, goods.value])
			"block":
				player_block += goods.value
				print("🎁 グッズ[%s]: ブロック +%d" % [goods.name, goods.value])
			"energy":
				player_energy += goods.value
				print("🎁 グッズ[%s]: エナジー +%d" % [goods.name, goods.value])
			"gold":
				Global.player_gold += goods.value
				print("🎁 グッズ[%s]: ゴールド +%d" % [goods.name, goods.value])

# === ポーション（消耗品） ===

func _setup_potion_buttons():
	for i in range(potion_buttons.size()):
		if i < Global.player_potions.size():
			var potion = Global.player_potions[i]
			potion_buttons[i].text = potion.name
			potion_buttons[i].tooltip_text = potion.description
			potion_buttons[i].visible = true
			potion_buttons[i].pressed.connect(_on_potion_used.bind(i))
		else:
			potion_buttons[i].visible = false

func _on_potion_used(index: int):
	if not is_player_turn() or battle_over:
		return
	if index >= Global.player_potions.size():
		return

	var potion = Global.player_potions[index]

	match potion.effect:
		"heal":
			player_hp = min(player_hp + potion.value, player_max_hp)
			player_hp_bar.value = player_hp
			label.text = "%s使用！ HP +%d" % [potion.name, potion.value]
		"energy":
			player_energy += potion.value
			label.text = "%s使用！ エナジー +%d" % [potion.name, potion.value]
		"strength":
			add_status("player", "strength", potion.value)
			label.text = "%s使用！ 筋力 +%d" % [potion.name, potion.value]
		"aoe_poison":
			for i in range(enemies.size()):
				if enemies[i].hp > 0:
					add_status("enemy", "poison", potion.value, i)
			label.text = "%s使用！ 全敵に毒%d付与！" % [potion.name, potion.value]

	Global.player_potions.remove_at(index)
	print("🧪 ポーション使用: %s" % potion.name)

	# ボタン再構築（インデックスがずれるので全リセット）
	for btn in potion_buttons:
		# 全接続を解除
		for conn in btn.pressed.get_connections():
			btn.pressed.disconnect(conn.callable)
		btn.visible = false
	for i in range(Global.player_potions.size()):
		var p = Global.player_potions[i]
		potion_buttons[i].text = p.name
		potion_buttons[i].tooltip_text = p.description
		potion_buttons[i].visible = true
		potion_buttons[i].pressed.connect(_on_potion_used.bind(i))

	update_ui()

func _update_potion_buttons():
	for i in range(potion_buttons.size()):
		if potion_buttons[i].visible:
			potion_buttons[i].disabled = not is_player_turn() or battle_over
