extends Control
## Home 画面。立ち絵と吹き出しのセリフ、出撃・強化・ガチャ・装備・ミッション・設定への入口。
## その日の初回表示時にログインボーナスを出す。

## セリフを自動で切り替える間隔（秒）
const LINE_INTERVAL := 7.0

@onready var portrait: TextureRect = %Portrait
@onready var bubble: PanelContainer = %Bubble
@onready var bubble_label: Label = %BubbleLabel
@onready var bubble_tail: TextureRect = %Tail
@onready var mission_button: Button = %MissionButton
@onready var mission_badge: TextureRect = %MissionBadge

var _line_index := -1
var _line_timer: Timer


func _ready() -> void:
	var costume := GameState.equipped_costume()
	portrait.texture = costume.get_portrait()
	portrait.material = costume.make_material()
	portrait.gui_input.connect(_on_portrait_input)
	%SortieButton.pressed.connect(_go.bind("area_select"))
	%UpgradeButton.pressed.connect(_go.bind("upgrade"))
	%GachaButton.pressed.connect(_go.bind("gacha"))
	%EquipButton.pressed.connect(_go.bind("equip"))
	mission_button.pressed.connect(_open_missions)
	DailyService.check_new_day()
	DailyService.missions_changed.connect(_refresh_badge)
	DailyService.day_changed.connect(_on_day_changed)
	AudioService.play_bgm("home")
	_refresh_badge()
	_line_timer = Timer.new()
	_line_timer.wait_time = LINE_INTERVAL
	_line_timer.timeout.connect(_next_line)
	add_child(_line_timer)
	_line_timer.start()
	_next_line()
	_show_startup_dialogs.call_deferred()


func _go(scene: String) -> void:
	AudioService.play_se("button")
	UiUtil.go(get_tree(), scene)


func _refresh_badge() -> void:
	mission_badge.visible = DailyService.has_claimable()


func _on_day_changed() -> void:
	_refresh_badge()
	if DailyService.has_pending_login_bonus():
		_show_login_bonus()


func _show_startup_dialogs() -> void:
	if DailyService.has_pending_login_bonus():
		await _show_login_bonus()


# ---------------------------------------------------------------- 吹き出し

