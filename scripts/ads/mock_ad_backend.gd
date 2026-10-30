class_name MockAdBackend
extends AdBackend
## モック広告: 「広告（モック）」とカウントダウンを表示し、AdService.debug_mock_result を返す。

const DURATION_SEC := 2

var _layer: CanvasLayer
var _label: Label


func initialize() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_rewarded_ready() -> bool:
	return true


func show_rewarded(_placement: String) -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 128
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)
	var title := Label.new()
	title.text = Text.AD_MOCK
	title.theme_type_variation = &"TitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_label)
	for i in range(DURATION_SEC, 0, -1):
		_label.text = Text.AD_COUNTDOWN % i
		await get_tree().create_timer(1.0, true, false, true).timeout
	_layer.queue_free()
	finished.emit(AdService.debug_mock_result)
