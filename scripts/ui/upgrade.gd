extends Control
## 強化画面。「現在値 → 次Lvの値」とコストを表示する。

@onready var list: VBoxContainer = %Content


func _ready() -> void:
	%BackButton.pressed.connect(func() -> void:
		AudioService.play_se("button")
		UiUtil.go(get_tree(), "home"))
	_refresh()


func _refresh() -> void:
	UiUtil.clear_children(list)
	for u: UpgradeData in GameState.upgrades.upgrades:
		list.add_child(_row(u))


func _row(u: UpgradeData) -> Control:
	var lv := SaveService.upgrade_level(u.id)
	var maxed := lv >= u.max_level()
	var panel := PanelContainer.new()
	var h := HBoxContainer.new()
	panel.add_child(h)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 1)
	info.add_child(UiUtil.label("%s  %s/%d" % [u.display_name, Text.LEVEL % lv, u.max_level()]))
	info.add_child(UiUtil.label(u.description, &"SmallLabel"))
	var change := u.format_value(lv) if maxed else "%s → %s" % [u.format_value(lv), u.format_value(lv + 1)]
	info.add_child(UiUtil.label(change))
	h.add_child(info)
	var b: Button
	if maxed:
		b = UiUtil.button(Text.MAX_LEVEL, func() -> void: pass)
		b.disabled = true
	else:
		var cost := u.costs[lv]
		b = UiUtil.button("%d\nコイン" % cost, _buy.bind(u))
		b.disabled = SaveService.coins() < cost
	b.custom_minimum_size = Vector2(80, 0)
	h.add_child(b)
	return panel


func _buy(u: UpgradeData) -> void:
	var lv := SaveService.upgrade_level(u.id)
	if lv >= u.max_level():
		return
	if not SaveService.try_spend_coins(u.costs[lv]):
		UiUtil.toast(self, Text.NOT_ENOUGH_COINS)
		return
	SaveService.set_upgrade_level(u.id, lv + 1)
	DailyService.add_progress(MissionData.Stat.UPGRADE, 1)
	SaveService.save_game()
	AudioService.play_se("heal")
	_refresh()
