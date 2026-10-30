extends SceneTree
## res://config/ 以下の調整用リソース（.tres）を仕様書の初期値で生成するツール。
##   godot --headless -s res://tools/gen_config.gd            # 既存ファイルは上書きしない
##   godot --headless -s res://tools/gen_config.gd -- --force # すべて作り直す
## 生成後はエディタのインスペクタで直接調整する。

const C := "res://config/"
var force := false


func _init() -> void:
	force = "--force" in OS.get_cmdline_user_args()
	_game_config()
	_enemies()
	var bosses := _bosses()
	_areas(bosses)
	_swords()
	_costumes()
	_upgrades()
	_gacha()
	_missions()
	_login_bonus()
	print("gen_config: done")
	quit()


func _save(res: Resource, path: String) -> void:
	if not force and FileAccess.file_exists(path):
		return
	var err := ResourceSaver.save(res, path)
	if err != OK:
		push_error("保存失敗 %s: %s" % [path, error_string(err)])


func _game_config() -> void:
	_save(GameConfig.new(), C + "game_config.tres")
	_save(JuiceConfig.new(), C + "juice_config.tres")


func _enemies() -> void:
	var defs := [
		["slime", "スライム", 1, EnemyData.Behavior.STRAIGHT],
		["bat", "コウモリ", 1, EnemyData.Behavior.BAT],
		["ghost", "ゴースト", 1, EnemyData.Behavior.GHOST],
		["knight", "鎧騎士", 2, EnemyData.Behavior.KNIGHT],
		["mage", "魔法使い", 1, EnemyData.Behavior.MAGE],
		["bullet", "魔法弾", 1, EnemyData.Behavior.BULLET],
	]
	for i in defs.size():
		var d: Array = defs[i]
		var e := EnemyData.new()
		e.id = StringName(d[0])
		e.display_name = d[1]
		e.hp = d[2]
		e.behavior = d[3]
		if d[0] == "bullet":
			e.gives_coin = false
			e.counts_as_floor = false
		e.sprite_frames = load("res://assets/sprites/enemies/%s_frames.tres" % d[0])
		_save(e, C + "enemies/%d_%s.tres" % [i + 1, d[0]])


func _bosses() -> Dictionary:
	var names := {
		"area1_mid": "コウモリの王", "area1_boss": "大スライム",
		"area2_mid": "さまよう亡霊", "area2_boss": "森の魔女",
		"area3_mid": "鉄壁の騎士", "area3_boss": "クリスタルゴーレム",
		"area4_mid": "雪原の魔導士", "area4_boss": "氷竜",
		"area5_mid": "魔王の影", "area5_boss": "魔王",
	}
	var out := {}
	for id: String in names:
		var path := C + "bosses/%s.tres" % id
		var b := BossData.new()
		b.id = StringName(id)
		b.display_name = names[id]
		b.is_area_boss = id.ends_with("_boss")
		b.sprite_frames = load("res://assets/sprites/bosses/%s_frames.tres" % id)
		b.bullet_frames = load("res://assets/sprites/bosses/boss_bullet_frames.tres")
		_save(b, path)
		out[id] = load(path) if FileAccess.file_exists(path) else b
	return out


func _areas(bosses: Dictionary) -> void:
	var defs := [
		[1, "はじまりの草原", 1.00, 1.0, ["slime", "bat"], [6, 4], [6, 3, 1]],
		[2, "まどろみの森", 1.15, 2.0, ["slime", "bat", "ghost"], [4, 3, 3], [4, 4, 2]],
		[3, "水晶の洞窟", 1.30, 3.0, ["slime", "bat", "ghost", "knight"], [3, 3, 2, 3], [3, 4, 3]],
		[4, "氷雪の山脈", 1.45, 5.0, ["slime", "bat", "ghost", "knight", "mage"], [2, 3, 2, 2, 3], [2, 4, 4]],
		[5, "魔王城", 1.60, 8.0, ["slime", "bat", "ghost", "knight", "mage"], [2, 2, 2, 2, 2], [1, 4, 5]],
	]
	for d: Array in defs:
		var a := AreaData.new()
		a.index = d[0]
		a.display_name = d[1]
		a.speed_mul = d[2]
		a.coin_mul = d[3]
		a.enemy_ids = PackedStringArray(d[4])
		a.spawn_weights = PackedFloat32Array(d[5])
		a.boss_pattern_weights = PackedFloat32Array(d[6])
		a.midboss = bosses["area%d_mid" % a.index]
		a.area_boss = bosses["area%d_boss" % a.index]
		a.background = load("res://assets/bg/area%d.png" % a.index)
		_save(a, C + "areas/area%d.tres" % a.index)


