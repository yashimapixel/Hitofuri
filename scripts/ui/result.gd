extends Control
## リザルト画面。広告を見るとコイン 2 倍（回数上限なし）。

@onready var list: VBoxContainer = %Content
@onready var title_label: Label = %Title
@onready var ad_button: Button = %AdButton
@onready var take_button: Button = %TakeButton

var _total := 0
var _done := false


func _ready() -> void:
	var r := GameState.last_result
	if r.is_empty():
		r = {"area": 1, "cleared": false, "floor": 0, "kills": 0, "max_combo": 0, "perfect_rate": 0.0, "coins": 0, "first_clear_bonus": 0, "new": {}}
	var news: Dictionary = r.get("new", {})
	title_label.text = Text.RESULT_CLEAR if bool(r.cleared) else Text.RESULT
	_row(Text.RESULT_FLOOR, "%dF" % int(r.floor), news.get("floor", false))
	_row(Text.RESULT_KILLS, str(r.kills), news.get("kills", false))
	_row(Text.RESULT_MAX_COMBO, str(r.max_combo), news.get("combo", false))
	_row(Text.RESULT_PERFECT_RATE, "%d%%" % roundi(float(r.perfect_rate) * 100.0), news.get("perfect_rate", false))
	if int(r.first_clear_bonus) > 0:
		_row(Text.RESULT_FIRST_CLEAR, str(r.first_clear_bonus), false)
	_total = int(r.coins) + int(r.first_clear_bonus)
	_row(Text.RESULT_COINS, str(_total), news.get("coins", false), &"TitleLabel")
	ad_button.text = "%s（%d）" % [Text.AD_DOUBLE, _total * GameState.config.ad_reward_multiplier]
	ad_button.pressed.connect(_on_ad)
	take_button.pressed.connect(_finish.bind(1))
	if _total <= 0:
		ad_button.disabled = true
	AudioService.play_bgm("result")


func _row(name: String, value: String, is_new: bool, variation: StringName = &"") -> void:
	var h := HBoxContainer.new()
	var n := UiUtil.label(name, variation)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(n)
	if is_new:
		var nl := UiUtil.label(Text.NEW_RECORD, &"SmallLabel")
		nl.self_modulate = Color(1, 0.4, 0.3)
		h.add_child(nl)
	h.add_child(UiUtil.label(value, variation, HORIZONTAL_ALIGNMENT_RIGHT))
	list.add_child(h)


func _on_ad() -> void:
	if _done:
		return
	AudioService.play_se("button")
	ad_button.disabled = true
	take_button.disabled = true
	AdService.show_rewarded("result_double")
	var result: AdService.Result = await AdService.rewarded_finished
	match result:
		AdService.Result.REWARDED:
			DailyService.add_progress(MissionData.Stat.AD_DOUBLE, 1)
			_finish(GameState.config.ad_reward_multiplier)
		AdService.Result.SKIPPED:
			UiUtil.toast(get_tree().root, Text.AD_SKIPPED)
			_finish(1)
		_:
			UiUtil.toast(get_tree().root, Text.AD_FAILED)
			_finish(1)


func _finish(mul: int) -> void:
	if _done:
		return
	_done = true
	AudioService.play_se("coin")
	SaveService.add_coins(_total * mul)
	SaveService.save_game()
	GameState.last_result = {}
	UiUtil.go(get_tree(), "home")
