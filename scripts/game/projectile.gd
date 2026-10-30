class_name Projectile
extends Enemy
## 魔法弾・ボスの攻撃弾。斬れる。ボスの弾は斬ると跳ね返ってボスにダメージを与える。

var from_boss := false


## 跳ね返してボスへ飛ばす。到達時に on_arrive を呼ぶ
func reflect(target: Vector2, sec: float, on_arrive: Callable) -> void:
	state = State.DEAD
	_set_flash(0.6)
	var tw := create_tween()
	tw.tween_property(self, "position", target, sec).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(on_arrive)
	tw.tween_callback(queue_free)