func _next_line() -> void:
	var lines: PackedStringArray = Text.HOME_LINES
	if lines.is_empty():
		bubble.hide()
		bubble_tail.hide()
		return
	var i := randi() % lines.size()
	if lines.size() > 1 and i == _line_index:
		i = (i + 1) % lines.size()
	_line_index = i
	bubble_label.text = lines[i]
	bubble.pivot_offset = Vector2(bubble.size.x * 0.3, bubble.size.y)
	bubble.scale = Vector2(0.85, 0.85)
	var tw := create_tween()
	tw.tween_property(bubble, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_portrait_input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	var mouse := event as InputEventMouseButton
	if (touch != null and touch.pressed) or (mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT):
		AudioService.play_se("button")
		_line_timer.start()
		_next_line()
		var tw := create_tween()
		portrait.pivot_offset = Vector2(portrait.size.x / 2.0, portrait.size.y)
		tw.tween_property(portrait, "scale", Vector2(1.0, 0.97), 0.06)
		tw.tween_property(portrait, "scale", Vector2.ONE, 0.08)


# ---------------------------------------------------------------- ログインボーナス

func _show_login_bonus() -> void:
	var reward := DailyService.claim_login_bonus()
	var total := DailyService.total_login_days()
	var m := Modal.open(self, Text.LOGIN_BONUS, 340)
	m.content.add_child(UiUtil.label(Text.LOGIN_DAY % total, &"", HORIZONTAL_ALIGNMENT_CENTER))
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	var table := GameState.login_bonus
	var cycle_start := total - int(reward.day) + 1
	for i in table.cycle_length():
		var r := table.reward_for(cycle_start + i)
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(40, 44)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		cell.add_child(v)
		v.add_child(UiUtil.label("%d" % (i + 1), &"SmallLabel", HORIZONTAL_ALIGNMENT_CENTER))
		v.add_child(UiUtil.label(_reward_short(r), &"SmallLabel", HORIZONTAL_ALIGNMENT_CENTER))
		if i + 1 < int(reward.day):
			cell.modulate = Color(0.5, 0.5, 0.5)
		elif i + 1 == int(reward.day):
			cell.modulate = Color(1.0, 0.9, 0.5)
		grid.add_child(cell)
	m.content.add_child(grid)
	m.content.add_child(UiUtil.label(_reward_text(reward), &"TitleLabel", HORIZONTAL_ALIGNMENT_CENTER))
	m.add_close_button(Text.OK)
	AudioService.play_se("coin")
	await m.closed


func _reward_short(r: Dictionary) -> String:
	match int(r.type):
		LoginBonusTable.RewardType.COIN:
			return str(r.amount)
		LoginBonusTable.RewardType.TICKET:
			return "券"
		LoginBonusTable.RewardType.TICKET_R2:
			return "★2"
		LoginBonusTable.RewardType.TICKET_R3:
			return "★3"
	return ""


func _reward_text(r: Dictionary) -> String:
	match int(r.type):
		LoginBonusTable.RewardType.COIN:
			return Text.REWARD_COIN % int(r.amount)
		LoginBonusTable.RewardType.TICKET:
			return "%s×%d" % [Text.REWARD_TICKET, int(r.amount)]
		LoginBonusTable.RewardType.TICKET_R2:
			return "%sチケット×%d" % [Text.REWARD_TICKET_R2, int(r.amount)]
		LoginBonusTable.RewardType.TICKET_R3:
			return "%sチケット×%d" % [Text.REWARD_TICKET_R3, int(r.amount)]
	return ""


# ---------------------------------------------------------------- ミッション

func _open_missions() -> void:
	AudioService.play_se("button")
	var m := Modal.open(self, Text.MISSION_TITLE, 340)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	m.content.add_child(list)
	m.content.add_child(UiUtil.label(Text.MISSION_RESET % GameState.config.day_reset_hour, &"SmallLabel", HORIZONTAL_ALIGNMENT_CENTER))
	m.add_close_button()
	_fill_missions(list)


func _fill_missions(list: VBoxContainer) -> void:
	UiUtil.clear_children(list)
	var entries := DailyService.missions()
	for i in entries.size():
		var e: Dictionary = entries[i]
		var md := DailyService.mission_data(e)
		if md == null:
			continue
		var row := HBoxContainer.new()
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 0)
		info.add_child(UiUtil.label(md.describe()))
		info.add_child(UiUtil.label("%d / %d   報酬 %dコイン" % [int(e.progress), md.target, GameState.missions.reward_coin], &"SmallLabel"))
		row.add_child(info)
		var b: Button
		if bool(e.claimed):
			b = UiUtil.button(Text.MISSION_CLAIMED, func() -> void: pass)
			b.disabled = true
		else:
			b = UiUtil.button(Text.MISSION_CLAIM, func() -> void:
				if DailyService.claim_mission(i):
					AudioService.play_se("coin")
				_fill_missions(list))
			b.disabled = not DailyService.is_complete(e)
		b.custom_minimum_size = Vector2(72, 0)
		row.add_child(b)
		list.add_child(row)
	var all_row := HBoxContainer.new()
	var all_label := UiUtil.label(Text.MISSION_ALL_CLEAR % GameState.missions.all_clear_tickets, &"SmallLabel")
	all_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	all_row.add_child(all_label)
	var ab := UiUtil.button(Text.MISSION_CLAIMED if bool(SaveService.data.daily.all_clear_claimed) else Text.MISSION_CLAIM, func() -> void:
		if DailyService.claim_all_clear():
			AudioService.play_se("gacha_1")
		_fill_missions(list))
	ab.disabled = not DailyService.can_claim_all_clear()
	ab.custom_minimum_size = Vector2(72, 0)
	all_row.add_child(ab)
	list.add_child(all_row)
