class_name Boss
extends Node2D
## ボスの見た目。アニメ名: idle / windup / hurt

var _flash_blink := false
var _blink_t := 0.0
var _base_x := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite


func setup(frames: SpriteFrames) -> void:
	_base_x = position.x
	sprite.sprite_frames = frames
	sprite.material = sprite.material.duplicate() if sprite.material != null else null
	sprite.play(&"idle")


func play_idle() -> void:
	_flash_blink = false
	_set_flash(0.0)
	sprite.play(&"idle")


## 攻撃の予備動作: 白く点滅
func play_windup() -> void:
	_flash_blink = true
	_blink_t = 0.0
	sprite.play(&"windup")


func play_hurt() -> void:
	_flash_blink = false
	_set_flash(0.0)
	sprite.play(&"hurt")
	var tw := create_tween()
	tw.tween_property(self, "position:x", _base_x + 4 * scale.x, 0.04)
	tw.tween_property(self, "position:x", _base_x - 4 * scale.x, 0.04)
	tw.tween_property(self, "position:x", _base_x, 0.04)
	tw.tween_callback(func() -> void:
		if sprite.animation == &"hurt":
			sprite.play(&"idle"))


func play_defeated() -> void:
	_flash_blink = false
	_set_flash(1.0)
	var tw := create_tween()
	tw.tween_property(self, "scale", scale * 1.3, 0.3)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)


func _process(delta: float) -> void:
	if _flash_blink:
		_blink_t += delta
		_set_flash(0.85 if int(_blink_t / 0.08) % 2 == 0 else 0.0)


func _set_flash(v: float) -> void:
	if sprite.material is ShaderMaterial:
		(sprite.material as ShaderMaterial).set_shader_parameter("flash", v)
