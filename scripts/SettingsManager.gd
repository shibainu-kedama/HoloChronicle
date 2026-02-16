extends Node

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "audio"

var _config := ConfigFile.new()

func _ready():
	_config.load(SETTINGS_PATH)
	_apply_volume("BGM", get_bgm_volume())
	_apply_volume("SE", get_se_volume())

func set_bgm_volume(db: float):
	_apply_volume("BGM", db)
	_config.set_value(SECTION, "bgm_volume", db)
	_config.save(SETTINGS_PATH)

func set_se_volume(db: float):
	_apply_volume("SE", db)
	_config.set_value(SECTION, "se_volume", db)
	_config.save(SETTINGS_PATH)

func get_bgm_volume() -> float:
	return _config.get_value(SECTION, "bgm_volume", -6.0)

func get_se_volume() -> float:
	return _config.get_value(SECTION, "se_volume", -6.0)

func _apply_volume(bus_name: String, db: float):
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, db)
