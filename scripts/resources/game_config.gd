class_name GameConfig
extends Resource
## ゲーム全体の調整値。res://config/game_config.tres をインスペクタで編集する。

@export_group("レイアウト")
@export var judge_line_y: float = 470.0
@export var heroine_position: Vector2 = Vector2(180, 530)
@export var spawn_y: float = -32.0
@export var boss_y: float = 150.0
## 敵の出現 X 位置のばらつき（中心 ± この値 px）
@export var spawn_x_jitter: float = 64.0

@export_group("表示サイズ")
## スプライトの表示倍率（素材を大きい解像度で描き直した場合は 1 にする）
@export var heroine_scale: float = 2.0
@export var enemy_scale: float = 2.0
@export var boss_scale: float = 2.0

@export_group("判定")
## PERFECT 幅（ms）。強化・剣で広がる
@export var perfect_window_ms: float = 70.0
## GOOD 幅 = PERFECT 幅 + この値（ms）
@export var good_extra_ms: float = 80.0
## 空振り硬直（秒）
@export var whiff_stun_sec: float = 0.4
## 被弾後の無敵時間（秒）
@export var invincible_sec: float = 0.8
@export var base_hp: int = 3

@export_group("速度・出現")
@export var base_speed: float = 220.0
@export var speed_per_floor: float = 0.01
@export var spawn_interval_base: float = 1.1
@export var spawn_interval_per_floor: float = 0.015
@export var spawn_interval_min: float = 0.45
@export var floors_per_area: int = 30
@export var midboss_floors: PackedInt32Array = PackedInt32Array([10, 20])
## エンドレス: 30F ごとに加算する速度倍率
@export var endless_speed_step: float = 0.1
## エンドレス: 速度式の floor に周回内の階層（1〜30）を使う
@export var endless_use_cycle_floor: bool = true

@export_group("敵の挙動")
@export var bat_accel_distance: float = 160.0
@export var bat_accel_mul: float = 1.8
@export var ghost_fade_y_min: float = 200.0
@export var ghost_fade_y_max: float = 330.0
@export var ghost_alpha: float = 0.1
@export var knight_knockback_px: float = 80.0
@export var knight_knockback_sec: float = 0.15
@export var mage_stop_y: float = 160.0
@export var mage_stop_sec: float = 0.6
@export var bullet_speed_mul: float = 1.5

@export_group("ボス")
@export var midboss_hp_base: int = 6
@export var midboss_hp_per_area: int = 2
@export var boss_hp_base: int = 10
@export var boss_hp_per_area: int = 3
@export var boss_windup_sec: float = 0.5
## ボス弾の速度 = 通常の敵速度 × この値
@export var boss_bullet_speed_mul: float = 1.0
@export var boss_enrage_hp_ratio: float = 0.5
@export var boss_enrage_speed_mul: float = 1.2
## 攻撃パターン間の休み（秒）
@export var boss_rest_sec: float = 0.9
## 攻撃パターンごとの弾の発射タイミング（秒）。単発 / 2連 / 3連（不均等）
@export var boss_pattern_single: PackedFloat32Array = PackedFloat32Array([0.0])
@export var boss_pattern_double: PackedFloat32Array = PackedFloat32Array([0.0, 0.35])
@export var boss_pattern_triple: PackedFloat32Array = PackedFloat32Array([0.0, 0.3, 0.75])
@export var boss_damage_perfect: int = 2
@export var boss_damage_good: int = 1
## ボス登場から最初の攻撃までの待ち（秒）
@export var boss_intro_sec: float = 1.0

@export_group("コイン")
@export var coin_per_kill: float = 1.0
@export var coin_midboss: float = 20.0
@export var coin_boss: float = 50.0
@export var coin_first_clear_per_area: int = 300
@export var combo_step: int = 10
@export var combo_mul_per_step: float = 0.5
@export var combo_mul_cap: float = 3.0
@export var ad_reward_multiplier: int = 2

@export_group("日付")
## 日付の切り替え時刻（端末ローカル時刻）
@export var day_reset_hour: int = 4