func _swords() -> void:
	var E := SwordData.EffectId
	var defs := [
		["見習いの剣", 1, E.NONE, 0.0, 0.0, "効果なし"],
		["鉄の剣", 1, E.COIN_PERCENT, 5.0, 2.0, "獲得コイン +{v}%"],
		["旅人の短剣", 1, E.GOOD_WINDOW_MS, 10.0, 5.0, "GOOD幅 +{v}ms"],
		["樫の木剣", 1, E.WHIFF_STUN_REDUCE, 0.10, 0.03, "空振り硬直 -{v}秒"],
		["銀の剣", 2, E.GHOST_ALPHA, 0.4, 0.1, "ゴーストの透明度が {v} に"],
		["疾風の剣", 2, E.BAT_BONUS_COIN, 2.0, 1.0, "コウモリ撃破時にコイン +{v}"],
		["守りの剣", 2, E.GUARD_EVERY_COMBO, 25.0, -3.0, "{v}コンボごとにガード+1"],
		["炎の剣", 2, E.KNIGHT_ONE_SHOT, 0.30, 0.10, "鎧騎士を {v}% の確率で1撃で倒す"],
		["癒しの剣", 2, E.HEAL_EVERY_COMBO, 20.0, -2.0, "{v}コンボごとにHP+1"],
		["聖騎士の剣", 3, E.BOSS_REFLECT_DAMAGE, 1.0, 0.5, "ボスへの跳ね返しダメージ +{v}"],
		["星屑の剣", 3, E.COMBO_CAP, 1.0, 0.25, "コンボ倍率の上限 +{v}"],
		["竜殺しの剣", 3, E.DRAGON_SLAYER, 20.0, 5.0, "PERFECT幅 +{v}ms\n被弾時コンボが半減で済む"],
	]
	for i in defs.size():
		var d: Array = defs[i]
		var s := SwordData.new()
		s.id = StringName("sword_%02d" % (i + 1))
		s.display_name = d[0]
		s.rarity = d[1]
		s.effect_id = d[2]
		s.base_value = d[3]
		s.per_level = d[4]
		s.description = d[5]
		s.icon = load("res://assets/sprites/swords/sword_%02d.png" % (i + 1))
		_save(s, C + "swords/sword_%02d.tres" % (i + 1))


func _costumes() -> void:
	var frames: SpriteFrames = load("res://assets/sprites/heroine_frames.tres")
	var defs := [
		["冒険者の服", 1, false, Color(0.25, 0.45, 0.8), Color(0.9, 0.85, 0.7), Color(0.85, 0.55, 0.25)],
		["村娘の服", 1, true, Color(0.75, 0.35, 0.3), Color(0.95, 0.92, 0.85), Color(0.5, 0.3, 0.15)],
		["見習い騎士", 1, true, Color(0.6, 0.62, 0.7), Color(0.3, 0.35, 0.6), Color(0.95, 0.85, 0.4)],
		["旅装束", 1, true, Color(0.5, 0.4, 0.25), Color(0.35, 0.5, 0.3), Color(0.25, 0.2, 0.2)],
		["魔法学院の制服", 2, true, Color(0.2, 0.2, 0.35), Color(0.7, 0.2, 0.3), Color(0.6, 0.4, 0.85)],
		["森の狩人", 2, true, Color(0.25, 0.5, 0.25), Color(0.55, 0.4, 0.2), Color(0.9, 0.6, 0.3)],
		["巫女装束", 2, true, Color(0.95, 0.95, 0.95), Color(0.85, 0.15, 0.2), Color(0.1, 0.1, 0.15)],
		["白銀の鎧", 3, true, Color(0.85, 0.88, 0.95), Color(0.45, 0.6, 0.9), Color(0.95, 0.95, 1.0)],
		["星詠みのドレス", 3, true, Color(0.2, 0.15, 0.45), Color(0.95, 0.8, 0.3), Color(0.6, 0.85, 1.0)],
	]
	for i in defs.size():
		var d: Array = defs[i]
		var c := CostumeData.new()
		c.id = StringName("costume_%02d" % i)
		c.display_name = d[0]
		c.rarity = d[1]
		c.in_gacha = d[2]
		c.sprite_frames = frames
		c.use_palette = true
		c.primary_color = d[3]
		c.secondary_color = d[4]
		c.hair_color = d[5]
		_save(c, C + "costumes/costume_%02d.tres" % i)


