class_name JuiceConfig
extends Resource
## 手触り（ジュース）の調整値。res://config/juice_config.tres をインスペクタで編集する。

## すべての演出をまとめて ON/OFF（比較調整用）
@export var juice_enabled: bool = true

@export_group("ヒットストップ（ms）")
@export var hitstop_perfect_ms: float = 60.0
@export var hitstop_good_ms: float = 30.0
@export var hitstop_reflect_ms: float = 90.0
## ヒットストップ中の Engine.time_scale
@export var hitstop_time_scale: float = 0.02

@export_group("画面揺れ")
@export var shake_damage_px: float = 4.0
@export var shake_damage_ms: float = 150.0
@export var shake_boss_kill_px: float = 6.0
@export var shake_boss_kill_ms: float = 300.0

@export_group("斬撃エフェクト")
@export var slash_fx_fps: float = 30.0
@export var slash_fx_width: float = 260.0
@export var slash_fx_thickness: float = 2.0

@export_group("判定文字")
@export var judge_pop_scale: float = 1.4
@export var judge_pop_sec: float = 0.08
@export var judge_hold_sec: float = 0.25
@export var judge_fade_sec: float = 0.25
@export var perfect_color: Color = Color(1.0, 0.85, 0.3)
@export var good_color: Color = Color(0.5, 0.85, 1.0)
@export var miss_color: Color = Color(0.7, 0.7, 0.7)

@export_group("コンボ表示")
@export var combo_normal_color: Color = Color(1, 1, 1)
@export var combo_highlight_color: Color = Color(1.0, 0.55, 0.2)
@export var combo_shake_px: float = 3.0
@export var combo_shake_sec: float = 0.3

@export_group("撃破")
@export var kill_flash_sec: float = 0.06
@export var debris_amount: int = 10
@export var debris_speed: float = 140.0
@export var debris_lifetime: float = 0.4
@export var coin_fly_sec: float = 0.45

@export_group("振動（ms）")
@export var vibrate_perfect_ms: int = 10
@export var vibrate_damage_ms: int = 40

@export_group("ヒロイン")
@export var heroine_slash_fps: float = 24.0
@export var damage_blink_interval: float = 0.08
