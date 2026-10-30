extends Control
## Home 画面。出撃・強化・ガチャ・装備・ミッション・設定への入口。
## その日の初回表示時にログインボーナス、エリア解放時にストーリーを出す。

const BADGE_TEX := preload("res://assets/ui/badge.png")

@onready var heroine: Heroine = %Heroine
@onready var mission_button: Button = %MissionButton
@onready var mission_badge: TextureRect = %MissionBadge


func _ready() -> void:
	heroine.apply_costume(GameState.equipped_costume())
	%SortieButton.pressed.connect(_go.bind("area_select"))
	%UpgradeButton.pressed.connect(_go.bind("upgrade"))
	%GachaButton.pressed.connect(_go.bind("gacha"))
	%EquipButton.pressed.connect(_go.bind("equip"))
	%SettingsButton.pressed.connect(_go.bind("settings"))
	mission_button.pressed.connect(_open_missions)
	DailyService.check_new_day()
	DailyService.missions_changed.connect(_refresh_badge)
	DailyService.day_changed.connect(_on_day_changed)
	AudioService.play_bgm("home")
	_refresh_badge()
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
	if GameState.pending_story == 0 and not 1 in _seen_stories():
		GameState.pending_story = 1
	if GameState.pending_story > 0:
		await _show_story(GameState.pending_story)
		GameState.pending_story = 0
	if DailyService.has_pending_login_bonus():
		await _show_login_bonus()


func _seen_stories() -> Array[int]:
	var out: Array[int] = []
	for v: Variant in SaveService.data.story_seen:
		out.append(int(v))
	return out


# ---------------------------------------------------------------- ストーリー

func _show_story(index: int) -> void:
	if index in _seen_stories() or not Text.STORY.has(index):
		return
	SaveService.data.story_seen.append(index)
	SaveService.save_game()
	var area := GameState.get_area(mini(index, GameState.area_count()))
	var title := Text.ENDLESS if index > GameState.area_count() else area.display_name
	var m := Modal.open(self, title)
	var img := TextureRect.new()
	img.texture = area.story_image if area.story_image != null else area.background
	img.custom_minimum_size = Vector2(280, 150)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.clip_contents = true
	m.content.add_child(img)
	var text := UiUtil.label(Text.STORY[index])
	text.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	m.content.add_child(text)
	m.add_close_button(Text.OK)
	await m.closed


# ---------------------------------------------------------------- ログインボーナス

func _show_login_bonus() -> void:
	var reward := DailyService.claim_login_bonus()
	var total := DailyService.total_login_days()
	var m := Modal.open(self, Text.LOGIN_BONUS)
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
		cell.custom_minimum_size = Vector2(38, 40)
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
	var m := Modal.open(self, Text.MISSION_TITLE, 320)
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
