class_name UpgradeTable
extends Resource
## 強化項目の一覧。res://config/upgrades.tres

@export var upgrades: Array[UpgradeData] = []


func get_upgrade(id: StringName) -> UpgradeData:
	for u: UpgradeData in upgrades:
		if u.id == id:
			return u
	return null
