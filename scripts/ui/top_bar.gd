class_name TopBar
extends PanelContainer
## 画面上部の所持コイン・ガチャチケット表示。

@onready var coin_label: Label = %CoinLabel
@onready var ticket_label: Label = %TicketLabel
@onready var r2_box: Control = %R2Box
@onready var r2_label: Label = %R2Label
@onready var r3_box: Control = %R3Box
@onready var r3_label: Label = %R3Label


func _ready() -> void:
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
