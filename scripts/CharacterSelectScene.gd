# CharacterSelectScene.gd
extends Control

const CHAR_CSV: String = "res://data/characters.csv"

# ==== 背景 ====
@onready var background: TextureRect = $Background

# ==== 下部のキャラ選択ボタン ====
@onready var character_buttons: Array[TextureButton] = [
	$BottomArea/HBoxButtons/Btn_Character1,
	$BottomArea/HBoxButtons/Btn_Character2,
	$BottomArea/HBoxButtons/Btn_Character3,
]

# ==== キャラ詳細表示 ====
@onready var label_name      : Label       = $InfoPanel/Label_Name
@onready var label_desc      : Label       = $InfoPanel/Label_Desc
@onready var label_hp        : Label       = $InfoPanel/HBox_Stats/Label_HP
@onready var label_gold      : Label       = $InfoPanel/HBox_Stats/Label_Gold
@onready var label_talent    : Label       = $InfoPanel/TalentContainer/VBox_TalentTexts/Label_TalentName
@onready var label_talentdesc: Label       = $InfoPanel/TalentContainer/VBox_TalentTexts/Label_TalentDesc
@onready var tex_talent_icon : TextureRect = $InfoPanel/TalentContainer/TextureRect_TalentIcon

# ==== 決定・戻るボタン ====
@onready var button_confirm: Button = $Button_Confirm
@onready var button_back   : Button = $Button_Back

# ==== 状態 ====
var selected_index: int = -1
var characters: Array[CharacterData] = []


func _ready() -> void:
	# フェードイン
	FadeLayer.fade_in()

	# キャラ一覧ロード
	characters = CharacterLoader.load_characters(CHAR_CSV)
	if characters.is_empty():
		push_error("[CharacterSelect] キャラCSVが空 or 読み込み失敗")
		return

	# ボタンセットアップ
	_setup_buttons()

	# 最初は決定ボタン無効
	button_confirm.disabled = true

	button_confirm.pressed.connect(_on_confirm_pressed)
	button_back.pressed.connect(_on_back_pressed)


# 下部のキャラボタンにアイコンを設定 & シグナル接続
func _setup_buttons() -> void:
	var count: int = min(character_buttons.size(), characters.size())

	for i in range(count):
		var btn: TextureButton = character_buttons[i]
		var info: CharacterData = characters[i]

		# ボタン用の画像（icon_path があれば優先、なければ image_path）
		var tex_path: String = ""
		if info.talent_icon_path != "":  # ここを icon_path にしたければ CSV＆CharacterData 側も追加
			tex_path = info.talent_icon_path
		else:
			tex_path = info.image_path

		if tex_path != "" and ResourceLoader.exists(tex_path):
			btn.texture_normal = load(tex_path)
		else:
			push_warning("[CharacterSelect] ボタン画像が見つかりません: %s" % tex_path)

		# ボタン押下時のコールバック
		btn.pressed.connect(_on_character_selected.bind(i))


# キャラ選択時
func _on_character_selected(index: int) -> void:
	if index < 0 or index >= characters.size():
		return

	selected_index = index
	var info: CharacterData = characters[index]

	# === 情報パネル更新 ===
	label_name.text       = info.name
	label_desc.text       = info.description
	label_hp.text         = "HP: %d" % info.hp
	label_gold.text       = "GOLD: %d" % info.gold
	label_talent.text     = info.talent_name
	label_talentdesc.text = info.talent_desc

	# タレントアイコン
	var icon_path: String = info.talent_icon_path
	if icon_path != "" and ResourceLoader.exists(icon_path):
		tex_talent_icon.texture = load(icon_path)
	else:
		tex_talent_icon.texture = null

	# 背景イラスト切り替え（image_path を背景として使用）
	var bg_path: String = info.image_path
	if bg_path != "" and ResourceLoader.exists(bg_path):
		background.texture = load(bg_path)
	else:
		push_warning("[CharacterSelect] 背景画像が見つかりません: %s" % bg_path)

	# === ボタンのハイライト ===
	for i in range(character_buttons.size()):
		character_buttons[i].modulate = Color(1, 1, 1, 1)
	character_buttons[index].modulate = Color(1, 1, 1, 1).lerp(Color(1, 1, 0.5, 1), 0.5)

	# 決定ボタンを有効化
	button_confirm.disabled = false


# 決定 → 選んだキャラでゲーム開始
func _on_confirm_pressed() -> void:
	if selected_index < 0 or selected_index >= characters.size():
		push_warning("キャラを選んでください")
		return

	var selected: CharacterData = characters[selected_index]
	Global.selected_character = selected
	Global.player_hp = selected.hp
	Global.player_max_hp = selected.hp
	Global.player_gold = selected.gold
	Global.player_atk_bonus = 0

	# 初期デッキ読み込み
	Global.player_deck = DeckLoader.load_starting_deck(selected.id)
	print("🃏 初期デッキ:", Global.player_deck.map(func(c): return c.name))

	# 初期グッズ付与
	Global.player_goods.clear()
	Global.player_potions.clear()
	if selected.starting_goods_id != "":
		var goods = CardLoader.get_goods_by_id(selected.starting_goods_id)
		if goods:
			Global.player_goods.append(goods)
			print("🎁 初期グッズ:", goods.name)

	# フェード付きでマップへ
	await FadeLayer.change_scene_with_fade("res://scenes/MapScene.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/TitleScene.tscn")
