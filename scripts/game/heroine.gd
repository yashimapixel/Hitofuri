class_name Heroine
extends Node2D
## ヒロイン。アニメ名: idle / slash / hurt / down

## 斬りモーションの再生速度（fps）。0 なら SpriteFrames の設定をそのまま使う
var slash_fps: float = 0.0

var _blink_left := 0.0
var _blink_interval := 0.08
var _is_down := false

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finished)


func apply_costume(c: CostumeData) -> void:
	sprite.sprite_frames = c.sprite_frames
	sprite.material = c.make_material()
	sprite.play(&"idle")


## 入力と同じフレームで斬りモーションを始める
func slash() -> void:
	if _is_down:
		return
	sprite.stop()
	sprite.speed_scale = 1.0
	if slash_fps > 0.0 and sprite.sprite_frames.has_animation(&"slash"):
		sprite.speed_scale = slash_fps / maxf(1.0, sprite.sprite_frames.get_animation_speed(&"slash"))
	sprite.play(&"slash")
	sprite.frame = 0


func hurt() -> void:
	if _is_down:
		return
	sprite.speed_scale = 1.0
	sprite.play(&"hurt")


func down() -> void:
	_is_down = true
	_blink_left = 0.0
	visible = true
	sprite.speed_scale = 1.0
	sprite.play(&"down")


func blink(duration: float, interval: float) -> void:
	_blink_left = duration
	_blink_interval = maxf(interval, 0.01)


func set_stunned(on: bool) -> void:
	modulate = Color(0.55, 0.55, 0.65) if on else Color.WHITE


func _process(delta: float) -> void:
	if _blink_left > 0.0:
		_blink_left -= delta
		visible = _blink_left <= 0.0 or int(_blink_left / _blink_interval) % 2 == 0
	elif not visible:
		visible = true


func _on_animation_finished() -> void:
	if sprite.animation == &"slash" or sprite.animation == &"hurt":
		sprite.speed_scale = 1.0
		sprite.play(&"idle")
