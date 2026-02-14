extends Control

@onready var label = $Label

func show_damage(amount: int):
	label.text = str(amount)
	scale = Vector2.ONE
	modulate = Color(1, 1, 1, 1)
	position.y += 10  # 少し下から始めると自然

	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 30, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): queue_free())
