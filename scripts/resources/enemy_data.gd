class_name EnemyData
extends Resource
## 通常敵 1 種の定義。res://config/enemies/*.tres

enum Behavior { STRAIGHT, BAT, GHOST, KNIGHT, MAGE, BULLET }

@export var id: StringName = &""
@export var display_name: String = ""
@export var hp: int = 1
@export var behavior: Behavior = Behavior.STRAIGHT
## 速度に掛ける倍率（魔法弾は GameConfig.bullet_speed_mul を使う）
@export var speed_mul: float = 1.0
## false なら撃破コインなし（魔法弾）
@export var gives_coin: bool = true
## false なら階層としてカウントしない（魔法弾）
@export var counts_as_floor: bool = true
## アニメ名: move
@export var sprite_frames: SpriteFrames
