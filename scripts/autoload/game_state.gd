extends Node
## 設定データの読み込みと、シーン間で共有する状態を持つ。

const ENDLESS := 0

var config: GameConfig
var juice: JuiceConfig
var upgrades: UpgradeTable
var gacha: GachaConfig
var missions: MissionTable
var login_bonus: LoginBonusTable
var enemies: Dictionary[StringName, EnemyData] = {}
## index 順（1 始まりのエリア番号 − 1 が添字）
var areas: Array[AreaData] = []
var swords: Array[SwordData] = []
var costumes: Array[CostumeData] = []

## 出撃するエリア（ENDLESS = エンドレス）
var selected_area: int = 1
## 直前のランの結果（Result 画面が読む）
var last_result: Dictionary = {}

# デバッグ（OS.is_debug_build() のときだけ設定画面から変更できる）
var debug_show_judge: bool = false


func _ready() -> void:
	config = load("res://config/game_config.tres")
	juice = load("res://config/juice_config.tres")
	upgrades = load("res://config/upgrades.tres")
	gacha = load("res://config/gacha.tres")
	missions = load("res://config/missions.tres")
	login_bonus = load("res://config/login_bonus.tres")
	for e: EnemyData in _load_dir("res://config/enemies/"):
		enemies[e.id] = e
	for a: AreaData in _load_dir("res://config/areas/"):
		areas.append(a)
	areas.sort_custom(func(x: AreaData, y: AreaData) -> bool: return x.index < y.index)
	for s: SwordData in _load_dir("res://config/swords/"):
		swords.append(s)
	for c: CostumeData in _load_dir("res://config/costumes/"):
		costumes.append(c)


func _load_dir(path: String) -> Array[Resource]:
	var out: Array[Resource] = []
	var files: PackedStringArray = ResourceLoader.list_directory(path)
	var names: Array[String] = []
	for f: String in files:
		if f.ends_with(".tres") or f.ends_with(".res"):
			names.append(f)
	names.sort()
	for f: String in names:
		var r: Resource = load(path + f)
		if r != null:
			out.append(r)
	return out


func is_debug() -> bool:
	return OS.is_debug_build()


func area_count() -> int:
	return areas.size()


func get_area(index: int) -> AreaData:
	if index >= 1 and index <= areas.size():
		return areas[index - 1]
	return areas.back()


func get_sword(id: StringName) -> SwordData:
	for s: SwordData in swords:
		if s.id == id:
			return s
	return swords[0]


func get_costume(id: StringName) -> CostumeData:
	for c: CostumeData in costumes:
		if c.id == id:
			return c
	return costumes[0]


func equipped_sword() -> SwordData:
	return get_sword(StringName(SaveService.data.equipped_sword))


func equipped_sword_level() -> int:
	return SaveService.sword_level(equipped_sword().id)


func equipped_costume() -> CostumeData:
	return get_costume(StringName(SaveService.data.equipped_costume))


func upgrade_value(id: StringName) -> float:
	var u: UpgradeData = upgrades.get_upgrade(id)
	return u.value_at(SaveService.upgrade_level(id)) if u != null else 0.0


func juice_on() -> bool:
	return juice.juice_enabled
