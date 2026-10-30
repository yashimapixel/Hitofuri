extends Control
## 装備画面（剣・衣装）。

@onready var list: VBoxContainer = %Content
@onready var heroine: Heroine = %Heroine
@onready var sword_tab: Button = %SwordTab
@onready var costume_tab: Button = %CostumeTab
@onready var detail: Label = %Detail

var _tab := "sword"


func _ready() -> void:
	%BackButton.pressed.connect(func() -> void:
		AudioService.play_se("button")
		UiUtil.go(get_tree(), "home"))
	sword_tab.pressed.connect(_set_tab.bind("sword"))
	costume_tab.pressed.connect(_set_tab.bind("costume"))
	_refresh()


func _set_tab(t: String) -> void:
	AudioService.play_se("button")
	_tab = t
	_refresh()


func _refresh() -> void:
	sword_tab.disabled = _tab == "sword"
	costume_tab.disabled = _tab == "costume"
	heroine.apply_costume(GameState.equipped_costume())
	var s := GameState.equipped_sword()
	detail.text = "%s %s Lv%d\n%s" % [UiUtil.stars(s.rarity), s.display_name, GameState.equipped_sword_level(), s.describe(GameState.equipped_sword_level())]
	UiUtil.clear_children(list)
	if _tab == "sword":
		for sw: SwordData in GameState.swords:
			list.add_child(_sword_row(sw))
	else:
		for c: CostumeData in GameState.costumes:
			list.add_child(_costume_row(c))


func _sword_row(s: SwordData) -> Control:
	var lv := SaveService.sword_level(s.id)
	var owned := lv > 0
	var equipped := String(s.id) == String(SaveService.data.equipped_sword)
	var panel := PanelContainer.new()
	var h := HBoxContainer.new()
	panel.add_child(h)
	var icon := TextureRect.new()
	icon.texture = s.icon
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.custom_minimum_size = Vector2(20, 20)
	icon.modulate = Color.WHITE if owned else Color(0, 0, 0, 0.6)
	h.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	var name_label := UiUtil.label("%s %s" % [UiUtil.stars(s.rarity), s.display_name if owned else "？？？"] + ("  Lv%d" % lv if owned else ""))
	name_label.self_modulate = UiUtil.rarity_color(s.rarity)
	info.add_child(name_label)
	if owned:
		info.add_child(UiUtil.label(s.describe(lv), &"SmallLabel"))
	h.add_child(info)
	var b := UiUtil.button(Text.EQUIPPED if equipped else Text.EQUIP, func() -> void:
		SaveService.data.equipped_sword = String(s.id)
		SaveService.save_game()
		_refresh())
	b.disabled = equipped or not owned
	b.custom_minimum_size = Vector2(64, 0)
	h.add_child(b)
	return panel


func _costume_row(c: CostumeData) -> Control:
	var owned := SaveService.has_costume(c.id)
	var equipped := String(c.id) == String(SaveService.data.equipped_costume)
	var panel := PanelContainer.new()
	var h := HBoxContainer.new()
	panel.add_child(h)
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(16, 16)
	swatch.color = c.primary_color if owned else Color(0.2, 0.2, 0.2)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(swatch)
	var name_label := UiUtil.label("%s %s" % [UiUtil.stars(c.rarity), c.display_name if owned else "？？？"])
	name_label.self_modulate = UiUtil.rarity_color(c.rarity)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(name_label)
	var b := UiUtil.button(Text.EQUIPPED if equipped else Text.EQUIP, func() -> void:
		SaveService.data.equipped_costume = String(c.id)
		SaveService.save_game()
		_refresh())
	b.disabled = equipped or not owned
	b.custom_minimum_size = Vector2(64, 0)
	h.add_child(b)
	return panel
