extends Node
## 振動。設定で OFF にできる。


func vibrate(ms: int) -> void:
	if ms <= 0 or not SaveService.setting("vibration"):
		return
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)
