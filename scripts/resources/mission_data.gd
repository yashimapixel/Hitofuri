class_name MissionData
extends Resource
## デイリーミッション 1 件。res://config/missions.tres の中にまとめて入っている

## 進捗を数える統計キー（DailyService.add_progress / set_progress_max で使う）
enum Stat { SORTIE, PERFECT, COMBO_IN_RUN, KILL, BOSS_KILL, AD_DOUBLE, UPGRADE, GACHA }

@export var id: StringName = &""
## 表示文。{n} が target に置き換わる
@export var text: String = ""
@export var stat: Stat = Stat.SORTIE
@export var target: int = 1
## true なら「1 回のランでの最大値」で判定する（コンボ系）
@export var is_max_value: bool = false


func describe() -> String:
	return text.replace("{n}", str(target))
