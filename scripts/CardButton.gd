extends TextureButton

signal use_card(card)

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

# カードデータ（外部から渡される）
var card_name: String
var effect_type: String
var power: int
var cost: int
var image_path: String

# カードのデータを保持するための変数
var card_data: CardData

func _ready():
	# 既存の初期化…
	hoverfx_init()
	connect("pressed", Callable(self, "_on_pressed"))

func _on_pressed():
	emit_signal("use_card", self)

func _on_mouse_entered() -> void:
	_hoverfx_on_hover_in()

func _on_mouse_exited() -> void:
	_hoverfx_on_hover_out()

func update_card_display(data: CardData) -> void:
	card_data = data
	card_name = data.name
	effect_type = data.effect
	power = data.power
	cost = data.cost
	image_path = data.image_path

	$VBoxContainer/Label_Name.text = card_data.name
	$VBoxContainer/Label_Effect.text = card_data.effect
	$VBoxContainer/HBox_Power/Label_Power.text = str(card_data.power)
	$VBoxContainer/HBox_Cost/Label_Cost.text = str(card_data.cost)
	$VBoxContainer/Label_Info.text = card_data.info
	$CardTexture.texture = load(card_data.image_path)

	# レアリティ・呪いに応じた名前色
	if card_data.is_curse():
		$VBoxContainer/Label_Name.add_theme_color_override("font_color", Color(0.7, 0.1, 0.5))
	else:
		match card_data.rarity:
			"rare":
				$VBoxContainer/Label_Name.add_theme_color_override("font_color", Color(1.0, 0.78, 0.1))   # ゴールド
			"uncommon":
				$VBoxContainer/Label_Name.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))    # 青
			_:
				$VBoxContainer/Label_Name.remove_theme_color_override("font_color")
	# ツールチップ構築（レアリティ表示付き）
	const RARITY_LABELS := {"common": "★ コモン", "uncommon": "★★ アンコモン", "rare": "★★★ レア"}
	var rarity_label: String = RARITY_LABELS.get(card_data.rarity, "★ コモン")
	var tip := "%s  [%s]\nコスト: %d / 威力: %d" % [card_data.name, rarity_label, card_data.cost, card_data.power]
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
	
# ================= Hover/Pop FX (for BaseButton/TextureButton) =================
@export var hoverfx_scale: float = 1.50            # ホバー時の拡大倍率
@export var hoverfx_duration: float = 0.08         # ホバー in/out の時間
@export var hoverfx_hover_z: int = 20              # ホバー時の z_index
@export var hoverfx_press_shrink_ratio: float = 0.94  # クリック時に一瞬縮む比率
@export var hoverfx_press_in_duration: float = 0.04   # 縮む速さ
@export var hoverfx_press_out_duration: float = 0.10  # 戻る速さ

var _hoverfx_base_scale := Vector2.ONE
var _hoverfx_is_hovered := false
var _hoverfx_tween: Tween

func hoverfx_init() -> void:
	# BaseButton 前提（TextureButton/ Button）
	_hoverfx_base_scale = scale
	# 中心基準で拡大
	pivot_offset = size * 0.5
	resized.connect(func(): pivot_offset = size * 0.5)

	# フォーカス操作(Enter/Space)でも“選択中”に見せたい場合は有効に
	if focus_mode == Control.FOCUS_NONE:
		focus_mode = Control.FOCUS_ALL

	# mouse_entered / mouse_exited は tscn 側接続を利用
	if not focus_entered.is_connected(_hoverfx_on_hover_in):
		focus_entered.connect(_hoverfx_on_hover_in)
	if not focus_exited.is_connected(_hoverfx_on_hover_out):
		focus_exited.connect(_hoverfx_on_hover_out)

	# クリックで“ポン”
	if self is BaseButton and not pressed.is_connected(_hoverfx_on_pressed):
		pressed.connect(_hoverfx_on_pressed)

func _hoverfx_on_hover_in() -> void:
	_hoverfx_is_hovered = true
	_hoverfx_animate_to(_hoverfx_base_scale * hoverfx_scale, hoverfx_hover_z)

func _hoverfx_on_hover_out() -> void:
	_hoverfx_is_hovered = false
	_hoverfx_animate_to(_hoverfx_base_scale, 0)

func _hoverfx_on_pressed() -> void:
	_hoverfx_play_click_pop()

func _hoverfx_play_click_pop() -> void:
	var final_target := _hoverfx_base_scale * (hoverfx_scale if _hoverfx_is_hovered else 1.0)
	var pressed_target := final_target * hoverfx_press_shrink_ratio

	if _hoverfx_tween and _hoverfx_tween.is_running():
		_hoverfx_tween.kill()

	if _hoverfx_is_hovered:
		z_index = hoverfx_hover_z

	_hoverfx_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hoverfx_tween.tween_property(self, "scale", pressed_target, hoverfx_press_in_duration)
	_hoverfx_tween.tween_property(self, "scale", final_target,  hoverfx_press_out_duration)

func _hoverfx_animate_to(target: Vector2, new_z: int) -> void:
	z_index = new_z
	if _hoverfx_tween and _hoverfx_tween.is_running():
		_hoverfx_tween.kill()
	_hoverfx_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hoverfx_tween.tween_property(self, "scale", target, hoverfx_duration)
# ============================= end Hover/Pop FX ================================
