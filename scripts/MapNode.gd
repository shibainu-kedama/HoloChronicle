extends Button

var node_type: String = "none"

@onready var icon_texture: TextureRect = $IconTexture
@onready var label_type: Label = $Label_Type

func _ready():
	# クリック時の処理を接続（必要なら）
	connect("pressed", self._on_pressed)

# 外部から呼ばれる：ノードのタイプを設定し、見た目を更新
func set_type(t: String) -> void:
	node_type = t

	# ラベルにタイプ名を表示
	label_type.text = t.capitalize()

	# タイプに応じてアイコンを設定
	match t:
		"battle":
			icon_texture.texture = preload("res://icons/icon_battle.png")
		"rest":
			icon_texture.texture = preload("res://icons/icon_rest.png")
		"event":
			icon_texture.texture = preload("res://icons/icon_event.png")
		"boss":
			icon_texture.texture = preload("res://icons/icon_boss.png")
		_:
			icon_texture.texture = null  # 未定義時は非表示またはデフォルト

# ノードがクリックされたときの処理（必要に応じて拡張）
func _on_pressed():
	print("ノード [%s] が押されました（タイプ: %s）" % [name, node_type])
	
	if not Global.is_node_unlocked(name):
		print("ノード %s はまだロック中" % name)
		return
	
	# すでに通過済みなら何もしない
	if Global.passed_nodes.has(name):
		print("ノード %s はすでに通過済み" % name)
		return
	
	print("✅ ノード %s を通過しました" % name)
	Global.passed_nodes.append(name)
	
	# 最初に選んだ場合：他の 1-系ノードをロック
	if Global.unlocked_nodes.has("1-A") and Global.unlocked_nodes.has("1-B") and Global.unlocked_nodes.has("1-C"):
		print("🌟 初回選択 → 他の選択肢をロック")
		Global.unlocked_nodes = [name]  # 今選んだものだけ残す
	
	# 次ノードを解放
	Global.unlock_next_nodes(name)
	
	print("現在のunlocked_nodes:", Global.unlocked_nodes)
	
	# マップ画面のボタン状態を更新
	var map_scene = get_tree().get_current_scene()
	if map_scene.has_method("update_node_interactability"):
		map_scene.update_node_interactability()
		
	# ここで現在ステージ種別をセット
	Global.set_stage_type_from_string(node_type)
	
	# MapScene にインタラクト更新を依頼（親 or 上位シーンから探す）
	match node_type:
		"battle":
			get_tree().change_scene_to_file("res://scenes/BattleScene.tscn")
		"rest":
			get_tree().change_scene_to_file("res://scenes/RestScene.tscn")
		"event":
			get_tree().change_scene_to_file("res://scenes/EventScene.tscn")
		"boss":
			get_tree().change_scene_to_file("res://scenes/BattleScene.tscn")
		_:
			print("未定義のタイプ: ", node_type)

func set_passed_visual(passed: bool) -> void:
	if passed:
		icon_texture.modulate = Color(0.5, 0.5, 0.5)  # 暗め
		label_type.modulate = Color(0.6, 0.6, 0.6)
	else:
		icon_texture.modulate = Color(1, 1, 1)
		label_type.modulate = Color(1, 1, 1)

func play_attention_animation():
	if get_meta("is_animating") == true:
		return
	set_meta("is_animating", true)

	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.4)
	tween.tween_property(self, "scale", Vector2.ONE, 0.4)
