extends PanelContainer

@onready var item_container: VBoxContainer = $VBoxContainer

func _ready() -> void:
	var goods := Global.player_goods
	if goods.is_empty():
		visible = false
		return

	for g in goods:
		var label := Label.new()
		label.text = "■ " + g.name
		label.add_theme_font_size_override("font_size", 14)
		item_container.add_child(label)
