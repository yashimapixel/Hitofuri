extends Control
## 設定画面（BGM / 効果音 / 振動）。デバッグビルドではデバッグ機能も出す。

@onready var list: VBoxContainer = %Content


func _ready() -> void:
	%BackButton.pressed.connect(func() -> void:
		AudioService.play_se("button")
		UiUtil.go(get_tree(), "home"))
	_build()


func _build() -> void:
	UiUtil.clear_children(list)
	list.add_child(_toggle(Text.BGM, SaveService.setting("bgm"), func(on: bool) -> void:
		SaveService.set_setting("bgm", on)
		AudioService.apply_settings()))
	list.add_child(_toggle(Text.SE, SaveService.setting("se"), func(on: bool) -> void:
		SaveService.set_setting("se", on)
		AudioService.apply_settings()))
	list.add_child(_toggle(Text.VIBRATION, SaveService.setting("vibration"), func(on: bool) -> void:
		SaveService.set_setting("vibration", on)
		HapticsService.vibrate(30)))
	if GameState.is_debug():
		_build_debug()


func _toggle(text: String, value: bool, on_toggled: Callable) -> Control:
	var c := CheckButton.new()
	c.text = text
	c.button_pressed = value
	c.focus_mode = Control.FOCUS_NONE
	c.toggled.connect(on_toggled)
	return c


func _build_debug() -> void:
	list.add_child(HSeparator.new())
	list.add_child(UiUtil.label(Text.DEBUG, &"SmallLabel"))
	var grid := GridContainer.new()
	grid.columns = 2
	list.add_child(grid)
	var add := func(text: String, cb: Callable) -> void:
		var b := UiUtil.button(text, cb)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(b)
	add.call(Text.DEBUG_COINS, func() -> void:
		SaveService.add_coins(10000)
		SaveService.save_game())
	add.call(Text.DEBUG_TICKETS, func() -> void:
		for k: String in ["tickets", "tickets_r2", "tickets_r3"]:
			SaveService.add_item(k, 5)
		SaveService.save_game())
	add.call(Text.DEBUG_UNLOCK, func() -> void:
		SaveService.data.unlocked_area = GameState.area_count()
		SaveService.data.endless_unlocked = true
		SaveService.save_game()
		UiUtil.toast(self, Text.DEBUG_UNLOCK))
	add.call(Text.DEBUG_NEXT_DAY, func() -> void:
		DailyService.debug_advance_day()
		UiUtil.toast(self, Text.DEBUG_NEXT_DAY))
	add.call(Text.DEBUG_RESET, func() -> void:
		SaveService.reset()
		DailyService.check_new_day()
		UiUtil.toast(self, Text.DEBUG_RESET)
		_build())
	list.add_child(_toggle(Text.DEBUG_JUDGE_VIS, GameState.debug_show_judge, func(on: bool) -> void:
		GameState.debug_show_judge = on))
	list.add_child(_toggle(Text.DEBUG_JUICE, GameState.juice.juice_enabled, func(on: bool) -> void:
		GameState.juice.juice_enabled = on))
	var h := HBoxContainer.new()
	var l := UiUtil.label(Text.DEBUG_AD_RESULT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var opt := OptionButton.new()
	opt.focus_mode = Control.FOCUS_NONE
	for k: String in AdService.Result.keys():
		opt.add_item(k)
	opt.selected = AdService.debug_mock_result
	opt.item_selected.connect(func(i: int) -> void: AdService.debug_mock_result = i as AdService.Result)
	h.add_child(opt)
	list.add_child(h)
