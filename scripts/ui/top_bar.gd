class_name TopBar
extends PanelContainer
## 画面上部のヘッダー: 所持コイン・ガチャチケット（コインの右）と、設定ボタン（右上）。

## true なら右上に設定ボタンを出す（Home）
@export var show_settings: bool = false

@onready var coin_label: Label = %CoinLabel
@onready var ticket_label: Label = %TicketLabel
@onready var r2_box: Control = %R2Box
@onready var r2_label: Label = %R2Label
@onready var r3_box: Control = %R3Box
@onready var r3_label: Label = %R3Label
@onready var settings_button: Button = %SettingsButton


func _ready() -> void:
	settings_button.visible = show_settings
	settings_button.pressed.connect(func() -> void:
		AudioService.play_se("button")
		UiUtil.go(get_tree(), "settings"))
	SaveService.changed.connect(refresh)
	refresh()


func refresh() -> void:
	coin_label.text = str(SaveService.coins())
	ticket_label.text = str(SaveService.item_count("tickets"))
	var r2 := SaveService.item_count("tickets_r2")
	var r3 := SaveService.item_count("tickets_r3")
	r2_label.text = str(r2)
	r3_label.text = str(r3)
	r2_box.visible = r2 > 0
	r3_box.visible = r3 > 0
