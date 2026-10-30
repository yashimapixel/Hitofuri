class_name Modal
extends CanvasLayer
## 画面の上に重ねるダイアログ（ログインボーナス・ミッション・ストーリーなど）。
##   var m := Modal.open(self, "タイトル")
##   m.content.add_child(...)
##   await m.closed

signal closed

var content: VBoxContainer
var panel: PanelContainer


static func open(parent: Node, title: String, width: float = 300.0) -> Modal:
	var m := Modal.new()
	m.layer = 20
	m.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(m)
	m._build(title, width)
	return m


func _build(title: String, width: float) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(width, 348.0), 0)
	center.add_child(panel)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	if title != "":
		content.add_child(UiUtil.label(title, &"TitleLabel", HORIZONTAL_ALIGNMENT_CENTER))
	panel.scale = Vector2(0.9, 0.9)
	panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(panel, "scale", Vector2.ONE, 0.12)
	panel.resized.connect(func() -> void: panel.pivot_offset = panel.size / 2.0)


## 閉じるボタンを追加する
func add_close_button(text: String = Text.CLOSE) -> Button:
	var b := UiUtil.button(text, close)
	content.add_child(b)
	return b


func close() -> void:
	closed.emit()
	queue_free()
