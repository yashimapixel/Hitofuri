class_name UpgradeData
extends Resource
## 強化 1 項目。res://config/upgrades.tres の中にまとめて入っている

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
## Lv0 のときの値
@export var base_value: float = 0.0
## 1 Lv ごとの増分
@export var per_level: float = 1.0
## 値の表示書式（例: "%d" / "+%d%%" / "+%dms"）
@export var value_format: String = "%d"
## costs[i] = Lv i → Lv i+1 のコスト。要素数 = 最大Lv
@export var costs: PackedInt32Array = PackedInt32Array()


func max_level() -> int:
	return costs.size()


func value_at(level: int) -> float:
	return base_value + per_level * float(level)


func format_value(level: int) -> String:
	return value_format % roundi(value_at(level))
