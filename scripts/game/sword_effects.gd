class_name SwordEffects
extends RefCounted
## 剣の効果をここに集約する。各フックは effect_id で分岐する。
## 新しい剣は config/swords/ に .tres を追加するだけで増やせる（既存の effect_id を使う場合）。

const E := SwordData.EffectId

var sword: SwordData
var level: int = 1
var value: float = 0.0


func _init(s: SwordData, lv: int) -> void:
	sword = s
	level = maxi(lv, 1)
	value = s.value_at(level) if s != null else 0.0


func _is(id: SwordData.EffectId) -> bool:
	return sword != null and sword.effect_id == id


## 判定幅（ms）を補正する。kind は "perfect" または "good_extra"
func modify_judge_window(kind: String, ms: float) -> float:
	if kind == "perfect" and _is(E.DRAGON_SLAYER):
		return ms + value
	if kind == "good_extra" and _is(E.GOOD_WINDOW_MS):
		return ms + value
	return ms


func modify_whiff_stun(sec: float) -> float:
	if _is(E.WHIFF_STUN_REDUCE):
		return maxf(0.05, sec - value)
	return sec


func modify_ghost_alpha(alpha: float) -> float:
	if _is(E.GHOST_ALPHA):
		return clampf(value, alpha, 1.0)
	return alpha


func coin_multiplier() -> float:
	if _is(E.COIN_PERCENT):
		return 1.0 + value / 100.0
	return 1.0


func combo_cap_bonus() -> float:
	return value if _is(E.COMBO_CAP) else 0.0


func boss_reflect_bonus() -> int:
	return floori(value) if _is(E.BOSS_REFLECT_DAMAGE) else 0


## 撃破時の追加コイン（倍率前の素の値）
func on_kill(enemy: EnemyData) -> float:
	if _is(E.BAT_BONUS_COIN) and enemy.behavior == EnemyData.Behavior.BAT:
		return value
	return 0.0


## 鎧騎士を 1 撃で倒すか
func knight_one_shot(rng: RandomNumberGenerator) -> bool:
	return _is(E.KNIGHT_ONE_SHOT) and rng.randf() < value


## コンボが増えたときに呼ぶ。{"guard": n, "heal": n} を返す
func on_combo(combo: int) -> Dictionary:
	var out := {"guard": 0, "heal": 0}
	if combo <= 0:
		return out
	if _is(E.GUARD_EVERY_COMBO) and combo % maxi(5, roundi(value)) == 0:
		out.guard = 1
	if _is(E.HEAL_EVERY_COMBO) and combo % maxi(5, roundi(value)) == 0:
		out.heal = 1
	return out


## 被弾時のコンボを返す
func on_damaged(combo: int) -> int:
	if _is(E.DRAGON_SLAYER):
		return combo / 2
	return 0
