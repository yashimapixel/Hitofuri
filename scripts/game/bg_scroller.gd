class_name BgScroller
extends Node2D
## 背景をゆっくり縦スクロールさせる（縦にループする画像を 2 枚並べる）。

var speed: float = 8.0

var _a: Sprite2D
var _b: Sprite2D
var _offset := 0.0
var _height := 640.0


func setup(tex: Texture2D, scroll_speed: float) -> void:
	speed = scroll_speed
	if tex == null:
		return
	_height = tex.get_height()
	_a = Sprite2D.new()
	_b = Sprite2D.new()
	for s: Sprite2D in [_a, _b]:
		s.texture = tex
		s.centered = false
		add_child(s)
	_layout()


func _process(delta: float) -> void:
	if _a == null:
		return
	_offset = fposmod(_offset + speed * delta, _height)
	_layout()


func _layout() -> void:
	_a.position.y = floorf(_offset)
	_b.position.y = floorf(_offset) - _height
