extends Node
## 各画面のスクリーンショットを撮る（見た目の確認用）。
##   xvfb-run godot --rendering-driver opengl3 res://tools/screenshots.tscn -- <出力ディレクトリ>

var _out := "user://screenshots"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


## 60fps 換算のフレーム数ぶん（実時間で）待つ
func _wait(frames: int) -> void:
	await get_tree().create_timer(frames / 60.0, true, false, true).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(_out.path_join(name + ".png"))
	print("saved ", name)


func _close_modals() -> void:
	for c: Node in get_tree().current_scene.get_children() + get_tree().root.get_children():
		if c is Modal:
			c.close()


func _run() -> void:
	var tree := get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	tree.current_scene = null
	var save := SaveService
	var backup: Dictionary = save.data.duplicate(true)
	save.reset()
	await _wait(2)

	tree.change_scene_to_file("res://scenes/title.tscn")
	await _wait(20)
	await _shot("01_title")
	tree.change_scene_to_file("res://scenes/home.tscn")
	await _wait(30)
	await _shot("03_home_login")
	_close_modals()
	await _wait(20)
	await _shot("04_home")

	save.add_coins(50000)
	save.add_item("tickets", 3)
	save.add_item("tickets_r3", 1)
	tree.current_scene.call("_open_missions")
	await _wait(20)
	await _shot("05_missions")
	_close_modals()

	save.data.unlocked_area = 3
	save.data.best_floor = {"1": 30, "2": 14}
	save.data.cleared_areas = [1]
	for s: String in ["area_select", "upgrade", "gacha", "equip", "settings"]:
		tree.change_scene_to_file("res://scenes/%s.tscn" % s)
		await _wait(20)
		await _shot("1_" + s)

	tree.change_scene_to_file("res://scenes/gacha.tscn")
	await _wait(10)
	tree.current_scene.call("_pull", 10, "coins", 2700)
	await _wait(25)
	await _shot("2_gacha_anim")
	await _wait(120)
	await _shot("2_gacha_result")
	_close_modals()

	GameState.debug_show_judge = true
	GameState.selected_area = 1
	tree.change_scene_to_file("res://scenes/game.tscn")
	await _wait(30)
	await _shot("3_game_intro")
	_close_modals()
	await _wait(200)
	await _shot("3_game_area1")
	var g := tree.current_scene
	g.set("combo", 19)
	g.call("_on_tap")
	await _wait(3)
	await _shot("3_game_tap")
	# ボス戦
	GameState.selected_area = 5
	save.data.story_seen = [5]
	tree.change_scene_to_file("res://scenes/game.tscn")
	await _wait(5)
	g = tree.current_scene
	g.get_node("Spawner").next_floor = 30
	await _wait(150)
	await _shot("4_game_boss")
	g.call("_open_pause")
	await _wait(5)
	await _shot("4_game_pause")
	g.call("_retreat")
	await _wait(10)
	await _shot("5_result")

	save.data = backup
	save.save_game()
	tree.quit()
