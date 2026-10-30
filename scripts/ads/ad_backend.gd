class_name AdBackend
extends Node
## 広告バックエンドの共通インターフェース。
## 終了時に finished(AdService.Result) を必ず 1 回 emit すること。

@warning_ignore("unused_signal")
signal finished(result: int)


func initialize() -> void:
	pass


func is_rewarded_ready() -> bool:
	return false


func show_rewarded(_placement: String) -> void:
	finished.emit(AdService.Result.ERROR)
