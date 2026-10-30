class_name GachaSystem
extends RefCounted
## ガチャの抽選と、結果のセーブへの反映。


## min_rarity: 1 = 通常、2 = ★2以上確定、3 = ★3確定
static func roll(min_rarity: int, rng: RandomNumberGenerator) -> Dictionary:
	var g := GameState.gacha
	var rarity := _roll_rarity(g, min_rarity, rng)
	var swords := GameState.swords.filter(func(s: SwordData) -> bool: return s.in_gacha and s.rarity == rarity)
	var costumes := GameState.costumes.filter(func(c: CostumeData) -> bool: return c.in_gacha and c.rarity == rarity)
	var pick_sword := rng.randf() * (g.sword_weight + g.costume_weight) < g.sword_weight
	if swords.is_empty():
		pick_sword = false
	if costumes.is_empty():
		pick_sword = true
	if pick_sword:
		return _give_sword(swords[rng.randi_range(0, swords.size() - 1)], g)
	return _give_costume(costumes[rng.randi_range(0, costumes.size() - 1)], g)


static func _roll_rarity(g: GachaConfig, min_rarity: int, rng: RandomNumberGenerator) -> int:
	var total := 0.0
	for i in g.rarity_weights.size():
		if i + 1 >= min_rarity:
			total += g.rarity_weights[i]
	var r := rng.randf() * total
	for i in g.rarity_weights.size():
		if i + 1 < min_rarity:
			continue
		r -= g.rarity_weights[i]
		if r <= 0.0:
			return i + 1
	return g.rarity_weights.size()


static func _give_sword(s: SwordData, g: GachaConfig) -> Dictionary:
	var lv := SaveService.sword_level(s.id)
	var out := {"kind": "sword", "item": s, "rarity": s.rarity, "level": lv, "coins": 0}
	if lv == 0:
		SaveService.set_sword_level(s.id, 1)
		out.outcome = "new"
		out.level = 1
	elif lv < g.sword_max_level:
		SaveService.set_sword_level(s.id, lv + 1)
		out.outcome = "levelup"
		out.level = lv + 1
	else:
		out.outcome = "convert"
		out.coins = g.duplicate_coin
		SaveService.add_coins(g.duplicate_coin)
	return out


static func _give_costume(c: CostumeData, g: GachaConfig) -> Dictionary:
	var out := {"kind": "costume", "item": c, "rarity": c.rarity, "level": 0, "coins": 0}
	if not SaveService.has_costume(c.id):
		SaveService.add_costume(c.id)
		out.outcome = "new"
	else:
		out.outcome = "convert"
		out.coins = g.duplicate_coin
		SaveService.add_coins(g.duplicate_coin)
	return out
