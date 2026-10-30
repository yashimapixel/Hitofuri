extends Node
## 自動テスト: 全画面を開き、ボットでエリアを遊んで Result まで進むことを確認する。
##   godot --headless --fixed-fps 60 res://tools/smoke_test.tscn
## セーブは user:// を使うので、実行前後でバックアップ・復元する。

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _gs() -> Node:
	return get_tree().root.get_node("GameState")


func _save() -> Node:
	return get_tree().root.get_node("SaveService")


func _wait(frames: int) -> void:
	for i in frames:
		await get_tree().process_frame


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: ", msg)
	else:
		print("  FAIL: ", msg)
		_failures.append(msg)


func _run() -> void:
	# シーン切り替えで消えないように root 直下へ移す
	var tree := get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	tree.current_scene = null
	await _wait(2)
	var save := _save()
	var backup: Dictionary = save.data.duplicate(true)
	save.reset()
	get_tree().root.get_node("DailyService").check_new_day()

	print("[screens]")
	for s: String in ["title", "home", "area_select", "upgrade", "gacha", "equip", "settings"]:
		get_tree().change_scene_to_file("res://scenes/%s.tscn" % s)
		await _wait(10)
		_check(get_tree().current_scene != null and get_tree().current_scene.scene_file_path.ends_with(s + ".tscn"), "open " + s)
		# Home のダイアログ（ストーリー・ログボ）を閉じる
		for c: Node in get_tree().current_scene.get_children():
			if c is CanvasLayer and c.has_method("close"):
				c.close()
		for c: Node in get_tree().root.get_children():
			if c is CanvasLayer and c.has_method("close"):
				c.close()

	print("[gacha]")
	save.add_coins(100000)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var counts := [0, 0, 0]
	for i in 2000:
		var r: Dictionary = GachaSystem.roll(1, rng)
		counts[int(r.rarity) - 1] += 1
	print("  rarity counts (2000): ", counts)
	_check(counts[0] > 1100 and counts[2] > 80 and counts[2] < 220, "gacha rates roughly 65/28/7")
	var r3: Dictionary = GachaSystem.roll(3, rng)
	_check(int(r3.rarity) == 3, "★3 ticket gives ★3")

	print("[daily]")
	var daily := get_tree().root.get_node("DailyService")
	_check(daily.missions().size() == 3, "3 missions rolled")
	_check(not daily.has_pending_login_bonus(), "login bonus claimed on Home")
	daily.debug_advance_day()
	_check(daily.has_pending_login_bonus(), "next day login pending")
	daily.claim_login_bonus()

	print("[stage intro]")
	save.data.story_seen = []
	_gs().selected_area = 1
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	await _wait(10)
	var modal := _find_modal(get_tree().current_scene)
	_check(modal != null, "intro shown on first entry")
	_check(not bool(get_tree().current_scene.get("_started")), "spawning waits for intro")
	if modal != null:
		modal.close()
	await _wait(5)
	_check(bool(get_tree().current_scene.get("_started")), "game starts after intro closes")
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	await _wait(10)
	_check(_find_modal(get_tree().current_scene) == null, "intro not shown on second entry")
	# 以降のテストでは紹介を出さない
	save.data.story_seen = [1, 2, 3, 4, 5, 6]

	print("[game: perfect bot, area 1]")
	save.data.equipped_sword = "sword_01"
	_gs().selected_area = 1
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	await _wait(3)
	var ok := await _play_with_bot(true, 60 * 240)
	_check(ok, "reached result")
	var res: Dictionary = _gs().last_result
	print("  result: ", res)
	_check(bool(res.get("cleared", false)), "area 1 cleared by perfect bot")
	_check(int(save.data.unlocked_area) == 2, "area 2 unlocked")

	print("[result: ad double]")
	var coins_before: int = save.coins()
	var total: int = int(res.coins) + int(res.first_clear_bonus)
	get_tree().current_scene.call("_on_ad")
	await _wait(60 * 3)
	_check(save.coins() == coins_before + total * 2, "ad doubled coins (%d -> %d)" % [coins_before, save.coins()])

	print("[game: idle bot, area 3 knights / endless]")
	for idx: int in [3, 4, 0]:
		save.data.unlocked_area = 5
		save.data.endless_unlocked = true
		_gs().selected_area = idx
		get_tree().change_scene_to_file("res://scenes/game.tscn")
		await _wait(3)
		ok = await _play_with_bot(false, 60 * 120)
		_check(ok and not bool(_gs().last_result.get("cleared", true)), "area %d: game over when not tapping" % idx)

	print("[game: perfect bot, area 4 with mages]")
	_gs().selected_area = 4
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	await _wait(3)
	ok = await _play_with_bot(true, 60 * 300)
	_check(ok and bool(_gs().last_result.get("cleared", false)), "area 4 cleared by perfect bot: %s" % str(_gs().last_result))

	save.data = backup
	save.save_game()
	print("\nSMOKE TEST: ", "PASS" if _failures.is_empty() else "FAIL %s" % str(_failures))
	get_tree().quit(0 if _failures.is_empty() else 1)


func _find_modal(n: Node) -> Modal:
	for c: Node in n.get_children():
		if c is Modal:
			return c
	return null


## ボットで遊ぶ。perfect=true なら判定ラインぴったりで斬る。Result に着いたら true
func _play_with_bot(perfect: bool, max_frames: int) -> bool:
	for i in max_frames:
		await get_tree().process_frame
		var g := get_tree().current_scene
		if g == null:
			continue
		if g.scene_file_path.ends_with("result.tscn"):
			return true
		if not perfect or not g.has_method("_on_tap"):
			continue
		var field: Node = g.get_node_or_null("Field")
		if field == null:
			continue
		var judge: JudgeSystem = g.get("judge")
		var target: Enemy = judge.find_target(field.get_children())
		if target != null and absf(target.time_to_line()) <= 0.012 and float(g.get("stun_left")) <= 0.0:
			g.call("_on_tap")
	var gs := get_tree().current_scene
	if gs != null and gs.has_method("_on_tap"):
		print("  timeout state: paused=%s floor=%d hp=%d run_over=%s next_floor=%d field=%d boss=%s" % [get_tree().paused, gs.get("floor_reached"), gs.get("hp"), gs.get("run_over"), gs.get_node("Spawner").next_floor, gs.get_node("Field").get_child_count(), gs.get_node("BossController").state])
	return false
