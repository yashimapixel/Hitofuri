class_name AreaData
extends Resource
## エリア 1 つの定義。res://config/areas/*.tres

@export var index: int = 1
@export var display_name: String = ""
@export var speed_mul: float = 1.0
@export var coin_mul: float = 1.0
## 出現テーブル: enemy_ids[i] が spawn_weights[i] の重みで出る
@export var enemy_ids: PackedStringArray = PackedStringArray()
@export var spawn_weights: PackedFloat32Array = PackedFloat32Array()
## ボスの攻撃パターンの重み（単発 / 2連 / 3連）
@export var boss_pattern_weights: PackedFloat32Array = PackedFloat32Array([1, 0, 0])
@export var midboss: BossData
@export var area_boss: BossData
@export var background: Texture2D
@export var bg_scroll_speed: float = 8.0
## エリア解放時に出す一枚絵（未設定なら背景を使う）
@export var story_image: Texture2D
