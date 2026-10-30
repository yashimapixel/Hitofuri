class_name Enemy
extends Node2D
## 通常敵。EnemyData.behavior に応じて動く。見た目は子の AnimatedSprite2D（アニメ名 move）。

signal fire_requested(enemy: Enemy)

enum State { MOVING, STOPPED, KNOCKBACK, DEAD }

var data: EnemyData
## 基本の降下速度（px/s）
var speed: float = 200.0
var hp: int = 1
## この敵が表す階層（弾は 0）
var floor_num: int = 0
var state: State = State.MOVING
var line_y: float = 470.0
var ghost_alpha: float = 0.1

var _cfg: GameConfig
var _stop_timer := 0.0
var _fired := false

@onready var sprite: AnimatedSprite2D = $Sprite


func setup(d: EnemyData, spd: float, floor_number: int, frames: SpriteFrames = null) -> void:
	data = d
	speed = spd
	hp = d.hp
	floor_num = floor_number
	_cfg = GameState.config
	line_y = _cfg.judge_line_y
	ghost_alpha = _cfg.ghost_alpha
	if is_node_ready():
		_apply_frames(frames)
	else:
		ready.connect(_apply_frames.bind(frames), CONNECT_ONE_SHOT)


func _apply_frames(frames: SpriteFrames) -> void:
	sprite.sprite_frames = frames if frames != null else data.sprite_frames
	sprite.play(&"move")
	sprite.material = sprite.material.duplicate() if sprite.material != null else null


func is_targetable() -> bool:
	return state != State.DEAD


func current_speed() -> float:
	if data.behavior == EnemyData.Behavior.BAT and line_y - position.y <= _cfg.bat_accel_distance:
		return speed * _cfg.bat_accel_mul
	return speed


## 判定ラインに到達するまでの残り時間（秒）。通過後は負。
func time_to_line() -> float:
	var d := line_y - position.y
	match state:
		State.STOPPED:
			return d / speed + _stop_timer
		State.KNOCKBACK:
			return d / speed + _cfg.knight_knockback_sec
	if data.behavior == EnemyData.Behavior.BAT and d > _cfg.bat_accel_distance:
		return (d - _cfg.bat_accel_distance) / speed + _cfg.bat_accel_distance / (speed * _cfg.bat_accel_mul)
	if data.behavior == EnemyData.Behavior.MAGE and not _fired and position.y < _cfg.mage_stop_y:
		return d / speed + _cfg.mage_stop_sec
	return d / current_speed()


func _process(delta: float) -> void:
	match state:
		State.MOVING:
			position.y += current_speed() * delta
			if data.behavior == EnemyData.Behavior.MAGE and not _fired and position.y >= _cfg.mage_stop_y:
				position.y = _cfg.mage_stop_y
				state = State.STOPPED
				_stop_timer = _cfg.mage_stop_sec
		State.STOPPED:
			_stop_timer -= delta
			if _stop_timer <= 0.0:
				_fired = true
				state = State.MOVING
				fire_requested.emit(self)
	if data.behavior == EnemyData.Behavior.GHOST and state != State.DEAD:
		var fade := position.y >= _cfg.ghost_fade_y_min and position.y <= _cfg.ghost_fade_y_max
		modulate.a = ghost_alpha if fade else 1.0


## 1 回目の斬りで倒れない敵（鎧騎士）: 上にノックバックしてから再接近
func knockback() -> void:
	hp -= 1
	state = State.KNOCKBACK
	_set_flash(1.0)
	var tw := create_tween()
	tw.tween_property(self, "position:y", position.y - _cfg.knight_knockback_px, _cfg.knight_knockback_sec).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_method(_set_flash, 1.0, 0.0, _cfg.knight_knockback_sec)
	tw.tween_callback(func() -> void: state = State.MOVING)


## 撃破: 白く点滅してから消える
func die(flash_sec: float) -> void:
	state = State.DEAD
	_set_flash(1.0)
	var tw := create_tween()
	tw.tween_interval(maxf(flash_sec, 0.01))
	tw.tween_callback(queue_free)


## 被弾で消える
func vanish() -> void:
	state = State.DEAD
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.1)
	tw.tween_callback(queue_free)


func _set_flash(v: float) -> void:
	if sprite.material is ShaderMaterial:
		(sprite.material as ShaderMaterial).set_shader_parameter("flash", v)
