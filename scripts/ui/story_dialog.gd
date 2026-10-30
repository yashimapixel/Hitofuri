class_name StoryDialog
extends RefCounted
## ステージ紹介（一枚絵＋3行）。そのステージに初めて入ったときに 1 回だけ出す。
## index はエリア番号。エリア数+1 はエンドレス。


static func is_seen(index: int) -> bool:
	for v: Variant in SaveService.data.story_seen:
		if int(v) == index:
			return true
	return false


## 未表示なら Modal を開いて返す（await modal.closed で閉じるのを待てる）。表示済みなら null
static func open_if_new(parent: Node, index: int) -> Modal:
	if is_seen(index) or not Text.STORY.has(index):
		return null
	SaveService.data.story_seen.append(index)
	SaveService.save_game()
	var area := GameState.get_area(mini(index, GameState.area_count()))
	var title := Text.ENDLESS if index > GameState.area_count() else area.display_name
	var m := Modal.open(parent, title, 320)
	var img := TextureRect.new()
	img.texture = area.story_image if area.story_image != null else area.background
	img.custom_minimum_size = Vector2(296, 160)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.clip_contents = true
	m.content.add_child(img)
	var text := UiUtil.label(Text.STORY[index])
	text.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	m.content.add_child(text)
	m.add_close_button(Text.OK)
	return m
