extends Node
## 起動直後の処理。Autoload の初期化を待ってタイトルへ。


func _ready() -> void:
	AdService.init_ads()
	await get_tree().process_frame
	UiUtil.go(get_tree(), "title")
