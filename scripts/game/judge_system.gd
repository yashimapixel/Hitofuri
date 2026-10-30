class_name JudgeSystem
extends RefCounted
## 時間ベースの判定。敵が判定ラインに到達するまでの残り時間 t（秒）で判定する。

enum Judge { NONE, PERFECT, GOOD }

var perfect_sec: float = 0.07
var good_sec: float = 0.15


func setup(perfect_ms: float, good_extra_ms: float) -> void:
	perfect_sec = perfect_ms / 1000.0
	good_sec = (perfect_ms + good_extra_ms) / 1000.0


func judge(t: float) -> Judge:
	var a := absf(t)
	if a <= perfect_sec:
		return Judge.PERFECT
	if a <= good_sec:
		return Judge.GOOD
	return Judge.NONE


## 判定ラインに最も近い（|t| が最小の）未撃破の対象を返す。
func find_target(targets: Array) -> Enemy:
	var best: Enemy = null
	var best_t := INF
	for e: Enemy in targets:
		if not e.is_targetable():
			continue
		var t := absf(e.time_to_line())
		if t < best_t:
			best_t = t
			best = e
	return best


## 判定ラインを GOOD 範囲を超えて通過したか
func has_passed(e: Enemy) -> bool:
	return e.time_to_line() < -good_sec
