extends Control

@onready var enemy_hp_bar = $VBoxContainer/EnemyHPBar
@onready var intent_label = $VBoxContainer/EnemyIntentLabel

# 敵HPバーの最大値・現在値をセット
func initialize_hp(max_hp: int) -> void:
	enemy_hp_bar.max_value = max_hp
	enemy_hp_bar.value = max_hp

# 敵の現在HPを更新
func set_hp(current_hp: int) -> void:
	enemy_hp_bar.value = current_hp

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
		_:
			text = "？？？"

	intent_label.text = text
