extends Node
## リワード広告の窓口。中身（バックエンド）を差し替えられる。
##   AdService.show_rewarded("result_double")
##   var result: AdService.Result = await AdService.rewarded_finished

enum Result { REWARDED, SKIPPED, ERROR }

signal rewarded_finished(result: Result)

## デバッグ用: モック広告が返す結果
var debug_mock_result: Result = Result.REWARDED

var _backend: AdBackend
var _was_paused := false
var _showing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	init_ads()


func init_ads() -> void:
	if _backend != null:
		return
	# 実機（mobile）で AdMob プラグインが入っていれば本番、そうでなければモック
	if OS.has_feature("mobile") and AdMobBackend.is_available():
		_backend = AdMobBackend.new()
	else:
		_backend = MockAdBackend.new()
	add_child(_backend)
	_backend.finished.connect(_on_backend_finished)
	_backend.initialize()


func is_rewarded_ready() -> bool:
	return _backend != null and _backend.is_rewarded_ready()


func show_rewarded(placement: String) -> void:
	if _showing:
		return
	if not is_rewarded_ready():
		rewarded_finished.emit.call_deferred(Result.ERROR)
		return
	_showing = true
	_was_paused = get_tree().paused
	get_tree().paused = true
	AudioService.set_ad_mute(true)
	_backend.show_rewarded(placement)


func _on_backend_finished(result: int) -> void:
	_showing = false
	get_tree().paused = _was_paused
	AudioService.set_ad_mute(false)
	rewarded_finished.emit.call_deferred(result as Result)
