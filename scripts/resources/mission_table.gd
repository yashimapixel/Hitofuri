class_name MissionTable
extends Resource
## デイリーミッションのプールと報酬。res://config/missions.tres

@export var missions: Array[MissionData] = []
@export var daily_count: int = 3
@export var reward_coin: int = 150
## 全達成ボーナス（ガチャチケット枚数）
@export var all_clear_tickets: int = 1


func get_mission(id: StringName) -> MissionData:
	for m: MissionData in missions:
		if m.id == id:
			return m
	return null
