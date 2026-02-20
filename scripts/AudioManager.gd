## AudioManager.gd
## BGM・SE の一元管理シングルトン。
## 実音声ファイル（res://audio/）があれば自動ロード、なければプロシージャル音で代替。
extends Node

# --- BGM ---
var _bgm_player: AudioStreamPlayer

# --- SE プール（同時発音数分） ---
const SE_POOL_SIZE := 8
var _se_pool: Array[AudioStreamPlayer] = []

# --- 生成済みサウンドキャッシュ ---
var _sounds: Dictionary = {}

# --- 現在のBGMパス（重複再生防止） ---
var _current_bgm_path := ""

func _ready() -> void:
	_setup_bgm_player()
	_setup_se_pool()
	_build_sounds()

# ============================================================
#  公開 API
# ============================================================

## BGM をファイルパスで再生。同じファイルが既に流れていれば何もしない。
## ファイルが存在しない場合は静かにスキップ。
func play_bgm(path: String) -> void:
	if path == _current_bgm_path and _bgm_player.playing:
		return
	if not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	_current_bgm_path = path
	_bgm_player.stream = stream
	_bgm_player.play()

## BGM を停止する。
func stop_bgm() -> void:
	_bgm_player.stop()
	_current_bgm_path = ""

## 登録されたSEを名前で再生する。
func play_se(name: String) -> void:
	if not _sounds.has(name):
		return
	var player := _get_free_se_player()
	player.stream = _sounds[name]
	player.play()

# ============================================================
#  内部セットアップ
# ============================================================

func _setup_bgm_player() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "BGM"
	_bgm_player.volume_db = 0.0
	add_child(_bgm_player)

func _setup_se_pool() -> void:
	for i in range(SE_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "SE"
		add_child(p)
		_se_pool.append(p)

func _get_free_se_player() -> AudioStreamPlayer:
	for p in _se_pool:
		if not p.playing:
			return p
	return _se_pool[0]   # 全話中なら先頭を上書き

# ============================================================
#  サウンド登録（実ファイル優先、なければプロシージャル）
# ============================================================

func _build_sounds() -> void:
	# 実ファイルがあればそれを使い、なければコード生成音を登録
	_reg("card_play",   "res://audio/se_card_play.ogg",   _make_sweep(300.0, 640.0, 0.16, 0.45))
	_reg("card_draw",   "res://audio/se_card_draw.ogg",   _make_sweep(420.0, 720.0, 0.10, 0.30))
	_reg("attack",      "res://audio/se_attack.ogg",      _make_impact(0.14, 0.55))
	_reg("hit_enemy",   "res://audio/se_hit_enemy.ogg",   _make_impact(0.10, 0.60))
	_reg("hit_player",  "res://audio/se_hit_player.ogg",  _make_impact(0.20, 0.45))
	_reg("block",       "res://audio/se_block.ogg",       _make_sine(180.0, 0.18, 0.50))
	_reg("heal",        "res://audio/se_heal.ogg",        _make_sweep(440.0, 660.0, 0.28, 0.40))
	_reg("enemy_die",   "res://audio/se_enemy_die.ogg",   _make_sweep(300.0, 120.0, 0.30, 0.50))
	_reg("card_draw_turn","res://audio/se_card_draw.ogg", _make_sweep(380.0, 600.0, 0.12, 0.25))
	_reg("turn_end",    "res://audio/se_turn_end.ogg",    _make_sine(330.0, 0.14, 0.35))
	_reg("victory",     "res://audio/se_victory.ogg",     _make_sweep(350.0, 900.0, 0.55, 0.60))
	_reg("defeat",      "res://audio/se_defeat.ogg",      _make_sweep(350.0, 160.0, 0.55, 0.50))
	_reg("button_click","res://audio/se_button_click.ogg",_make_sine(640.0, 0.06, 0.30))
	_reg("poison_tick", "res://audio/se_poison.ogg",      _make_sine(260.0, 0.12, 0.35))

func _reg(name: String, path: String, fallback: AudioStreamWAV) -> void:
	if ResourceLoader.exists(path):
		_sounds[name] = load(path)
	else:
		_sounds[name] = fallback

# ============================================================
#  プロシージャル音生成ヘルパー
# ============================================================

const _SAMPLE_RATE := 22050

## サイン波（シンプルなトーン）
func _make_sine(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var n := int(_SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var env := 1.0 - float(i) / n                        # linear fade-out
		var v := int(sin(float(i) / _SAMPLE_RATE * TAU * freq) * env * volume * 32767)
		v = clampi(v, -32768, 32767)
		data[i * 2]     = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	return _to_wav(data)

## サイン波スイープ（音程が変化するトーン）
func _make_sweep(f0: float, f1: float, duration: float, volume: float) -> AudioStreamWAV:
	var n := int(_SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in range(n):
		var p   := float(i) / n
		var freq := lerpf(f0, f1, p)
		phase += TAU * freq / _SAMPLE_RATE
		var env := sin(p * PI)                                # bell curve
		var v := int(sin(phase) * env * volume * 32767)
		v = clampi(v, -32768, 32767)
		data[i * 2]     = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	return _to_wav(data)

## ノイズ＋低音サイン合成（打撃音）
func _make_impact(duration: float, volume: float) -> AudioStreamWAV:
	var n := int(_SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var p   := float(i) / n
		var env := exp(-p * 14.0)                            # sharp exponential decay
		var noise := randf_range(-1.0, 1.0)
		var tone  := sin(float(i) / _SAMPLE_RATE * TAU * 90.0)  # 90 Hz thump
		var mixed := (noise * 0.55 + tone * 0.45) * env * volume
		var v := clampi(int(mixed * 32767), -32768, 32767)
		data[i * 2]     = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	return _to_wav(data)

func _to_wav(data: PackedByteArray) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.data       = data
	s.format     = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate   = _SAMPLE_RATE
	s.stereo     = false
	return s
