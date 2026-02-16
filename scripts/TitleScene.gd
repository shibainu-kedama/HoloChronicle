extends Control

@onready var title_logo: TextureRect = $TitleLogo
@onready var start_button: Button = $ButtonContainer/StartButton
@onready var settings_button: Button = $ButtonContainer/SettingsButton
@onready var quit_button: Button = $ButtonContainer/QuitButton
@onready var settings_popup: PopupPanel = $SettingsPopup
@onready var bgm_slider: HSlider = $SettingsPopup/MarginContainer/VBoxContainer/BGMSlider
@onready var se_slider: HSlider = $SettingsPopup/MarginContainer/VBoxContainer/SESlider
@onready var close_settings_button: Button = $SettingsPopup/MarginContainer/VBoxContainer/CloseButton
@onready var quit_confirm_dialog: ConfirmationDialog = $QuitConfirmDialog

func _ready() -> void:
	Global.reset_run_state()

	# ボタンシグナル接続
	start_button.pressed.connect(_on_start_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	close_settings_button.pressed.connect(_on_close_settings_pressed)
	quit_confirm_dialog.confirmed.connect(_on_quit_confirmed)

	# 音量スライダーシグナル
	bgm_slider.value_changed.connect(_on_bgm_volume_changed)
	se_slider.value_changed.connect(_on_se_volume_changed)

	# 音量スライダー初期値をSettingsManagerから取得
	bgm_slider.value = SettingsManager.get_bgm_volume()
	se_slider.value = SettingsManager.get_se_volume()

	# フォーカス設定（キーボード/ゲームパッド対応）
	start_button.focus_neighbor_top = start_button.get_path()
	quit_button.focus_neighbor_bottom = quit_button.get_path()
	start_button.grab_focus()

	# ボタンhover/focus演出
	_setup_button_hover(start_button)
	_setup_button_hover(settings_button)
	_setup_button_hover(quit_button)

	# フェードイン
	FadeLayer.fade_in()

	# タイトルロゴ呼吸アニメーション開始
	_start_breathing_animation()

func _start_breathing_animation() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(title_logo, "scale", Vector2(1.03, 1.03), 1.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(title_logo, "scale", Vector2(1.0, 1.0), 1.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# pivot_offsetを中央に設定（スケールが中心基準になるように）
	title_logo.pivot_offset = title_logo.size / 2.0

func _setup_button_hover(button: Button) -> void:
	button.mouse_entered.connect(func(): _animate_button_scale(button, 1.1))
	button.mouse_exited.connect(func(): _animate_button_scale(button, 1.0))
	button.focus_entered.connect(func(): _animate_button_scale(button, 1.1))
	button.focus_exited.connect(func(): _animate_button_scale(button, 1.0))
	button.pivot_offset = button.size / 2.0

func _animate_button_scale(button: Button, target_scale: float) -> void:
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(target_scale, target_scale), 0.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_start_button_pressed() -> void:
	await FadeLayer.change_scene_with_fade("res://scenes/CharacterSelectScene.tscn")

func _on_settings_button_pressed() -> void:
	settings_popup.popup_centered()

func _on_quit_button_pressed() -> void:
	quit_confirm_dialog.popup_centered()

func _on_close_settings_pressed() -> void:
	settings_popup.hide()

func _on_quit_confirmed() -> void:
	get_tree().quit()

func _on_bgm_volume_changed(value: float) -> void:
	SettingsManager.set_bgm_volume(value)

func _on_se_volume_changed(value: float) -> void:
	SettingsManager.set_se_volume(value)
