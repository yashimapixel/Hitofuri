extends Node2D
## ゲーム本編（1 ラン）。入力・判定・HP・コンボ・コイン・演出をまとめる。

const ENEMY_SCENE := preload("res://scenes/parts/enemy.tscn")
const PROJECTILE_SCENE := preload("res://scenes/parts/projectile.tscn")
const BOSS_SCENE := preload("res://scenes/parts/boss.tscn")
const HEART_TEX := preload("res://assets/ui/heart.png")
const HEART_EMPTY_TEX := preload("res://assets/ui/heart_empty.png")
const GUARD_TEX := preload("res://assets/ui/guard.png")
const COIN_TEX := preload("res://assets/ui/coin.png")
const DEBRIS_TEX := preload("res://assets/sprites/fx/debris.png")
const SLASH_FX_BASE_WIDTH := 200.0

var cfg: GameConfig
var juice: JuiceConfig
var judge := JudgeSystem.new()
var sword: SwordEffects
var area: AreaData
var area_index: int = 1
var endless := false
var rng := RandomNumberGenerator.new()

# ラン状態
var hp: int = 3
var max_hp: int = 3
var guards: int = 0
var combo: int = 0
var max_combo: int = 0
var kills: int = 0
var boss_kills: int = 0
var perfect_count: int = 0
var good_count: int = 0
var damage_count: int = 0
var coins_raw: float = 0.0
var floor_reached: int = 0
var stun_left := 0.0
var invincible_left := 0.0
var run_over := false
var cleared := false
var coin_mul_total := 1.0

var _ghost_alpha := 0.1
var _boss: Boss
var _boss_bullet_frames: SpriteFrames
var _hitstop_id := 0
var _shake_left := 0.0
var _shake_dur := 0.0
var _shake_px := 0.0
var _judge_tween: Tween
var _combo_tween: Tween
var _banner_tween: Tween
var _coin_se_cooldown := 0.0

@onready var background: BgScroller = $Background
@onready var camera: Camera2D = $Camera2D
@onready var judge_line: ColorRect = $JudgeLine
@onready var judge_vis: JudgeVisualizer = $JudgeVisualizer
@onready var boss_slot: Node2D = $BossSlot
@onready var field: Node2D = $Field
@onready var heroine: Heroine = $Heroine
@onready var slash_fx: AnimatedSprite2D = $SlashFx
@onready var effects: Node2D = $Effects
@onready var spawner: Spawner = $Spawner
@onready var boss_ctrl: BossController = $BossController
@onready var hud: CanvasLayer = $HUD
@onready var hearts: HBoxContainer = $HUD/Hearts
@onready var floor_label: Label = $HUD/FloorLabel
@onready var coin_icon: TextureRect = $HUD/CoinBox/CoinIcon
@onready var coin_label: Label = $HUD/CoinBox/CoinLabel
@onready var pause_button: Button = $HUD/PauseButton
@onready var boss_bar: ProgressBar = $HUD/BossBar
@onready var boss_name: Label = $HUD/BossBar/BossName
@onready var banner: Label = $HUD/Banner
@onready var judge_label: Label = $HUD/JudgeLabel
@onready var combo_label: Label = $HUD/ComboLabel
@onready var pause_layer: CanvasLayer = $PauseLayer
@onready var resume_button: Button = %ResumeButton
@onready var retreat_button: Button = %RetreatButton


