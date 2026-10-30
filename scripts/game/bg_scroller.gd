class_name BgScroller
extends Node2D
## 背景をゆっくり縦スクロールさせる。縦にループする画像を必要な枚数だけ並べ、
## 見えている範囲（cover で指定）を覆う。横長の画面では整数倍に拡大して左右の余白も埋める。

var speed: float = 8.0

var _tex: Texture2D
var _sprites: Array[Sprite2D] = []
var _offset := 0.0
var _rect := Rect2(0, 0, 360, 640)
var _scale := 1.0


func setup(tex: Texture2D, scroll_speed: float) -> void:
	speed = scroll_speed
	_tex = tex
	_rebuild()


## 背景で覆うワールド座標の範囲
func cover(rect: Rect2) -> void:
	_rect = rect
	_rebuild()


func _rebuild() -> void:
	if _tex == null:
		return
	_scale = maxf(1.0, ceilf(_rect.size.x / _tex.get_width()))
	var tile_h := _tex.get_height() * _scale
	var need := int(ceilf(_rect.size.y / tile_h)) + 1
	while _sprites.size() < need:
		var s := Sprite2D.new()
		s.texture = _tex
		s.centered = false
		add_child(s)
		_sprites.append(s)
	for s: Sprite2D in _sprites:
		s.scale = Vector2(_scale, _scale)
	_layout()


func _process(delta: float) -> void:
	if _sprites.is_empty():
		return
	_offset = fposmod(_offset + speed * delta, _tex.get_height() * _scale)
	_layout()


func _layout() -> void:
	var tile_h := _tex.get_height() * _scale
	var x := floorf(_rect.get_center().x - _tex.get_width() * _scale / 2.0)
	# 下端（ワールド y = rect.end.y）から上へ並べる
	var base := _rect.end.y - tile_h + floorf(_offset)
	for i in _sprites.size():
		_sprites[i].position = Vector2(x, base - tile_h * i)
