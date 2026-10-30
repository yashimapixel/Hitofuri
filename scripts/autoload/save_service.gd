extends Node
## user://save.json への保存と読み込み。
## save_version でマイグレーションし、書き込みは一時ファイル → リネームで行う。

signal changed

const SAVE_PATH := "user://save.json"
const TMP_PATH := "user://save.json.tmp"
const SAVE_VERSION := 1

var data: Dictionary = {}


func _ready() -> void:
	load_game()


func default_data() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"coins": 0,
		"tickets": 0,
		"tickets_r2": 0,
		"tickets_r3": 0,
		"upgrades": {"hp": 0, "window": 0, "coin": 0, "guard": 0},
		"swords": {"sword_01": 1},
		"equipped_sword": "sword_01",
		"costumes": ["costume_00"],
		"equipped_costume": "costume_00",
		"unlocked_area": 1,
		"cleared_areas": [],
		"best_floor": {},
		"endless_unlocked": false,
		"endless_best": 0,
		"bests": {"kills": 0, "combo": 0, "perfect_rate": 0.0, "coins": 0},
		"settings": {"bgm": true, "se": true, "vibration": true},
		"daily": {
			"day_index": -1,
			"total_login_days": 0,
			"login_claimed_day": -1,
			"missions": [],
			"all_clear_claimed": false,
		},
		"debug": {"day_offset": 0},
		"story_seen": [],
	}


func load_game() -> void:
	var loaded: Dictionary = {}
	if FileAccess.file_exists(SAVE_PATH):
		var text := FileAccess.get_file_as_string(SAVE_PATH)
		var parsed: Variant = JSON.parse_string(text)
		if parsed is Dictionary:
			loaded = parsed
		else:
			push_warning("save.json が壊れているため初期化します")
	data = _migrate(loaded) if not loaded.is_empty() else default_data()
	_fill_defaults(data, default_data())


func save_game() -> void:
	data.save_version = SAVE_VERSION
	var f := FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if f == null:
		push_error("セーブに失敗: %s" % error_string(FileAccess.get_open_error()))
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	var dir := DirAccess.open("user://")
	if dir.rename(TMP_PATH.get_file(), SAVE_PATH.get_file()) != OK:
		dir.remove(SAVE_PATH.get_file())
		dir.rename(TMP_PATH.get_file(), SAVE_PATH.get_file())
	changed.emit()


func reset() -> void:
	data = default_data()
	save_game()


## 古いバージョンのセーブを現在の形式に変換する。
func _migrate(d: Dictionary) -> Dictionary:
	var v: int = int(d.get("save_version", 0))
	# 例: if v < 2: d["new_field"] = ...; v = 2
	if v < 1:
		v = 1
	d.save_version = v
	return d


## 足りないキーを既定値で埋める（新しいフィールドを追加したとき用）。
func _fill_defaults(d: Dictionary, defaults: Dictionary) -> void:
	for k: Variant in defaults:
		if not d.has(k):
			d[k] = defaults[k]
		elif d[k] is Dictionary and defaults[k] is Dictionary and k != "best_floor" and k != "swords":
			_fill_defaults(d[k], defaults[k])


# ---------------------------------------------------------------- 通貨

func coins() -> int:
	return int(data.coins)


func add_coins(n: int) -> void:
	data.coins = coins() + n
	changed.emit()


func try_spend_coins(n: int) -> bool:
	if coins() < n:
		return false
	data.coins = coins() - n
	changed.emit()
	return true


func item_count(key: String) -> int:
	return int(data.get(key, 0))


func add_item(key: String, n: int) -> void:
	data[key] = item_count(key) + n
	changed.emit()


# ---------------------------------------------------------------- 強化・装備

func upgrade_level(id: StringName) -> int:
	return int(data.upgrades.get(String(id), 0))


func set_upgrade_level(id: StringName, lv: int) -> void:
	data.upgrades[String(id)] = lv
	changed.emit()


func sword_level(id: StringName) -> int:
	return int(data.swords.get(String(id), 0))


func has_sword(id: StringName) -> bool:
	return sword_level(id) > 0


func set_sword_level(id: StringName, lv: int) -> void:
	data.swords[String(id)] = lv


func has_costume(id: StringName) -> bool:
	return String(id) in data.costumes


func add_costume(id: StringName) -> void:
	if not has_costume(id):
		data.costumes.append(String(id))


# ---------------------------------------------------------------- エリア

func unlocked_area() -> int:
	return int(data.unlocked_area)


func is_area_cleared(index: int) -> bool:
	for a: Variant in data.cleared_areas:
		if int(a) == index:
			return true
	return false


func best_floor(index: int) -> int:
	if index == GameState.ENDLESS:
		return int(data.endless_best)
	return int(data.best_floor.get(str(index), 0))


func set_best_floor(index: int, f: int) -> void:
	if index == GameState.ENDLESS:
		data.endless_best = f
	else:
		data.best_floor[str(index)] = f


func setting(key: String) -> bool:
	return bool(data.settings.get(key, true))


func set_setting(key: String, v: bool) -> void:
	data.settings[key] = v
	save_game()
