extends Control
## エリア選択。各エリアの最高到達階層を表示する。

@onready var list: VBoxContainer = %Content


func _ready() -> void:
	%BackButton.pressed.connect(func() -> void:
		AudioService.play_se("button")
		UiUtil.go(get_tree(), "home"))
	for a: AreaData in GameState.areas:
		list.add_child(_area_button(a))
	if bool(SaveService.data.endless_unlocked):
		var b := UiUtil.button("%s\n%s" % [Text.ENDLESS, Text.BEST_FLOOR % SaveService.best_floor(GameState.ENDLESS)], _start.bind(GameState.ENDLESS))
		b.custom_minimum_size = Vector2(0, 64)
		list.add_child(b)


func _area_button(a: AreaData) -> Button:
	var unlocked := a.index <= SaveService.unlocked_area()
	var status := Text.LOCKED
	if unlocked:
		status = Text.BEST_FLOOR % SaveService.best_floor(a.index)
		if SaveService.is_area_cleared(a.index):
			status += "  " + Text.CLEARED
	var b := UiUtil.button("%d. %s\n%s" % [a.index, a.display_name, status], _start.bind(a.index))
	b.disabled = not unlocked
	b.custom_minimum_size = Vector2(0, 64)
	return b


func _start(index: int) -> void:
	GameState.selected_area = index
	UiUtil.go(get_tree(), "game")
