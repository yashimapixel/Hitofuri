class_name Spawner
extends Node
## 階層の進行と敵の出現を管理する。敵 1 体（またはボス 1 体）= 1 階層。

signal spawn_requested(data: EnemyData, floor_num: int)
signal boss_requested(floor_num: int, is_area_boss: bool)

var area: AreaData
var endless := false
var next_floor := 1
## フィールドに通常敵が残っていないか（ボス出現の待ち合わせ用）
var is_field_clear: Callable = func() -> bool: return true

var _cfg: GameConfig
var _timer := 0.0
var _boss_active := false
var _finished := false
var _rng := RandomNumberGenerator.new()


func start(a: AreaData, is_endless: bool) -> void:
	_cfg = GameState.config
	area = a
	endless = is_endless
	next_floor = 1
	_timer = 0.8
	_rng.randomize()


func floors_per_cycle() -> int:
	return _cfg.floors_per_area


## エンドレスでの周回内の階層（1〜30）
func cycle_floor(f: int) -> int:
	return ((f - 1) % floors_per_cycle()) + 1


func cycle_index(f: int) -> int:
	return (f - 1) / floors_per_cycle()


func is_boss_floor(f: int) -> bool:
	var cf := cycle_floor(f)
	return cf == floors_per_cycle() or cf in _cfg.midboss_floors


func is_area_boss_floor(f: int) -> bool:
	return cycle_floor(f) == floors_per_cycle()


func spawn_interval(f: int) -> float:
	var ff := cycle_floor(f) if endless and _cfg.endless_use_cycle_floor else f
	return maxf(_cfg.spawn_interval_min, _cfg.spawn_interval_base - _cfg.spawn_interval_per_floor * ff)


func _process(delta: float) -> void:
	if _finished or _boss_active or area == null:
		return
	if is_boss_floor(next_floor):
		if is_field_clear.call():
			_boss_active = true
			boss_requested.emit(next_floor, is_area_boss_floor(next_floor))
		return
	_timer -= delta
	if _timer <= 0.0:
		spawn_requested.emit(_pick_enemy(), next_floor)
		_timer += spawn_interval(next_floor)
		next_floor += 1


func on_boss_defeated() -> void:
	_boss_active = false
	if not endless and next_floor >= floors_per_cycle():
		_finished = true
		return
	next_floor += 1
	_timer = spawn_interval(next_floor) + 0.4


func stop() -> void:
	_finished = true


func _pick_enemy() -> EnemyData:
	var total := 0.0
	for w: float in area.spawn_weights:
		total += w
	var r := _rng.randf() * total
	for i in area.enemy_ids.size():
		r -= area.spawn_weights[i] if i < area.spawn_weights.size() else 0.0
		if r <= 0.0:
			return GameState.enemies.get(StringName(area.enemy_ids[i]))
	return GameState.enemies.get(StringName(area.enemy_ids[0]))
