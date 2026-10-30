class_name JudgeVisualizer
extends Node2D
## デバッグ用: 判定ライン付近の PERFECT / GOOD 範囲を色帯で表示する。
## 範囲は時間ベースなので、現在の階層の速度で px に換算して描く。

var judge: JudgeSystem
var line_y: float = 470.0
var speed: float = 220.0:
	set(v):
		speed = v
		queue_redraw()


func _draw() -> void:
	if judge == null:
		return
	var good_px := judge.good_sec * speed
	var perfect_px := judge.perfect_sec * speed
	draw_rect(Rect2(0, line_y - good_px, 360, good_px * 2.0), Color(0.3, 0.6, 1.0, 0.18))
	draw_rect(Rect2(0, line_y - perfect_px, 360, perfect_px * 2.0), Color(1.0, 0.8, 0.2, 0.28))
