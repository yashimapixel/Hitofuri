extends Control
## ガチャ画面。宝箱が揺れる → 開く → レア度に応じて光の色が変わる。タップでスキップ。

@onready var chest: AnimatedSprite2D = %Chest
@onready var light: Sprite2D = %Light
@onready var tap_catcher: Control = %TapCatcher
@onready var buttons: VBoxContainer = %Buttons
@onready var rates_label: Label = %Rates

var _rng := RandomNumberGenerator.new()
var _anim: Tween


func _ready() -> void:
	_rng.randomize()
	%BackButton.pressed.connect(func() -> void:
		AudioService.play_se("button")
		UiUtil.go(get_tree(), "home"))
	tap_catcher.gui_input.connect(_on_tap_catcher)
	tap_catcher.hide()
	light.hide()
	chest.play(&"closed")
	var g := GameState.gacha
	var w := g.rarity_weights
	var total := 0.0
	for v: float in w:
		total += v
	var pct := func(v: float) -> String: return ("%.1f" % (v / total * 100.0)).trim_suffix(".0")
	rates_label.text = Text.GACHA_RATES % [pct.call(w[0]), pct.call(w[1]), pct.call(w[2]), str(roundi(g.sword_weight)), str(roundi(g.costume_weight))]
	SaveService.changed.connect(_refresh_buttons)
	_refresh_buttons()


func _refresh_buttons() -> void:
	UiUtil.clear_children(buttons)
	var g := GameState.gacha
	var b1 := UiUtil.button(Text.GACHA_SINGLE % g.single_cost, _pull.bind(1, "coins", g.single_cost))
	b1.disabled = SaveService.coins() < g.single_cost
	buttons.add_child(b1)
	var b10 := UiUtil.button(Text.GACHA_TEN % g.ten_cost, _pull.bind(10, "coins", g.ten_cost))
	b10.disabled = SaveService.coins() < g.ten_cost
	buttons.add_child(b10)
	var t := SaveService.item_count("tickets")
	var bt := UiUtil.button(Text.GACHA_TICKET % t, _pull.bind(1, "tickets", 1))
	bt.disabled = t <= 0
	buttons.add_child(bt)
	var t2 := SaveService.item_count("tickets_r2")
	if t2 > 0:
		buttons.add_child(UiUtil.button(Text.GACHA_TICKET_R2 % t2, _pull.bind(1, "tickets_r2", 1)))
	var t3 := SaveService.item_count("tickets_r3")
	if t3 > 0:
		buttons.add_child(UiUtil.button(Text.GACHA_TICKET_R3 % t3, _pull.bind(1, "tickets_r3", 1)))


func _pull(count: int, currency: String, cost: int) -> void:
	if _anim != null and _anim.is_running():
		return
	if currency == "coins":
		if not SaveService.try_spend_coins(cost):
			UiUtil.toast(self, Text.NOT_ENOUGH_COINS)
			return
	else:
		if SaveService.item_count(currency) < cost:
			return
		SaveService.add_item(currency, -cost)
	var min_rarity := 3 if currency == "tickets_r3" else (2 if currency == "tickets_r2" else 1)
	var results: Array[Dictionary] = []
	var best := 1
	for i in count:
		var r := GachaSystem.roll(min_rarity, _rng)
		results.append(r)
		best = maxi(best, int(r.rarity))
	DailyService.add_progress(MissionData.Stat.GACHA, count)
	SaveService.save_game()
	await _play_animation(best)
	await _show_results(results)
	chest.play(&"closed")
	light.hide()


func _play_animation(rarity: int) -> void:
	var g := GameState.gacha
	buttons.hide()
	tap_catcher.show()
	chest.play(&"closed")
	chest.rotation = 0.0
	light.hide()
	_anim = create_tween()
	var steps := 8
	for i in steps:
		var a := deg_to_rad(8.0 if i % 2 == 0 else -8.0) * (1.0 + i / float(steps))
		_anim.tween_callback(AudioService.play_se.bind("chest_shake", 1.0))
		_anim.tween_property(chest, "rotation", a, g.shake_sec / steps)
	_anim.tween_property(chest, "rotation", 0.0, 0.05)
	_anim.tween_callback(_open_chest.bind(rarity))
	_anim.tween_property(light, "scale", Vector2(3.5, 3.5), g.open_sec).from(Vector2(0.5, 0.5))
	_anim.parallel().tween_property(light, "modulate:a", 1.0, g.open_sec * 0.5).from(0.0)
	_anim.tween_interval(0.3)
	await _anim.finished
	tap_catcher.hide()
	buttons.show()


func _open_chest(rarity: int) -> void:
	chest.play(&"open")
	light.self_modulate = GameState.gacha.rarity_light_colors[clampi(rarity - 1, 0, 2)]
	light.show()
	AudioService.play_se("gacha_%d" % clampi(rarity, 1, 3))


func _on_tap_catcher(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	var mouse := event as InputEventMouseButton
	if (touch != null and touch.pressed) or (mouse != null and mouse.pressed):
		if _anim != null and _anim.is_running():
			_anim.custom_step(100.0)


func _show_results(results: Array[Dictionary]) -> void:
	var m := Modal.open(self, Text.GACHA_TITLE, 320)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 2)
	m.content.add_child(list)
	var small := results.size() > 3
	for r: Dictionary in results:
		var h := HBoxContainer.new()
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(16, 16)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		if r.kind == "sword":
			icon.texture = (r.item as SwordData).icon
		else:
			icon.texture = preload("res://assets/ui/star.png")
			icon.self_modulate = (r.item as CostumeData).primary_color
		h.add_child(icon)
		var kind := Text.SWORD if r.kind == "sword" else Text.COSTUME
		var name_label := UiUtil.label("%s %s %s" % [UiUtil.stars(int(r.rarity)), kind, r.item.display_name], &"SmallLabel" if small else &"")
		name_label.self_modulate = UiUtil.rarity_color(int(r.rarity))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(name_label)
		var outcome := ""
		match r.outcome:
			"new":
				outcome = Text.GACHA_NEW
			"levelup":
				outcome = Text.GACHA_LEVEL_UP % int(r.level)
			"convert":
				outcome = Text.GACHA_CONVERT % int(r.coins)
		h.add_child(UiUtil.label(outcome, &"SmallLabel"))
		list.add_child(h)
	m.add_close_button(Text.OK)
	await m.closed
