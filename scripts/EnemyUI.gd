extends Control
class_name EnemyUI

const STATUS_DESCRIPTIONS := {
	"weak": "脱力：与ダメージが25%減少",
	"vulnerable": "脆弱：被ダメージが50%増加",
	"strength": "筋力：攻撃ダメージが増加",
	"poison": "毒：ターン開始時にスタック分ダメージ（1ずつ減少）",
}

@onready var enemy_hp_bar = $VBoxContainer/EnemyHPBar
@onready var enemy_hp_label = $VBoxContainer/EnemyHPLabel
@onready var intent_label = $VBoxContainer/EnemyIntentLabel
@onready var name_label = $VBoxContainer/EnemyNameLabel
@onready var block_label = $VBoxContainer/EnemyBlockLabel
@onready var status_label = $VBoxContainer/EnemyStatusLabel

# 敵名を表示
func set_enemy_name(enemy_name: String) -> void:
	name_label.text = enemy_name

# 敵HPバーの最大値・現在値をセット
func initialize_hp(max_hp: int) -> void:
	enemy_hp_bar.max_value = max_hp
	enemy_hp_bar.value = max_hp
	_update_hp_label()

# 敵の現在HPを更新
func set_hp(current_hp: int) -> void:
	enemy_hp_bar.value = current_hp
	_update_hp_label()

func set_block(block_amount: int) -> void:
	if block_label:
		block_label.text = "ブロック: %d" % block_amount

# 次の行動の内容をラベルに反映
func set_intent(intent: Dictionary) -> void:
	var text := ""
	match intent.get("type", ""):
		"attack":
			text = "攻撃（%d）" % intent.get("power", 0)
		"multi_attack":
			text = "連撃（%d x %d）" % [intent.get("power", 0), intent.get("times", 0)]
		"buff":
			text = "バフ準備中"
		"debuff":
			text = "デバフ準備中"
		"block":
			text = "防御（+%d）" % intent.get("power", 0)
		_:
			text = "？？？"

	intent_label.text = text

func _ready() -> void:
	if status_label:
		status_label.mouse_filter = Control.MOUSE_FILTER_STOP

func set_statuses(statuses: Dictionary) -> void:
	if status_label:
		status_label.text = format_statuses(statuses)
		# ステータスツールチップ構築
		var tip_parts: Array[String] = []
		for key in statuses:
			if statuses[key] > 0 and STATUS_DESCRIPTIONS.has(key):
				tip_parts.append(STATUS_DESCRIPTIONS[key])
		status_label.tooltip_text = "\n".join(tip_parts)

static func format_statuses(statuses: Dictionary) -> String:
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
	return " ".join(parts)

func _update_hp_label() -> void:
	if enemy_hp_label:
		enemy_hp_label.text = "HP: %d / %d" % [int(enemy_hp_bar.value), int(enemy_hp_bar.max_value)]
