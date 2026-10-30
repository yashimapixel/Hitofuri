extends Node
## 日付の切り替え（毎日 GameConfig.day_reset_hour 時）、ログインボーナス、デイリーミッション。

signal day_changed
signal missions_changed

const STAT_KEYS := {
	MissionData.Stat.SORTIE: "sortie",
	MissionData.Stat.PERFECT: "perfect",
	MissionData.Stat.COMBO_IN_RUN: "combo",
	MissionData.Stat.KILL: "kill",
	MissionData.Stat.BOSS_KILL: "boss_kill",
	MissionData.Stat.AD_DOUBLE: "ad_double",
	MissionData.Stat.UPGRADE: "upgrade",
	MissionData.Stat.GACHA: "gacha",
}


func _ready() -> void:
	check_new_day()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		check_new_day()


## 端末ローカル時刻から「日」の通し番号を求める（reset_hour 時に切り替わる）。
func current_day_index() -> int:
	var dt: Dictionary = Time.get_datetime_dict_from_system()
	var local_unix: int = Time.get_unix_time_from_datetime_dict(dt)
	var shifted: int = local_unix - GameState.config.day_reset_hour * 3600
	return floori(shifted / 86400.0) + int(SaveService.data.debug.day_offset)


func _daily() -> Dictionary:
	return SaveService.data.daily


## 日付が変わっていたらミッションを抽選し直す。変わったら true。
func check_new_day() -> bool:
	var today := current_day_index()
	if int(_daily().day_index) == today:
		return false
	_daily().day_index = today
	_roll_missions(today)
	SaveService.save_game()
	day_changed.emit()
	return true


func debug_advance_day() -> void:
	SaveService.data.debug.day_offset = int(SaveService.data.debug.day_offset) + 1
	check_new_day()


# ---------------------------------------------------------------- ログインボーナス

func has_pending_login_bonus() -> bool:
	return int(_daily().login_claimed_day) != current_day_index()


## 今日のログインボーナスを受け取る。報酬内容を返す。
func claim_login_bonus() -> Dictionary:
	var d := _daily()
	d.total_login_days = int(d.total_login_days) + 1
	d.login_claimed_day = current_day_index()
	var r: Dictionary = GameState.login_bonus.reward_for(int(d.total_login_days))
	match int(r.type):
		LoginBonusTable.RewardType.COIN:
			SaveService.add_coins(int(r.amount))
		LoginBonusTable.RewardType.TICKET:
			SaveService.add_item("tickets", int(r.amount))
		LoginBonusTable.RewardType.TICKET_R2:
			SaveService.add_item("tickets_r2", int(r.amount))
		LoginBonusTable.RewardType.TICKET_R3:
			SaveService.add_item("tickets_r3", int(r.amount))
	SaveService.save_game()
	return r


func total_login_days() -> int:
	return int(_daily().total_login_days)


# ---------------------------------------------------------------- ミッション

func _roll_missions(day: int) -> void:
	var table: MissionTable = GameState.missions
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(day)
	var pool: Array[MissionData] = table.missions.duplicate()
	var picked: Array = []
	for i in mini(table.daily_count, pool.size()):
		var idx := rng.randi_range(0, pool.size() - 1)
		picked.append({"id": String(pool[idx].id), "progress": 0, "claimed": false})
		pool.remove_at(idx)
	_daily().missions = picked
	_daily().all_clear_claimed = false
	missions_changed.emit()


func missions() -> Array:
	return _daily().missions


func mission_data(entry: Dictionary) -> MissionData:
	return GameState.missions.get_mission(StringName(entry.id))


func is_complete(entry: Dictionary) -> bool:
	var m := mission_data(entry)
	return m != null and int(entry.progress) >= m.target


## 統計を加算する（例: 撃破数）。保存は呼び出し側でまとめて行う。
func add_progress(stat: MissionData.Stat, amount: int) -> void:
	for e: Dictionary in missions():
		var m := mission_data(e)
		if m != null and m.stat == stat and not m.is_max_value:
			e.progress = mini(int(e.progress) + amount, m.target)
	missions_changed.emit()


## 1 回のランでの最大値で判定する統計（例: コンボ）。
func set_progress_max(stat: MissionData.Stat, value: int) -> void:
	for e: Dictionary in missions():
		var m := mission_data(e)
		if m != null and m.stat == stat:
			e.progress = mini(maxi(int(e.progress), value), m.target)
	missions_changed.emit()


func claim_mission(index: int) -> bool:
	var e: Dictionary = missions()[index]
	if bool(e.claimed) or not is_complete(e):
		return false
	e.claimed = true
	SaveService.add_coins(GameState.missions.reward_coin)
	SaveService.save_game()
	missions_changed.emit()
	return true


func all_claimed() -> bool:
	for e: Dictionary in missions():
		if not bool(e.claimed):
			return false
	return not missions().is_empty()


func can_claim_all_clear() -> bool:
	return all_claimed() and not bool(_daily().all_clear_claimed)


func claim_all_clear() -> bool:
	if not can_claim_all_clear():
		return false
	_daily().all_clear_claimed = true
	SaveService.add_item("tickets", GameState.missions.all_clear_tickets)
	SaveService.save_game()
	missions_changed.emit()
	return true


func has_claimable() -> bool:
	for e: Dictionary in missions():
		if not bool(e.claimed) and is_complete(e):
			return true
	return can_claim_all_clear()
