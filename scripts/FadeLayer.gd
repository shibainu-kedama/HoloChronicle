extends CanvasLayer

signal fade_in_finished
signal fade_out_finished

@onready var color_rect: ColorRect = $ColorRect
@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# 初期状態では入力を無視して、ボタンが押せるようにしておく
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _set_block_input(block: bool) -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP if block else Control.MOUSE_FILTER_IGNORE


func fade_in() -> void:
	_set_block_input(true)              # フェード中はクリック無効
	anim.play("fade_in")
	await anim.animation_finished
	_set_block_input(false)             # 終わったらクリック有効
	emit_signal("fade_in_finished")


func fade_out() -> void:
	_set_block_input(true)              # 黒くしてる間はクリック無効
	anim.play("fade_out")
	await anim.animation_finished
	emit_signal("fade_out_finished")


func change_scene_with_fade(path: String) -> void:
	await fade_out()
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await fade_in()
