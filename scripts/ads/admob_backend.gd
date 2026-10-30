class_name AdMobBackend
extends AdBackend
## 本番の AdMob バックエンド（M6 で導入するプラグインに合わせて実装する）。
##
## 手順は README の「AdMob の導入」を参照。プラグインのシングルトンが見つからない場合は
## is_available() が false を返し、AdService はモックを使う。
##
## ここではテスト用のリワード広告ユニット ID を既定値にしている（Google 公式のテスト ID）。

const PLUGIN_SINGLETON := "AdMob"
const TEST_REWARDED_ANDROID := "ca-app-pub-3940256099942544/5224354917"
const TEST_REWARDED_IOS := "ca-app-pub-3940256099942544/1712485313"

var _plugin: Object
var _loaded := false


static func is_available() -> bool:
	return Engine.has_singleton(PLUGIN_SINGLETON)


func initialize() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_plugin = Engine.get_singleton(PLUGIN_SINGLETON)
	# TODO(M6): プラグインの初期化 API と、ロード完了/報酬獲得/閉じた/失敗 のシグナルを接続する。
	#   例) _plugin.initialize(); _plugin.connect("rewarded_ad_loaded", _on_loaded) ...
	#   報酬獲得 → finished.emit(AdService.Result.REWARDED)
	#   報酬なしで閉じた → finished.emit(AdService.Result.SKIPPED)
	#   失敗 → finished.emit(AdService.Result.ERROR)
	_load_ad()


func _unit_id() -> String:
	return TEST_REWARDED_IOS if OS.get_name() == "iOS" else TEST_REWARDED_ANDROID


func _load_ad() -> void:
	# TODO(M6): _plugin.load_rewarded(_unit_id())
	_loaded = false


func is_rewarded_ready() -> bool:
	return _loaded


func show_rewarded(_placement: String) -> void:
	# TODO(M6): _plugin.show_rewarded()
	finished.emit(AdService.Result.ERROR)
