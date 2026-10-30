class_name BossData
extends Resource
## 中ボス・エリアボスの定義。res://config/bosses/*.tres

@export var id: StringName = &""
@export var display_name: String = ""
@export var is_area_boss: bool = false
## アニメ名: idle / windup / hurt
@export var sprite_frames: SpriteFrames
## ボスが撃つ弾の見た目（アニメ名: move）
@export var bullet_frames: SpriteFrames
