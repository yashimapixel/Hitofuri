class_name LoginBonusTable
extends Resource
## ログインボーナス（累計ログイン日数で進む 14 日サイクル）。res://config/login_bonus.tres

enum RewardType { COIN, TICKET, TICKET_R2, TICKET_R3 }

## 日ごとの報酬の種類（要素数 = サイクル日数）
@export var reward_types: Array[RewardType] = []
## 日ごとの報酬量
@export var amounts: PackedInt32Array = PackedInt32Array()
## 2 周目以降は確定チケットを通常チケットに置き換える
@export var downgrade_guaranteed_after_first_cycle: bool = true


func cycle_length() -> int:
	return reward_types.size()


## total_days は 1 始まりの累計ログイン日数
func reward_for(total_days: int) -> Dictionary:
	var n: int = cycle_length()
	if n == 0:
		return {"type": RewardType.COIN, "amount": 0, "day": 1}
	var idx: int = (total_days - 1) % n
	var cycle: int = (total_days - 1) / n
	var t: RewardType = reward_types[idx]
	var a: int = amounts[idx] if idx < amounts.size() else 1
	if cycle > 0 and downgrade_guaranteed_after_first_cycle and (t == RewardType.TICKET_R2 or t == RewardType.TICKET_R3):
		t = RewardType.TICKET
	return {"type": t, "amount": a, "day": idx + 1, "cycle": cycle}
