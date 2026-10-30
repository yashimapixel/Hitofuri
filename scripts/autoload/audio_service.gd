extends Node
## キー名で SE / BGM を再生する。
## res://assets/sfx/<key>.(ogg|wav|mp3) と res://assets/bgm/<key>.(ogg|wav|mp3) を探して使う。
## 本番素材は同じキー名のファイルを置くだけで差し替わる。

const SE_POOL_SIZE := 8
const EXTS := ["ogg", "wav", "mp3"]

var _se_players: Array[AudioStreamPlayer] = []
var _se_index := 0
var _bgm: AudioStreamPlayer
var _bgm_key := ""
var _cache: Dictionary = {}
var _ad_mute := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in SE_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = &"SE"
		add_child(p)
		_se_players.append(p)
	_bgm = AudioStreamPlayer.new()
	_bgm.bus = &"BGM"
	_bgm.finished.connect(_on_bgm_finished)
	add_child(_bgm)
	apply_settings()


func apply_settings() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"BGM"), not SaveService.setting("bgm") or _ad_mute)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"SE"), not SaveService.setting("se") or _ad_mute)


## 広告表示中は音を止める
func set_ad_mute(on: bool) -> void:
	_ad_mute = on
	apply_settings()


func _find(dir: String, key: String) -> AudioStream:
	var cache_key := dir + key
	if _cache.has(cache_key):
		return _cache[cache_key]
	var stream: AudioStream = null
	for ext: String in EXTS:
		var path := "res://assets/%s/%s.%s" % [dir, key, ext]
		if ResourceLoader.exists(path):
			stream = load(path)
			break
	_cache[cache_key] = stream
	return stream


func play_se(key: String, pitch: float = 1.0) -> void:
	var s := _find("sfx", key)
	if s == null:
		return
	var p := _se_players[_se_index]
	_se_index = (_se_index + 1) % _se_players.size()
	p.stream = s
	p.pitch_scale = pitch
	p.play()


func play_bgm(key: String) -> void:
	if key == _bgm_key and _bgm.playing:
		return
	_bgm_key = key
	var s := _find("bgm", key)
	_bgm.stop()
	if s == null:
		return
	if s is AudioStreamOggVorbis or s is AudioStreamMP3:
		s.set("loop", true)
	_bgm.stream = s
	_bgm.play()


func stop_bgm() -> void:
	_bgm_key = ""
	_bgm.stop()


func _on_bgm_finished() -> void:
	# ループ設定のない WAV でも途切れないように頭から再生し直す
	if _bgm_key != "":
		_bgm.play()
