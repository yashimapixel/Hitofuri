class_name GachaConfig
extends Resource
## ガチャの設定。res://config/gacha.tres

@export var single_cost: int = 300
@export var ten_cost: int = 2700
## ★1 / ★2 / ★3 の排出重み（%）
@export var rarity_weights: PackedFloat32Array = PackedFloat32Array([65, 28, 7])
## 剣 : 衣装 の抽選比率
@export var sword_weight: float = 7.0
@export var costume_weight: float = 3.0
@export var sword_max_level: int = 5
## 最大Lv後の剣・所持済み衣装の重複を変換するコイン
@export var duplicate_coin: int = 100
@export var shake_sec: float = 0.9
@export var open_sec: float = 0.6
@export var rarity_light_colors: PackedColorArray = PackedColorArray([Color(1, 1, 1), Color(0.35, 0.6, 1.0), Color(1.0, 0.82, 0.25)])
