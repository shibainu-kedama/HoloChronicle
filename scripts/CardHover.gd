# CardHover.gd（CardTexture 用）
extends TextureRect

@export var hover_scale: float = 1.5       # ホバー時の倍率
@export var duration: float = 0.08          # 拡大/縮小の所要時間
@export var hover_z: int = 20               # ホバー時のz_index
@export var enable_pop_on_click := true     # クリック“ポン”を有効にする
@export var press_shrink_ratio := 0.94      # 一瞬縮む比率（0.90〜0.96で調整）
@export var press_in_duration := 0.04       # 縮む速さ
@export var press_out_duration := 0.10      # 戻る速さ

var _base_scale := Vector2.ONE
var _tween: Tween
var _is_hovered := false

func _ready() -> void:
	_base_scale = scale
	pivot_offset = size * 0.5
	resized.connect(func(): pivot_offset = size * 0.5)

	# ← 重要：クリックを受け取るため
	mouse_filter = Control.MOUSE_FILTER_STOP
	# キーボード(Enter/Space)でも反応させたい場合
	focus_mode = Control.FOCUS_ALL

	mouse_entered.connect(_on_hover_in)
	mouse_exited.connect(_on_hover_out)
	focus_entered.connect(_on_hover_in)
	focus_exited.connect(_on_hover_out)

func _gui_input(event: InputEvent) -> void:
	if not enable_pop_on_click:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_play_click_pop()
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
		_play_click_pop()

func _on_hover_in() -> void:
	_is_hovered = true
	_animate_to(_base_scale * hover_scale, hover_z)

func _on_hover_out() -> void:
	_is_hovered = false
	_animate_to(_base_scale, 0)

func _play_click_pop() -> void:
	var final_target := _base_scale * (hover_scale if _is_hovered else 1.0)
	var pressed_target := final_target * press_shrink_ratio

	if _tween and _tween.is_running():
		_tween.kill()

	if _is_hovered:
		z_index = hover_z

	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", pressed_target, press_in_duration)
	_tween.tween_property(self, "scale", final_target, press_out_duration)

func _animate_to(target: Vector2, new_z: int) -> void:
	z_index = new_z
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", target, duration)