func _ready() -> void:
	cfg = GameState.config
	juice = GameState.juice
	rng.randomize()
	area_index = GameState.selected_area
	endless = area_index == GameState.ENDLESS
	area = GameState.get_area(GameState.area_count() if endless else area_index)
	sword = SwordEffects.new(GameState.equipped_sword(), GameState.equipped_sword_level())

	var perfect_ms := sword.modify_judge_window("perfect", cfg.perfect_window_ms + GameState.upgrade_value(&"window"))
	var good_extra_ms := sword.modify_judge_window("good_extra", cfg.good_extra_ms)
	judge.setup(perfect_ms, good_extra_ms)
	_ghost_alpha = sword.modify_ghost_alpha(cfg.ghost_alpha)
	max_hp = int(GameState.upgrade_value(&"hp"))
	hp = max_hp
	guards = int(GameState.upgrade_value(&"guard"))
	coin_mul_total = (1.0 + GameState.upgrade_value(&"coin") / 100.0) * sword.coin_multiplier()

	judge_line.position = Vector2(0, cfg.judge_line_y - 1)
	heroine.position = cfg.heroine_position
	heroine.apply_costume(GameState.equipped_costume())
	heroine.slash_fps = juice.heroine_slash_fps
	slash_fx.position = Vector2(cfg.heroine_position.x, cfg.judge_line_y)
	slash_fx.hide()
	slash_fx.animation_finished.connect(slash_fx.hide)
	background.setup(area.background, area.bg_scroll_speed)
	judge_vis.visible = GameState.is_debug() and GameState.debug_show_judge
	judge_vis.judge = judge
	judge_vis.line_y = cfg.judge_line_y

	spawner.is_field_clear = _is_field_clear
	spawner.spawn_requested.connect(_on_spawn_requested)
	spawner.boss_requested.connect(_on_boss_requested)
	boss_ctrl.fire_requested.connect(_on_boss_fire)
	boss_ctrl.hp_changed.connect(_on_boss_hp_changed)
	boss_ctrl.defeated.connect(_on_boss_defeated)

	pause_button.pressed.connect(_open_pause)
	resume_button.pressed.connect(_resume)
	retreat_button.pressed.connect(_retreat)
	pause_layer.hide()
	boss_bar.hide()
	banner.modulate.a = 0.0
	judge_label.modulate.a = 0.0
	combo_label.text = ""

	DailyService.add_progress(MissionData.Stat.SORTIE, 1)
	_update_hud()
	spawner.start(area, endless)
	AudioService.play_bgm("battle")
	_show_banner(Text.ENDLESS if endless else area.display_name)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if is_node_ready() and not run_over and not get_tree().paused:
			_open_pause()


# ---------------------------------------------------------------- 毎フレーム

func _process(delta: float) -> void:
	var real_delta := delta / Engine.time_scale if Engine.time_scale > 0.0 else delta
	_update_shake(real_delta)
	_coin_se_cooldown -= real_delta
	if run_over:
		return
	if stun_left > 0.0:
		stun_left -= delta
		if stun_left <= 0.0:
			heroine.set_stunned(false)
	if invincible_left > 0.0:
		invincible_left -= delta
	for c: Node in field.get_children():
		var e := c as Enemy
		if e != null and e.is_targetable() and judge.has_passed(e):
			_on_passed(e)
			if run_over:
				return
	if judge_vis.visible:
		judge_vis.speed = _speed_for_floor(maxi(1, spawner.next_floor - 1))


func _speed_for_floor(f: int) -> float:
	var mul := area.speed_mul
	var ff := f
	if endless:
		mul += cfg.endless_speed_step * spawner.cycle_index(f)
		if cfg.endless_use_cycle_floor:
			ff = spawner.cycle_floor(f)
	return cfg.base_speed * mul * (1.0 + cfg.speed_per_floor * ff)


func _is_field_clear() -> bool:
	for c: Node in field.get_children():
		if c is Enemy and (c as Enemy).state != Enemy.State.DEAD:
			return false
	return true


# ---------------------------------------------------------------- 出現

func _on_spawn_requested(d: EnemyData, f: int) -> void:
	if d == null:
		return
	var e := ENEMY_SCENE.instantiate() as Enemy
	e.setup(d, _speed_for_floor(f) * d.speed_mul, f)
	e.ghost_alpha = _ghost_alpha
	e.position = Vector2(cfg.heroine_position.x, cfg.spawn_y)
	e.fire_requested.connect(_on_mage_fire)
	field.add_child(e)


func _on_mage_fire(mage: Enemy) -> void:
	_spawn_projectile(mage.position + Vector2(0, 12), mage.speed * cfg.bullet_speed_mul, false, null)


func _spawn_projectile(pos: Vector2, spd: float, from_boss: bool, frames: SpriteFrames) -> void:
	var p := PROJECTILE_SCENE.instantiate() as Projectile
	p.setup(GameState.enemies[&"bullet"], spd, 0, frames)
	p.from_boss = from_boss
	p.position = pos
	field.add_child(p)


