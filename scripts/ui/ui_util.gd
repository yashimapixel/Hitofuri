class_name UiUtil
extends RefCounted
## UI の小さな共通処理。

const RARITY_COLORS := [Color(0.85, 0.85, 0.85), Color(0.5, 0.75, 1.0), Color(1.0, 0.82, 0.3)]


static func stars(rarity: int) -> String:
	return "★".repeat(rarity)


static func rarity_color(rarity: int) -> Color:
	return RARITY_COLORS[clampi(rarity - 1, 0, 2)]


static func clear_children(node: Node) -> void:
	for c: Node in node.get_children():
		node.remove_child(c)
		c.queue_free()


static func label(text: String, variation: StringName = &"", align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	l.horizontal_alignment = align
	return l


static func button(text: String, on_pressed: Callable, variation: StringName = &"") -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.theme_type_variation = variation
	b.pressed.connect(func() -> void: AudioService.play_se("button"))
	b.pressed.connect(on_pressed)
	return b


## 画面下部に一時的なメッセージを出す
static func toast(parent: Node, text: String, sec: float = 2.0) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(layer)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := label(text, &"SmallLabel", HORIZONTAL_ALIGNMENT_CENTER)
	l.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	l.custom_minimum_size = Vector2(280, 0)
	panel.add_child(l)
	layer.add_child(panel)
	panel.position = Vector2(30, 560)
	panel.modulate.a = 0.0
	var tw := panel.create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.15)
	tw.tween_interval(sec)
	tw.tween_property(panel, "modulate:a", 0.0, 0.3)
	tw.tween_callback(layer.queue_free)


## 画面遷移
static func go(tree: SceneTree, scene: String) -> void:
	tree.change_scene_to_file("res://scenes/%s.tscn" % scene)