func _upgrades() -> void:
	var t := UpgradeTable.new()
	var hp := UpgradeData.new()
	hp.id = &"hp"
	hp.display_name = "最大HP"
	hp.description = "最大HPが1増える"
	hp.base_value = 3
	hp.per_level = 1
	hp.value_format = "%d"
	hp.costs = PackedInt32Array([100, 300, 800, 2000, 5000])
	var win := UpgradeData.new()
	win.id = &"window"
	win.display_name = "見切り"
	win.description = "PERFECT幅が10ms広がる"
	win.base_value = 0
	win.per_level = 10
	win.value_format = "+%dms"
	win.costs = _geometric(80.0, 1.9, 5)
	var coin := UpgradeData.new()
	coin.id = &"coin"
	coin.display_name = "金運"
	coin.description = "獲得コインが10%増える"
	coin.base_value = 0
	coin.per_level = 10
	coin.value_format = "+%d%%"
	coin.costs = _geometric(150.0, 1.6, 10)
	var guard := UpgradeData.new()
	guard.id = &"guard"
	guard.display_name = "加護"
	guard.description = "ラン開始時に被弾を1回防ぐガードを得る"
	guard.base_value = 0
	guard.per_level = 1
	guard.value_format = "%d個"
	guard.costs = PackedInt32Array([500, 2000, 6000])
	t.upgrades = [hp, win, coin, guard]
	_save(t, C + "upgrades.tres")


func _geometric(base: float, ratio: float, n: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	for lv in n:
		out.append(roundi(base * pow(ratio, lv)))
	return out


func _gacha() -> void:
	_save(GachaConfig.new(), C + "gacha.tres")


func _missions() -> void:
	var S := MissionData.Stat
	var defs := [
		["sortie", "{n}回出撃する", S.SORTIE, 3, false],
		["perfect", "PERFECTを合計{n}回出す", S.PERFECT, 50, false],
		["combo", "1回のランで{n}コンボする", S.COMBO_IN_RUN, 20, true],
		["kill", "敵を合計{n}体倒す", S.KILL, 100, false],
		["boss", "ボスを{n}体倒す", S.BOSS_KILL, 1, false],
		["ad", "広告を見て報酬を2倍にする", S.AD_DOUBLE, 1, false],
		["upgrade", "強化を{n}回する", S.UPGRADE, 1, false],
		["gacha", "ガチャを{n}回引く", S.GACHA, 1, false],
	]
	var t := MissionTable.new()
	var list: Array[MissionData] = []
	for d: Array in defs:
		var m := MissionData.new()
		m.id = StringName(d[0])
		m.text = d[1]
		m.stat = d[2]
		m.target = d[3]
		m.is_max_value = d[4]
		list.append(m)
	t.missions = list
	_save(t, C + "missions.tres")


func _login_bonus() -> void:
	var R := LoginBonusTable.RewardType
	var t := LoginBonusTable.new()
	var types: Array[LoginBonusTable.RewardType] = [
		R.COIN, R.COIN, R.COIN, R.COIN, R.COIN, R.COIN, R.TICKET_R2,
		R.COIN, R.COIN, R.COIN, R.COIN, R.COIN, R.COIN, R.TICKET_R3,
	]
	t.reward_types = types
	t.amounts = PackedInt32Array([100, 130, 160, 200, 240, 280, 1, 150, 200, 250, 300, 350, 400, 1])
	_save(t, C + "login_bonus.tres")
