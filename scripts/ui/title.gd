extends Control
## タイトル画面。どこかをタップすると Home へ。

@onready var heroine: Heroine = %Heroine
@onready var tap_label: Label = %TapLabel


func _ready() -> void:
	heroine.apply_costume(GameState.equipped_costume())
	var tw := create_tween().set_loops()
	tw.tween_property(tap_label, "modulate:a", 0.2, 0.6)
	tw.tween_property(tap_label, "modulate:a", 1.0, 0.6)
	AudioService.play_bgm("home")


func _gui_input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	var mouse := event as InputEventMouseButton
	if (touch != null and touch.pressed) or (mouse != null and mouse.pressed):
		accept_event()
		AudioService.play_se("button")
		UiUtil.go(get_tree(), "home")
