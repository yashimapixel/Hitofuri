class_name SwordData
extends Resource
## 剣 1 本の定義。res://config/swords/*.tres
## 効果の処理は SwordEffects に集約されている。効果量 = base_value + per_level × (Lv − 1)

enum EffectId {
	NONE,
	COIN_PERCENT,          ## 獲得コイン +x%
	GOOD_WINDOW_MS,        ## GOOD 幅 +x ms
	WHIFF_STUN_REDUCE,     ## 空振り硬直 −x 秒
	GHOST_ALPHA,           ## ゴーストの透明度を x に
	BAT_BONUS_COIN,        ## コウモリ撃破時にコイン +x
	GUARD_EVERY_COMBO,     ## x コンボごとにガード +1
	KNIGHT_ONE_SHOT,       ## 鎧騎士を 1 撃で倒す確率 x
	HEAL_EVERY_COMBO,      ## x コンボごとに HP +1
	BOSS_REFLECT_DAMAGE,   ## ボスへの跳ね返しダメージ +floor(x)
	COMBO_CAP,             ## コンボ倍率の上限 +x
	DRAGON_SLAYER,         ## PERFECT 幅 +x ms、被弾時コンボ半減
}

@export var id: StringName = &""
@export var display_name: String = ""
@export_range(1, 3) var rarity: int = 1
## false ならガチャから出ない
@export var in_gacha: bool = true
@export var icon: Texture2D
@export var effect_id: EffectId = EffectId.NONE
@export var base_value: float = 0.0
@export var per_level: float = 0.0
## 説明文。{v} が効果量に置き換わる
@export_multiline var description: String = ""


func value_at(level: int) -> float:
	return base_value + per_level * float(maxi(level, 1) - 1)


func describe(level: int) -> String:
	var v: float = value_at(level)
	var s: String
	match effect_id:
		EffectId.COIN_PERCENT, EffectId.KNIGHT_ONE_SHOT:
			s = str(roundi(v * (100.0 if effect_id == EffectId.KNIGHT_ONE_SHOT else 1.0)))
		EffectId.WHIFF_STUN_REDUCE, EffectId.GHOST_ALPHA, EffectId.COMBO_CAP:
			s = "%.2f" % v
		EffectId.BOSS_REFLECT_DAMAGE:
			s = str(floori(v))
		_:
			s = str(roundi(v))
	return description.replace("{v}", s)