# ---------------------------------------------------------------- ボス

func _on_boss_requested(f: int, is_area_boss: bool) -> void:
	var src_area := area
	var hp_area := area_index
	if endless:
		src_area = GameState.areas[rng.randi_range(0, GameState.area_count() - 1)]
		hp_area = GameState.area_count() + spawner.cycle_index(f)
	var bd: BossData = src_area.area_boss if is_area_boss else src_area.midboss
	var boss_hp: int
	if is_area_boss:
		boss_hp = cfg.boss_hp_base + cfg.boss_hp_per_area * hp_area
	else:
		boss_hp = cfg.midboss_hp_base + cfg.midboss_hp_per_area * hp_area
	_boss = BOSS_SCENE.instantiate() as Boss
	_boss.position = Vector2(cfg.heroine_position.x, cfg.boss_y)
	boss_slot.add_child(_boss)
	_boss.setup(bd.sprite_frames)
	_boss.position.y = -40.0
	create_tween().tween_property(_boss, "position:y", cfg.boss_y, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_boss_bullet_frames = bd.bullet_frames
	boss_ctrl.begin(_boss, bd, boss_hp, src_area.boss_pattern_weights, f)
	boss_name.text = bd.display_name
	boss_bar.show()
	_show_banner(Text.BOSS_APPEAR % bd.display_name)
	AudioService.play_se("boss_appear")
	AudioService.play_bgm("boss")
	_update_hud()


func _on_boss_fire(from: Vector2, speed_mul: float) -> void:
	if run_over:
		return
	_spawn_projectile(from, _speed_for_floor(boss_ctrl.floor_num) * speed_mul, true, _boss_bullet_frames)


func _on_boss_hp_changed(value: int, max_value: int) -> void:
	boss_bar.max_value = max_value
	boss_bar.value = value


func _on_boss_defeated(bd: BossData) -> void:
	boss_kills += 1
	coins_raw += (cfg.coin_boss if bd.is_area_boss else cfg.coin_midboss) * area.coin_mul
	floor_reached = maxi(floor_reached, boss_ctrl.floor_num)
	for c: Node in field.get_children():
		if c is Projectile and (c as Projectile).from_boss and (c as Projectile).is_targetable():
			(c as Projectile).die(0.0)
	_shake(juice.shake_boss_kill_px, juice.shake_boss_kill_ms)
	AudioService.play_se("boss_kill")
	if is_instance_valid(_boss):
		_spawn_debris(_boss.position, 2)
		_spawn_coin_fly(_boss.position, 6)
	boss_bar.hide()
	_update_hud()
	spawner.on_boss_defeated()
	if bd.is_area_boss and not endless:
		cleared = true
		run_over = true
		_show_banner(Text.AREA_CLEAR)
		await get_tree().create_timer(1.6, true, false, true).timeout
		_end_run()
	else:
		AudioService.play_bgm("battle")


# ---------------------------------------------------------------- 入力

func _unhandled_input(event: InputEvent) -> void:
	var pos := Vector2.ZERO
	var tapped := false
	var touch := event as InputEventScreenTouch
	if touch != null and touch.pressed:
		tapped = true
		pos = touch.position
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_SPACE:
		tapped = true
		pos = Vector2(cfg.heroine_position.x, cfg.judge_line_y)
	if not tapped:
		return
	if pause_button.get_global_rect().has_point(pos):
		return
	get_viewport().set_input_as_handled()
	_on_tap()


func _on_tap() -> void:
	if run_over or get_tree().paused or stun_left > 0.0:
		return
	# 斬りモーションは入力と同じフレームで開始する
	heroine.slash()
	_play_slash_fx()
	AudioService.play_se("slash")
	var target := judge.find_target(field.get_children())
	var j := judge.judge(target.time_to_line()) if target != null else JudgeSystem.Judge.NONE
	if j == JudgeSystem.Judge.NONE:
		_whiff()
	else:
		_on_hit(target, j)


func _whiff() -> void:
	stun_left = sword.modify_whiff_stun(cfg.whiff_stun_sec)
	heroine.set_stunned(true)
	AudioService.play_se("whiff")
	_show_judge(Text.MISS, juice.miss_color)


func _on_hit(e: Enemy, j: JudgeSystem.Judge) -> void:
	var perfect := j == JudgeSystem.Judge.PERFECT
	if perfect:
		perfect_count += 1
		combo += 1
		max_combo = maxi(max_combo, combo)
		_apply_combo_effects()
		HapticsService.vibrate(juice.vibrate_perfect_ms)
		_hitstop(juice.hitstop_perfect_ms)
		AudioService.play_se("perfect")
		_show_judge(Text.PERFECT, juice.perfect_color)
	else:
		good_count += 1
		_hitstop(juice.hitstop_good_ms)
		AudioService.play_se("good")
		_show_judge(Text.GOOD, juice.good_color)
	_update_combo_label(perfect)

	var p := e as Projectile
	if p != null and p.from_boss:
		var dmg := (cfg.boss_damage_perfect if perfect else cfg.boss_damage_good) + sword.boss_reflect_bonus()
		_hitstop(juice.hitstop_reflect_ms)
		AudioService.play_se("reflect")
		var to := _boss.position if is_instance_valid(_boss) else p.position + Vector2(0, -300)
		p.reflect(to, 0.15, func() -> void: boss_ctrl.take_damage(dmg))
		return
	if e.data.behavior == EnemyData.Behavior.KNIGHT and e.hp > 1 and not sword.knight_one_shot(rng):
		e.knockback()
		return
	_kill(e)


func _kill(e: Enemy) -> void:
	e.die(juice.kill_flash_sec if GameState.juice_on() else 0.0)
	if e.data.counts_as_floor:
		kills += 1
		floor_reached = maxi(floor_reached, e.floor_num)
	if e.data.gives_coin:
		coins_raw += cfg.coin_per_kill * area.coin_mul * _combo_mul() + sword.on_kill(e.data)
		_spawn_coin_fly(e.position, 1)
	_spawn_debris(e.position, 1)
	AudioService.play_se("kill")
	_update_hud()


func _combo_mul() -> float:
	var cap := cfg.combo_mul_cap + sword.combo_cap_bonus()
	return minf(cap, 1.0 + floorf(float(combo) / cfg.combo_step) * cfg.combo_mul_per_step)


func _apply_combo_effects() -> void:
	var r := sword.on_combo(combo)
	if int(r.guard) > 0:
		guards += int(r.guard)
		AudioService.play_se("guard")
	if int(r.heal) > 0 and hp < max_hp:
		hp = mini(max_hp, hp + int(r.heal))
		AudioService.play_se("heal")
	_update_hud()


func _on_passed(e: Enemy) -> void:
	if e.data.counts_as_floor:
		floor_reached = maxi(floor_reached, e.floor_num)
	e.vanish()
	if invincible_left > 0.0:
		return
	invincible_left = cfg.invincible_sec
	heroine.blink(cfg.invincible_sec, juice.damage_blink_interval)
	if guards > 0:
		guards -= 1
		AudioService.play_se("guard")
		_update_hud()
		return
	hp -= 1
	damage_count += 1
	combo = sword.on_damaged(combo)
	_update_combo_label(false)
	heroine.hurt()
	_shake(juice.shake_damage_px, juice.shake_damage_ms)
	HapticsService.vibrate(juice.vibrate_damage_ms)
	AudioService.play_se("damage")
	_update_hud()
	if hp <= 0:
		_game_over()


func _game_over() -> void:
	run_over = true
	spawner.stop()
	boss_ctrl.set_process(false)
	field.process_mode = Node.PROCESS_MODE_DISABLED
	heroine.down()
	AudioService.stop_bgm()
	await get_tree().create_timer(1.4, true, false, true).timeout
	_end_run()


# ---------------------------------------------------------------- 一時停止

func _open_pause() -> void:
	if run_over:
		return
	get_tree().paused = true
	pause_layer.show()


func _resume() -> void:
	pause_layer.hide()
	get_tree().paused = false


func _retreat() -> void:
	pause_layer.hide()
	get_tree().paused = false
	run_over = true
	_end_run()


# ---------------------------------------------------------------- 終了

func _end_run() -> void:
	run_over = true
	Engine.time_scale = 1.0
	var coins := floori(coins_raw * coin_mul_total)
	var first_bonus := 0
	var d := SaveService.data
	if cleared and not endless:
		if not SaveService.is_area_cleared(area_index):
			first_bonus = cfg.coin_first_clear_per_area * area_index
			d.cleared_areas.append(area_index)
		if area_index < GameState.area_count() and area_index >= SaveService.unlocked_area():
			d.unlocked_area = area_index + 1
			GameState.pending_story = area_index + 1
		if area_index == GameState.area_count() and not bool(d.endless_unlocked):
			d.endless_unlocked = true
			GameState.pending_story = GameState.area_count() + 1
	var judged := perfect_count + good_count + damage_count
	var rate := float(perfect_count) / float(judged) if judged > 0 else 0.0
	var news := {}
	news.floor = floor_reached > SaveService.best_floor(area_index)
	if news.floor:
		SaveService.set_best_floor(area_index, floor_reached)
	var bests: Dictionary = d.bests
	news.kills = kills > int(bests.kills)
	news.combo = max_combo > int(bests.combo)
	news.perfect_rate = judged >= 10 and rate > float(bests.perfect_rate)
	news.coins = coins + first_bonus > int(bests.coins)
	if news.kills:
		bests.kills = kills
	if news.combo:
		bests.combo = max_combo
	if news.perfect_rate:
		bests.perfect_rate = rate
	if news.coins:
		bests.coins = coins + first_bonus

	DailyService.add_progress(MissionData.Stat.PERFECT, perfect_count)
	DailyService.add_progress(MissionData.Stat.KILL, kills)
	DailyService.add_progress(MissionData.Stat.BOSS_KILL, boss_kills)
	DailyService.set_progress_max(MissionData.Stat.COMBO_IN_RUN, max_combo)
	SaveService.save_game()

	GameState.last_result = {
		"area": area_index,
		"cleared": cleared,
		"floor": floor_reached,
		"kills": kills,
		"max_combo": max_combo,
		"perfect_rate": rate,
		"coins": coins,
		"first_clear_bonus": first_bonus,
		"new": news,
	}
	get_tree().change_scene_to_file("res://scenes/result.tscn")


# ---------------------------------------------------------------- HUD

func _update_hud() -> void:
	for c: Node in hearts.get_children():
		c.queue_free()
	for i in max_hp:
		var t := TextureRect.new()
		t.texture = HEART_TEX if i < hp else HEART_EMPTY_TEX
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hearts.add_child(t)
	for i in guards:
		var g := TextureRect.new()
		g.texture = GUARD_TEX
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hearts.add_child(g)
	var floors := cfg.floors_per_area
	if endless:
		floor_label.text = Text.FLOOR_ENDLESS % (floor_reached + 1)
	else:
		floor_label.text = Text.FLOOR % [clampi(floor_reached + 1, 1, floors), floors]
	coin_label.text = str(floori(coins_raw * coin_mul_total))


func _show_judge(text: String, color: Color) -> void:
	judge_label.text = text
	judge_label.self_modulate = color
	if _judge_tween != null:
		_judge_tween.kill()
	judge_label.pivot_offset = judge_label.size / 2.0
	if not GameState.juice_on():
		judge_label.modulate.a = 1.0
		judge_label.scale = Vector2.ONE
		return
	judge_label.modulate.a = 1.0
	judge_label.scale = Vector2.ONE * juice.judge_pop_scale
	_judge_tween = create_tween()
	_judge_tween.tween_property(judge_label, "scale", Vector2.ONE, juice.judge_pop_sec)
	_judge_tween.tween_interval(juice.judge_hold_sec)
	_judge_tween.tween_property(judge_label, "modulate:a", 0.0, juice.judge_fade_sec)


func _update_combo_label(increased: bool) -> void:
	combo_label.text = Text.COMBO % combo if combo >= 2 else ""
	if _combo_tween != null:
		_combo_tween.kill()
	combo_label.pivot_offset = combo_label.size / 2.0
	combo_label.position.x = 0.0
	if increased and combo > 0 and combo % cfg.combo_step == 0 and GameState.juice_on():
		combo_label.self_modulate = juice.combo_highlight_color
		_combo_tween = create_tween()
		var s := juice.combo_shake_sec / 6.0
		for i in 3:
			_combo_tween.tween_property(combo_label, "position:x", juice.combo_shake_px, s)
			_combo_tween.tween_property(combo_label, "position:x", -juice.combo_shake_px, s)
		_combo_tween.tween_property(combo_label, "position:x", 0.0, s)
		_combo_tween.tween_property(combo_label, "self_modulate", juice.combo_normal_color, 0.4)
	else:
		combo_label.self_modulate = juice.combo_highlight_color if combo >= cfg.combo_step else juice.combo_normal_color


func _show_banner(text: String) -> void:
	banner.text = text
	if _banner_tween != null:
		_banner_tween.kill()
	banner.modulate.a = 0.0
	_banner_tween = create_tween()
	_banner_tween.tween_property(banner, "modulate:a", 1.0, 0.2)
	_banner_tween.tween_interval(1.0)
	_banner_tween.tween_property(banner, "modulate:a", 0.0, 0.4)


# ---------------------------------------------------------------- ジュース

func _hitstop(ms: float) -> void:
	if not GameState.juice_on() or ms <= 0.0:
		return
	_hitstop_id += 1
	Engine.time_scale = juice.hitstop_time_scale
	get_tree().create_timer(ms / 1000.0, true, false, true).timeout.connect(_end_hitstop.bind(_hitstop_id))


## 最後に始めたヒットストップのタイマーだけが時間を戻す
func _end_hitstop(id: int) -> void:
	if id == _hitstop_id:
		Engine.time_scale = 1.0


func _shake(px: float, ms: float) -> void:
	if not GameState.juice_on() or px <= 0.0 or ms <= 0.0:
		return
	_shake_px = px
	_shake_dur = ms / 1000.0
	_shake_left = _shake_dur


func _update_shake(dt: float) -> void:
	if _shake_left > 0.0:
		_shake_left -= dt
		var k := clampf(_shake_left / _shake_dur, 0.0, 1.0)
		camera.offset = (Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * _shake_px * k).round()
	elif camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO


func _play_slash_fx() -> void:
	if not GameState.juice_on():
		return
	slash_fx.show()
	slash_fx.scale.x = juice.slash_fx_width / SLASH_FX_BASE_WIDTH
	slash_fx.speed_scale = juice.slash_fx_fps / maxf(1.0, slash_fx.sprite_frames.get_animation_speed(&"slash"))
	slash_fx.stop()
	slash_fx.play(&"slash")


func _spawn_debris(pos: Vector2, size_mul: float) -> void:
	if not GameState.juice_on():
		return
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.amount = maxi(1, int(juice.debris_amount * size_mul))
	p.lifetime = juice.debris_lifetime
	p.explosiveness = 1.0
	p.texture = DEBRIS_TEX
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = juice.debris_speed * 0.5 * size_mul
	p.initial_velocity_max = juice.debris_speed * size_mul
	p.gravity = Vector2(0, 400)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = g
	effects.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


func _spawn_coin_fly(from: Vector2, n: int) -> void:
	if not GameState.juice_on():
		return
	var to := coin_icon.global_position + coin_icon.size / 2.0
	for i in n:
		var s := Sprite2D.new()
		s.texture = COIN_TEX
		s.position = from + Vector2(rng.randf_range(-8, 8), rng.randf_range(-8, 8))
		hud.add_child(s)
		var tw := s.create_tween()
		tw.tween_interval(0.04 * i)
		tw.tween_property(s, "position", to, juice.coin_fly_sec).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(_on_coin_arrived)
		tw.tween_callback(s.queue_free)


func _on_coin_arrived() -> void:
	if _coin_se_cooldown <= 0.0:
		AudioService.play_se("coin")
		_coin_se_cooldown = 0.08
	coin_icon.pivot_offset = coin_icon.size / 2.0
	var tw := coin_icon.create_tween()
	coin_icon.scale = Vector2(1.5, 1.5)
	tw.tween_property(coin_icon, "scale", Vector2.ONE, 0.12)
