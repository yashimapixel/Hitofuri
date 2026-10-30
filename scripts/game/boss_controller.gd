class_name BossController
extends Node
## ボスの HP と攻撃リズムを管理する（中ボス・エリアボス共通）。

signal fire_requested(from: Vector2, speed_mul: float)
signal hp_changed(hp: int, max_hp: int)
signal defeated(data: BossData)

enum State { NONE, INTRO, REST, WINDUP, FIRING, DEAD }

var view: Boss
var data: BossData
var hp: int = 1
var max_hp: int = 1
var floor_num: int = 0
var state: State = State.NONE

var _cfg: GameConfig
var _weights: PackedFloat32Array
var _timer := 0.0
var _shots: PackedFloat32Array
var _shot_index := 0
var _fire_t := 0.0
var _rng := RandomNumberGenerator.new()


func begin(boss_view: Boss, boss_data: BossData, boss_hp: int, pattern_weights: PackedFloat32Array, floor_number: int) -> void:
	_cfg = GameState.config
	_rng.randomize()
	view = boss_view
	data = boss_data
	max_hp = boss_hp
	hp = boss_hp
	floor_num = floor_number
	_weights = pattern_weights
	state = State.INTRO
	_timer = _cfg.boss_intro_sec
	hp_changed.emit(hp, max_hp)


func is_active() -> bool:
	return state != State.NONE and state != State.DEAD


func is_enraged() -> bool:
	return data != null and data.is_area_boss and float(hp) < float(max_hp) * _cfg.boss_enrage_hp_ratio


func bullet_speed_mul() -> float:
	return _cfg.boss_bullet_speed_mul * (_cfg.boss_enrage_speed_mul if is_enraged() else 1.0)


func _process(delta: float) -> void:
	match state:
		State.INTRO, State.REST:
			_timer -= delta
			if _timer <= 0.0:
				state = State.WINDUP
				_timer = _cfg.boss_windup_sec
				view.play_windup()
				AudioService.play_se("windup")
		State.WINDUP:
			_timer -= delta
			if _timer <= 0.0:
				_shots = _pick_pattern()
				_shot_index = 0
				_fire_t = 0.0
				state = State.FIRING
				view.play_idle()
		State.FIRING:
			_fire_t += delta
			while _shot_index < _shots.size() and _fire_t >= _shots[_shot_index]:
				fire_requested.emit(view.position + Vector2(0, 24 * view.scale.y), bullet_speed_mul())
				_shot_index += 1
			if _shot_index >= _shots.size():
				state = State.REST
				_timer = _cfg.boss_rest_sec


func take_damage(n: int) -> void:
	if not is_active():
		return
	hp = maxi(0, hp - n)
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		state = State.DEAD
		view.play_defeated()
		defeated.emit(data)
	else:
		view.play_hurt()


func _pick_pattern() -> PackedFloat32Array:
	var patterns := [_cfg.boss_pattern_single, _cfg.boss_pattern_double, _cfg.boss_pattern_triple]
	var total := 0.0
	for w: float in _weights:
		total += w
	if total <= 0.0:
		return patterns[0]
	var r := _rng.randf() * total
	for i in mini(_weights.size(), patterns.size()):
		r -= _weights[i]
		if r <= 0.0:
			return patterns[i]
	return patterns[0]
