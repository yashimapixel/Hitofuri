extends SceneTree
## 仮素材（PNG / SpriteFrames / WAV）を生成するツール。
##   godot --headless -s res://tools/gen_placeholders.gd            # 既存ファイルは上書きしない
##   godot --headless -s res://tools/gen_placeholders.gd -- --force # すべて作り直す
## 本番素材に差し替えたファイルを壊さないよう、既定では既存ファイルをスキップする。

const SPR := "res://assets/sprites/"
const UI := "res://assets/ui/"
const BG := "res://assets/bg/"

# ヒロインのパレットキー色（衣装シェーダーで置き換える）
const KEY_PRIMARY := Color(1, 0, 0)
const KEY_SECONDARY := Color(0, 1, 0)
const KEY_HAIR := Color(0, 0, 1)
const SKIN := Color(1.0, 0.82, 0.68)
const OUTLINE := Color(0.12, 0.08, 0.14)
const STEEL := Color(0.85, 0.9, 0.95)
const GOLD := Color(1.0, 0.8, 0.25)
const BOOTS := Color(0.35, 0.22, 0.15)

var force := false
var rng := RandomNumberGenerator.new()


func _init() -> void:
	force = "--force" in OS.get_cmdline_user_args()
	rng.seed = 12345
	for d in ["assets/sprites/enemies", "assets/sprites/bosses", "assets/sprites/swords", "assets/sprites/fx", "assets/ui", "assets/bg", "assets/sfx", "assets/bgm"]:
		DirAccess.make_dir_recursive_absolute("res://" + d)
	_gen_heroine()
	_gen_enemies()
	_gen_bosses()
	_gen_fx()
	_gen_ui()
	_gen_swords()
	_gen_backgrounds()
	_gen_sfx()
	_gen_bgm()
	print("gen_placeholders: done")
	quit()


# ---------------------------------------------------------------- 書き出し

func _skip(path: String) -> bool:
	return not force and FileAccess.file_exists(path)


func _save_png(img: Image, path: String) -> void:
	if _skip(path):
		return
	img.save_png(ProjectSettings.globalize_path(path))


## sheet_path の画像を frame_size で切り出す SpriteFrames .tres を書き出す。
## anims: [{name, row, count, fps, loop}]
func _write_frames(tres_path: String, sheet_path: String, frame_size: Vector2i, anims: Array) -> void:
	if _skip(tres_path):
		return
	var total := 0
	for a: Dictionary in anims:
		total += int(a.count)
	var s := "[gd_resource type=\"SpriteFrames\" load_steps=%d format=3]\n\n" % (total + 2)
	s += "[ext_resource type=\"Texture2D\" path=\"%s\" id=\"1_sheet\"]\n\n" % sheet_path
	var n := 0
	var anim_entries: PackedStringArray = []
	for a: Dictionary in anims:
		var frames: PackedStringArray = []
		for i in int(a.count):
			n += 1
			var sid := "AtlasTexture_%d" % n
			s += "[sub_resource type=\"AtlasTexture\" id=\"%s\"]\natlas = ExtResource(\"1_sheet\")\nregion = Rect2(%d, %d, %d, %d)\n\n" % [sid, (i + int(a.get("col", 0))) * frame_size.x, int(a.row) * frame_size.y, frame_size.x, frame_size.y]
			frames.append("{\n\"duration\": 1.0,\n\"texture\": SubResource(\"%s\")\n}" % sid)
		anim_entries.append("{\n\"frames\": [%s],\n\"loop\": %s,\n\"name\": &\"%s\",\n\"speed\": %s\n}" % [", ".join(frames), "true" if a.loop else "false", a.name, str(float(a.fps))])
	s += "[resource]\nanimations = [%s]\n" % ", ".join(anim_entries)
	var f := FileAccess.open(tres_path, FileAccess.WRITE)
	f.store_string(s)
	f.close()


# ---------------------------------------------------------------- 描画ヘルパー

func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			_px(img, xx, yy, c)


func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


func _circle(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for yy in range(floori(cy - r), ceili(cy + r) + 1):
		for xx in range(floori(cx - r), ceili(cx + r) + 1):
			if Vector2(xx + 0.5 - cx, yy + 0.5 - cy).length() <= r:
				_px(img, xx, yy, c)


func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for yy in range(floori(cy - ry), ceili(cy + ry) + 1):
		for xx in range(floori(cx - rx), ceili(cx + rx) + 1):
			var dx := (xx + 0.5 - cx) / rx
			var dy := (yy + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				_px(img, xx, yy, c)


func _line(img: Image, a: Vector2, b: Vector2, c: Color, thick: int = 1) -> void:
	var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for i in steps + 1:
		var p := a.lerp(b, float(i) / float(steps))
		_rect(img, floori(p.x - thick / 2.0 + 0.5), floori(p.y - thick / 2.0 + 0.5), thick, thick, c)


func _tri(img: Image, p0: Vector2, p1: Vector2, p2: Vector2, c: Color) -> void:
	var minx := floori(minf(p0.x, minf(p1.x, p2.x)))
	var maxx := ceili(maxf(p0.x, maxf(p1.x, p2.x)))
	var miny := floori(minf(p0.y, minf(p1.y, p2.y)))
	var maxy := ceili(maxf(p0.y, maxf(p1.y, p2.y)))
	for yy in range(miny, maxy + 1):
		for xx in range(minx, maxx + 1):
			var p := Vector2(xx + 0.5, yy + 0.5)
			if Geometry2D.point_is_inside_triangle(p, p0, p1, p2):
				_px(img, xx, yy, c)


## 不透明部分の外側に 1px の輪郭を付ける
func _outline(img: Image, c: Color) -> void:
	var src := img.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q := Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height() and src.get_pixel(q.x, q.y).a > 0.0:
					img.set_pixel(x, y, c)
					break


func _new(w: int, h: int) -> Image:
	return Image.create_empty(w, h, false, Image.FORMAT_RGBA8)


func _tint(img: Image, c: Color, amount: float) -> Image:
	var out := img.duplicate() as Image
	for y in out.get_height():
		for x in out.get_width():
			var p := out.get_pixel(x, y)
			if p.a > 0.0:
				out.set_pixel(x, y, Color(p.lerp(c, amount), p.a))
	return out


# ---------------------------------------------------------------- ヒロイン 48×48

func _heroine_frame(pose: String, f: int) -> Image:
	var img := _new(48, 48)
	var bob := 0
	var dx := 0
	match pose:
		"idle":
			bob = [0, 1, 1, 0][f]
		"hurt":
			dx = [-2, 1][f]
			bob = 1
		"down":
			bob = [1, 4, 0, 0][f]
	var ox := dx
	var oy := bob
	if pose == "down" and f == 1:
		# 膝をつく
		_rect(img, 17 + ox, 34 + oy, 14, 6, KEY_SECONDARY)
		_rect(img, 18 + ox, 24 + oy, 12, 10, KEY_PRIMARY)
		_circle(img, 24 + ox, 18 + oy, 7, KEY_HAIR)
		_rect(img, 22 + ox, 23 + oy, 4, 6, KEY_HAIR)
		_line(img, Vector2(33, 38), Vector2(42, 44), STEEL, 2)
		_outline(img, OUTLINE)
		return img
	# 脚
	_rect(img, 19 + ox, 38 + oy, 4, 6 - bob, BOOTS)
	_rect(img, 25 + ox, 38 + oy, 4, 6 - bob, BOOTS)
	# スカート
	_tri(img, Vector2(24 + ox, 27 + oy), Vector2(13 + ox, 40 + oy), Vector2(35 + ox, 40 + oy), KEY_SECONDARY)
	_rect(img, 18 + ox, 29 + oy, 12, 4, KEY_SECONDARY)
	# 胴
	_rect(img, 17 + ox, 19 + oy, 14, 11, KEY_PRIMARY)
	_rect(img, 17 + ox, 28 + oy, 14, 2, GOLD)
	# 腕
	_rect(img, 14 + ox, 20 + oy, 3, 8, SKIN)
	_rect(img, 31 + ox, 20 + oy, 3, 8, SKIN)
	# 頭（後ろ姿）とポニーテール
	_circle(img, 24 + ox, 12 + oy, 7, KEY_HAIR)
	_rect(img, 22 + ox, 17 + oy, 4, 9, KEY_HAIR)
	_rect(img, 21 + ox, 7 + oy, 6, 1, GOLD)
	# 剣
	match pose:
		"slash":
			match f:
				0:
					_line(img, Vector2(14, 22), Vector2(4, 6), STEEL, 2)
					_rect(img, 12, 21, 4, 3, GOLD)
				1:
					_line(img, Vector2(14, 14), Vector2(46, 10), STEEL, 3)
					_rect(img, 12, 13, 3, 4, GOLD)
				2:
					_line(img, Vector2(34, 22), Vector2(46, 34), STEEL, 2)
					_rect(img, 32, 20, 4, 3, GOLD)
				3:
					_line(img, Vector2(34, 24), Vector2(42, 18), STEEL, 2)
					_rect(img, 32, 24, 4, 2, GOLD)
		"down":
			_line(img, Vector2(36, 40), Vector2(46, 44), STEEL, 2)
		_:
			_line(img, Vector2(34, 24 + oy), Vector2(34, 6 + oy), STEEL, 2)
			_rect(img, 31, 24 + oy, 7, 2, GOLD)
	if pose == "hurt":
		_rect(img, 38, 4, 2, 6, Color(1, 1, 0.6))
		_rect(img, 38, 12, 2, 2, Color(1, 1, 0.6))
	_outline(img, OUTLINE)
	if pose == "down" and f >= 2:
		img.rotate_90(CLOCKWISE)
		var shifted := _new(48, 48)
		shifted.blit_rect(img, Rect2i(0, 0, 48, 48), Vector2i(0, 12 if f == 2 else 14))
		return shifted
	return img


func _gen_heroine() -> void:
	var sheet := _new(48 * 4, 48 * 4)
	var rows := {"idle": [0, 4], "slash": [1, 4], "hurt": [2, 2], "down": [3, 4]}
	for pose: String in rows:
		for f in int(rows[pose][1]):
			sheet.blit_rect(_heroine_frame(pose, f), Rect2i(0, 0, 48, 48), Vector2i(f * 48, int(rows[pose][0]) * 48))
	_save_png(sheet, SPR + "heroine.png")
	_write_frames(SPR + "heroine_frames.tres", SPR + "heroine.png", Vector2i(48, 48), [
		{"name": "idle", "row": 0, "count": 4, "fps": 4, "loop": true},
		{"name": "slash", "row": 1, "count": 4, "fps": 24, "loop": false},
		{"name": "hurt", "row": 2, "count": 2, "fps": 8, "loop": false},
		{"name": "down", "row": 3, "count": 4, "fps": 6, "loop": false},
	])


# ---------------------------------------------------------------- 敵 32×32

func _draw_kind(kind: String, f: int, main: Color, sub: Color) -> Image:
	var img := _new(32, 32)
	var eye := Color(0.1, 0.05, 0.1)
	match kind:
		"slime":
			var squash := f == 1
			_ellipse(img, 16, 22 if not squash else 23, 11 if not squash else 12.5, 8 if not squash else 7, main)
			_ellipse(img, 12, 18, 3, 2, main.lightened(0.4))
			_rect(img, 12, 21, 2, 3, eye)
			_rect(img, 19, 21, 2, 3, eye)
		"bat":
			var up := f == 0
			_circle(img, 16, 16, 6, main)
			if up:
				_tri(img, Vector2(11, 15), Vector2(1, 6), Vector2(4, 19), main.darkened(0.2))
				_tri(img, Vector2(21, 15), Vector2(31, 6), Vector2(28, 19), main.darkened(0.2))
			else:
				_tri(img, Vector2(11, 15), Vector2(1, 25), Vector2(5, 13), main.darkened(0.2))
				_tri(img, Vector2(21, 15), Vector2(31, 25), Vector2(27, 13), main.darkened(0.2))
			_tri(img, Vector2(11, 11), Vector2(13, 6), Vector2(14, 11), main)
			_tri(img, Vector2(18, 11), Vector2(19, 6), Vector2(21, 11), main)
			_rect(img, 13, 15, 2, 2, Color(1, 0.9, 0.3))
			_rect(img, 18, 15, 2, 2, Color(1, 0.9, 0.3))
		"ghost":
			_circle(img, 16, 13, 9, main)
			_rect(img, 7, 13, 19, 10, main)
			for i in 4:
				var wx := 7 + i * 5 + (f * 2)
				_circle(img, wx, 23, 2.5, main)
			_rect(img, 11, 11, 3, 4, eye)
			_rect(img, 18, 11, 3, 4, eye)
		"knight":
			var o := f
			_rect(img, 9, 12 + o, 14, 14, main)
			_rect(img, 10, 4 + o, 12, 9, main.lightened(0.15))
			_rect(img, 11, 8 + o, 10, 2, eye)
			_rect(img, 15, 1 + o, 2, 4, sub)
			_rect(img, 3, 13 + o, 6, 10, sub.darkened(0.2))
			_rect(img, 4, 15 + o, 4, 6, GOLD)
			_rect(img, 10, 26, 4, 5, main.darkened(0.3))
			_rect(img, 18, 26, 4, 5, main.darkened(0.3))
			_line(img, Vector2(25, 26 + o), Vector2(25, 6 + o), STEEL, 2)
		"mage":
			_tri(img, Vector2(16, 9), Vector2(5, 30), Vector2(27, 30), main)
			_circle(img, 16, 12, 5, SKIN)
			_tri(img, Vector2(16, 0), Vector2(8, 10), Vector2(24, 10), main.darkened(0.25))
			_rect(img, 13, 12, 2, 2, eye)
			_rect(img, 18, 12, 2, 2, eye)
			_line(img, Vector2(27, 30), Vector2(27, 10), BOOTS, 2)
			_circle(img, 27, 8, 3 if f == 0 else 4, sub)
		"bullet":
			var r := 6.0 if f == 0 else 7.0
			_circle(img, 16, 16, r + 2, Color(main, 0.45))
			_circle(img, 16, 16, r, main)
			_circle(img, 15, 15, r * 0.45, Color(1, 1, 0.9))
		"witch":
			_tri(img, Vector2(16, 8), Vector2(4, 31), Vector2(28, 31), main)
			_circle(img, 16, 11, 5, Color(0.85, 0.95, 0.8))
			_tri(img, Vector2(18, -1), Vector2(6, 9), Vector2(26, 9), main.darkened(0.3))
			_rect(img, 4, 8, 24, 2, main.darkened(0.3))
			_rect(img, 13, 11, 2, 2, Color(1, 0.3, 0.6))
			_rect(img, 18, 11, 2, 2, Color(1, 0.3, 0.6))
			_line(img, Vector2(3, 31), Vector2(9, 14), BOOTS, 2)
			_circle(img, 9, 13, 2 + f, sub)
		"golem":
			_rect(img, 8, 9, 16, 15, main)
			_rect(img, 11, 2, 10, 8, main.lightened(0.2))
			_rect(img, 2 - f, 10, 6, 12, main.darkened(0.15))
			_rect(img, 24 + f, 10, 6, 12, main.darkened(0.15))
			_rect(img, 9, 24, 5, 7, main.darkened(0.25))
			_rect(img, 18, 24, 5, 7, main.darkened(0.25))
			_rect(img, 13, 5, 2, 2, sub)
			_rect(img, 17, 5, 2, 2, sub)
			_tri(img, Vector2(16, 12), Vector2(12, 20), Vector2(20, 20), sub)
		"dragon":
			_ellipse(img, 16, 20, 9, 8, main)
			_circle(img, 16, 9, 6, main.lightened(0.15))
			_tri(img, Vector2(9, 16), Vector2(0, 4 + f * 4), Vector2(3, 24), main.darkened(0.2))
			_tri(img, Vector2(23, 16), Vector2(32, 4 + f * 4), Vector2(29, 24), main.darkened(0.2))
			_tri(img, Vector2(11, 6), Vector2(9, 0), Vector2(13, 5), sub)
			_tri(img, Vector2(21, 6), Vector2(23, 0), Vector2(19, 5), sub)
			_rect(img, 13, 8, 2, 2, Color(1, 0.2, 0.2))
			_rect(img, 18, 8, 2, 2, Color(1, 0.2, 0.2))
			_ellipse(img, 16, 22, 5, 4, main.lightened(0.35))
		"demon":
			_tri(img, Vector2(16, 10), Vector2(3, 31), Vector2(29, 31), main)
			_circle(img, 16, 11, 6, Color(0.75, 0.7, 0.85))
			_tri(img, Vector2(11, 7), Vector2(6, -1 + f), Vector2(13, 5), sub)
			_tri(img, Vector2(21, 7), Vector2(26, -1 + f), Vector2(19, 5), sub)
			_rect(img, 13, 10, 2, 2, Color(1, 0.1, 0.2))
			_rect(img, 18, 10, 2, 2, Color(1, 0.1, 0.2))
			_rect(img, 9, 18, 14, 2, GOLD)
			_circle(img, 16, 24, 2 + f, Color(1, 0.2, 0.4))
	_outline(img, OUTLINE)
	return img


const ENEMY_DEFS := {
	"slime": ["slime", Color(0.35, 0.8, 0.35), Color.WHITE],
	"bat": ["bat", Color(0.55, 0.35, 0.7), Color.WHITE],
	"ghost": ["ghost", Color(0.92, 0.94, 1.0), Color.WHITE],
	"knight": ["knight", Color(0.6, 0.62, 0.7), Color(0.85, 0.2, 0.2)],
	"mage": ["mage", Color(0.25, 0.35, 0.8), Color(0.6, 0.95, 1.0)],
	"bullet": ["bullet", Color(1.0, 0.55, 0.2), Color.WHITE],
}


func _gen_enemies() -> void:
	for id: String in ENEMY_DEFS:
		var d: Array = ENEMY_DEFS[id]
		var sheet := _new(64, 32)
		for f in 2:
			sheet.blit_rect(_draw_kind(d[0], f, d[1], d[2]), Rect2i(0, 0, 32, 32), Vector2i(f * 32, 0))
		var png := SPR + "enemies/%s.png" % id
		_save_png(sheet, png)
		_write_frames(SPR + "enemies/%s_frames.tres" % id, png, Vector2i(32, 32), [
			{"name": "move", "row": 0, "count": 2, "fps": 6 if id != "bat" else 10, "loop": true},
		])


# ---------------------------------------------------------------- ボス 64×64

const BOSS_DEFS := {
	"area1_mid": ["bat", Color(0.7, 0.3, 0.5), Color.WHITE],
	"area1_boss": ["slime", Color(0.3, 0.75, 0.3), Color.WHITE],
	"area2_mid": ["ghost", Color(0.75, 0.85, 1.0), Color.WHITE],
	"area2_boss": ["witch", Color(0.35, 0.2, 0.5), Color(0.5, 1.0, 0.5)],
	"area3_mid": ["knight", Color(0.45, 0.45, 0.55), Color(0.3, 0.6, 1.0)],
	"area3_boss": ["golem", Color(0.5, 0.75, 0.9), Color(0.9, 0.4, 1.0)],
	"area4_mid": ["mage", Color(0.75, 0.85, 1.0), Color(0.4, 0.8, 1.0)],
	"area4_boss": ["dragon", Color(0.55, 0.8, 0.95), Color(1, 1, 1)],
	"area5_mid": ["demon", Color(0.3, 0.2, 0.35), Color(0.7, 0.7, 0.75)],
	"area5_boss": ["demon", Color(0.5, 0.1, 0.25), Color(1.0, 0.8, 0.3)],
}


func _gen_bosses() -> void:
	for id: String in BOSS_DEFS:
		var d: Array = BOSS_DEFS[id]
		var sheet := _new(64 * 2, 64 * 3)
		for f in 2:
			var a := _draw_kind(d[0], f, d[1], d[2])
			a.resize(64, 64, Image.INTERPOLATE_NEAREST)
			sheet.blit_rect(a, Rect2i(0, 0, 64, 64), Vector2i(f * 64, 0))
			var w := _tint(a, Color(1, 1, 0.8), 0.35 + 0.25 * f)
			sheet.blit_rect(w, Rect2i(0, 0, 64, 64), Vector2i(f * 64, 64))
		var h := _draw_kind(d[0], 0, d[1], d[2])
		h.resize(64, 64, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(_tint(h, Color(1, 0.2, 0.2), 0.5), Rect2i(0, 0, 64, 64), Vector2i(0, 128))
		var png := SPR + "bosses/%s.png" % id
		_save_png(sheet, png)
		_write_frames(SPR + "bosses/%s_frames.tres" % id, png, Vector2i(64, 64), [
			{"name": "idle", "row": 0, "count": 2, "fps": 3, "loop": true},
			{"name": "windup", "row": 1, "count": 2, "fps": 8, "loop": true},
			{"name": "hurt", "row": 2, "count": 1, "fps": 1, "loop": false},
		])
	# ボス弾
	var sheet2 := _new(64, 32)
	for f in 2:
		sheet2.blit_rect(_draw_kind("bullet", f, Color(0.95, 0.3, 0.9), Color.WHITE), Rect2i(0, 0, 32, 32), Vector2i(f * 32, 0))
	_save_png(sheet2, SPR + "bosses/boss_bullet.png")
	_write_frames(SPR + "bosses/boss_bullet_frames.tres", SPR + "bosses/boss_bullet.png", Vector2i(32, 32), [
		{"name": "move", "row": 0, "count": 2, "fps": 10, "loop": true},
	])


# ---------------------------------------------------------------- エフェクト

func _gen_fx() -> void:
	var w := 200
	var h := 24
	var sheet := _new(w * 4, h)
	var widths := [0.45, 1.0, 0.9, 0.7]
	var thick := [2, 5, 3, 1]
	var cols := [Color(1, 1, 1), Color(0.85, 1, 1), Color(0.6, 0.9, 1, 0.85), Color(0.5, 0.8, 1, 0.5)]
	for f in 4:
		var ww := int(w * widths[f])
		var x0 := f * w + (w - ww) / 2
		for x in ww:
			var t := float(x) / float(ww)
			var th := maxi(1, int(round(thick[f] * sin(t * PI))))
			_rect(sheet, x0 + x, h / 2 - th / 2, 1, th, cols[f])
	_save_png(sheet, SPR + "fx/slash.png")
	_write_frames(SPR + "fx/slash_frames.tres", SPR + "fx/slash.png", Vector2i(w, h), [
		{"name": "slash", "row": 0, "count": 4, "fps": 30, "loop": false},
	])
	# 破片パーティクル用
	var deb := _new(4, 4)
	deb.fill(Color.WHITE)
	_save_png(deb, SPR + "fx/debris.png")
	# ガチャの光
	var light := _new(96, 96)
	for y in 96:
		for x in 96:
			var d := Vector2(x - 47.5, y - 47.5).length() / 48.0
			if d < 1.0:
				light.set_pixel(x, y, Color(1, 1, 1, pow(1.0 - d, 1.6)))
	_save_png(light, SPR + "fx/light.png")


# ---------------------------------------------------------------- UI

func _frame_img(fill: Color, border: Color, dark: Color, size: int = 24) -> Image:
	var img := _new(size, size)
	_rect(img, 1, 0, size - 2, size, dark)
	_rect(img, 0, 1, size, size - 2, dark)
	_rect(img, 1, 1, size - 2, size - 2, border)
	_rect(img, 2, 2, size - 4, size - 4, fill)
	_rect(img, 3, 3, size - 6, 1, fill.lightened(0.15))
	return img


func _gen_ui() -> void:
	_save_png(_frame_img(Color(0.1, 0.1, 0.22, 0.94), Color(0.85, 0.8, 0.65), Color(0.03, 0.02, 0.06)), UI + "window.png")
	_save_png(_frame_img(Color(0.22, 0.32, 0.6), Color(0.75, 0.85, 1.0), Color(0.04, 0.04, 0.1)), UI + "button.png")
	_save_png(_frame_img(Color(0.32, 0.44, 0.78), Color(1, 1, 1), Color(0.04, 0.04, 0.1)), UI + "button_hover.png")
	_save_png(_frame_img(Color(0.14, 0.2, 0.42), Color(0.55, 0.65, 0.85), Color(0.04, 0.04, 0.1)), UI + "button_pressed.png")
	_save_png(_frame_img(Color(0.25, 0.25, 0.28), Color(0.45, 0.45, 0.5), Color(0.06, 0.06, 0.08)), UI + "button_disabled.png")
	_save_png(_frame_img(Color(0.85, 0.45, 0.1), Color(1, 0.9, 0.5), Color(0.15, 0.05, 0.0)), UI + "button_accent.png")
	_save_png(_frame_img(Color(1.0, 0.58, 0.2), Color(1, 1, 0.8), Color(0.15, 0.05, 0.0)), UI + "button_accent_hover.png")

	var heart := _new(12, 12)
	_circle(heart, 3.5, 4, 3, Color(0.95, 0.2, 0.3))
	_circle(heart, 8.5, 4, 3, Color(0.95, 0.2, 0.3))
	_tri(heart, Vector2(0.5, 5), Vector2(11.5, 5), Vector2(6, 11), Color(0.95, 0.2, 0.3))
	_px(heart, 3, 3, Color(1, 0.8, 0.8))
	var empty := heart.duplicate() as Image
	_save_png(heart, UI + "heart.png")
	for y in 12:
		for x in 12:
			if empty.get_pixel(x, y).a > 0:
				empty.set_pixel(x, y, Color(0.3, 0.25, 0.3))
	_save_png(empty, UI + "heart_empty.png")

	var coin := _new(12, 12)
	_circle(coin, 6, 6, 5.5, Color(0.6, 0.4, 0.05))
	_circle(coin, 6, 6, 4.5, Color(1.0, 0.82, 0.2))
	_rect(coin, 5, 3, 2, 6, Color(0.8, 0.55, 0.1))
	_save_png(coin, UI + "coin.png")

	for t: Array in [["ticket", Color(0.95, 0.45, 0.65)], ["ticket_r2", Color(0.35, 0.6, 1.0)], ["ticket_r3", Color(1.0, 0.8, 0.25)]]:
		var tk := _new(12, 12)
		_rect(tk, 0, 2, 12, 8, t[1])
		_rect(tk, 0, 5, 1, 2, Color(0, 0, 0, 0))
		_rect(tk, 11, 5, 1, 2, Color(0, 0, 0, 0))
		_rect(tk, 4, 3, 1, 6, Color(1, 1, 1, 0.7))
		_save_png(tk, UI + "%s.png" % t[0])

	var guard := _new(12, 12)
	_rect(guard, 2, 1, 8, 6, Color(0.5, 0.8, 1.0))
	_tri(guard, Vector2(2, 6), Vector2(10, 6), Vector2(6, 11.5), Color(0.5, 0.8, 1.0))
	_rect(guard, 5, 2, 2, 6, Color(1, 1, 1))
	_save_png(guard, UI + "guard.png")

	var pause := _new(16, 16)
	_rect(pause, 4, 3, 3, 10, Color.WHITE)
	_rect(pause, 9, 3, 3, 10, Color.WHITE)
	_save_png(pause, UI + "pause.png")

	var star := _new(8, 8)
	_tri(star, Vector2(4, 0), Vector2(1, 7), Vector2(7, 7), GOLD)
	_tri(star, Vector2(0, 2.5), Vector2(8, 2.5), Vector2(4, 6), GOLD)
	_save_png(star, UI + "star.png")

	var badge := _new(8, 8)
	_circle(badge, 4, 4, 3.5, Color(1, 0.2, 0.2))
	_rect(badge, 3, 2, 2, 3, Color.WHITE)
	_px(badge, 3, 6, Color.WHITE)
	_px(badge, 4, 6, Color.WHITE)
	_save_png(badge, UI + "badge.png")

	# 宝箱 48×48（closed / open）
	var chest := _new(96, 48)
	for f in 2:
		var c := _new(48, 48)
		var wood := Color(0.6, 0.35, 0.15)
		_rect(c, 6, 22, 36, 20, wood)
		_rect(c, 6, 30, 36, 3, GOLD)
		if f == 0:
			_rect(c, 6, 12, 36, 11, wood.lightened(0.1))
			_rect(c, 21, 18, 6, 8, GOLD)
		else:
			_rect(c, 6, 4, 36, 8, wood.lightened(0.1))
			_rect(c, 8, 18, 32, 5, Color(1, 1, 0.8))
		_rect(c, 10, 22, 3, 20, GOLD)
		_rect(c, 35, 22, 3, 20, GOLD)
		_outline(c, OUTLINE)
		chest.blit_rect(c, Rect2i(0, 0, 48, 48), Vector2i(f * 48, 0))
	_save_png(chest, UI + "chest.png")
	_write_frames(UI + "chest_frames.tres", UI + "chest.png", Vector2i(48, 48), [
		{"name": "closed", "row": 0, "count": 1, "fps": 1, "loop": false},
		{"name": "open", "row": 0, "col": 1, "count": 1, "fps": 1, "loop": false},
	])

	# アイコン（剣のエンブレム）
	for size: int in [192, 432]:
		var bg := _new(size, size)
		for y in size:
			for x in size:
				var t := float(y) / size
				bg.set_pixel(x, y, Color(0.16, 0.12, 0.35).lerp(Color(0.45, 0.2, 0.45), t))
		var fg := _new(size, size)
		var s := size / 48.0
		var art := _new(48, 48)
		_line(art, Vector2(12, 36), Vector2(36, 12), STEEL, 4)
		_line(art, Vector2(14, 36), Vector2(37, 13), Color(1, 1, 1), 1)
		_line(art, Vector2(9, 31), Vector2(17, 39), GOLD, 3)
		_line(art, Vector2(8, 40), Vector2(12, 36), BOOTS, 3)
		_circle(art, 38, 10, 3, Color(1, 1, 0.8, 0.8))
		_outline(art, OUTLINE)
		art.resize(int(48 * s), int(48 * s), Image.INTERPOLATE_NEAREST)
		if size == 432:
			# アダプティブアイコンは中央 66% が安全領域
			art.resize(288, 288, Image.INTERPOLATE_NEAREST)
			fg.blit_rect(art, Rect2i(0, 0, 288, 288), Vector2i(72, 72))
			_save_png(fg, UI + "icon_foreground.png")
			_save_png(bg, UI + "icon_background.png")
		else:
			bg.blend_rect(art, Rect2i(0, 0, size, size), Vector2i.ZERO)
			_save_png(bg, UI + "icon.png")
	var splash := _new(192, 192)
	var art2 := _new(48, 48)
	_line(art2, Vector2(12, 36), Vector2(36, 12), STEEL, 4)
	_line(art2, Vector2(9, 31), Vector2(17, 39), GOLD, 3)
	_line(art2, Vector2(8, 40), Vector2(12, 36), BOOTS, 3)
	_outline(art2, OUTLINE)
	art2.resize(144, 144, Image.INTERPOLATE_NEAREST)
	splash.blit_rect(art2, Rect2i(0, 0, 144, 144), Vector2i(24, 24))
	_save_png(splash, UI + "boot_splash.png")


# ---------------------------------------------------------------- 剣アイコン 16×16

const SWORD_COLORS := [
	Color(0.75, 0.75, 0.75), Color(0.6, 0.65, 0.7), Color(0.85, 0.75, 0.55), Color(0.65, 0.45, 0.25),
	Color(0.9, 0.95, 1.0), Color(0.5, 1.0, 0.7), Color(0.5, 0.75, 1.0), Color(1.0, 0.45, 0.2),
	Color(0.6, 1.0, 0.6), Color(1.0, 0.95, 0.6), Color(0.8, 0.6, 1.0), Color(1.0, 0.3, 0.35),
]


func _gen_swords() -> void:
	for i in 12:
		var img := _new(16, 16)
		_line(img, Vector2(4, 11), Vector2(13, 2), SWORD_COLORS[i], 2)
		_line(img, Vector2(2, 9), Vector2(6, 13), GOLD if i >= 9 else Color(0.6, 0.45, 0.3), 1)
		_line(img, Vector2(1, 14), Vector2(4, 11), BOOTS, 2)
		_outline(img, OUTLINE)
		_save_png(img, SPR + "swords/sword_%02d.png" % (i + 1))


# ---------------------------------------------------------------- 背景 360×640（縦にループ可能）

func _gen_backgrounds() -> void:
	var defs := {
		"area1": [Color(0.38, 0.62, 0.3), "grass"],
		"area2": [Color(0.15, 0.3, 0.2), "forest"],
		"area3": [Color(0.12, 0.1, 0.25), "crystal"],
		"area4": [Color(0.72, 0.8, 0.9), "snow"],
		"area5": [Color(0.18, 0.12, 0.2), "castle"],
	}
	for id: String in defs:
		var base: Color = defs[id][0]
		var kind: String = defs[id][1]
		var img := _new(360, 640)
		img.fill(base)
		rng.seed = hash(id)
		match kind:
			"grass":
				for i in 400:
					var x := rng.randi_range(0, 359)
					var y := rng.randi_range(0, 639)
					_rect(img, x, y, 1, 3, base.darkened(0.25))
					_rect(img, x + 2, (y + 1) % 640, 1, 2, base.darkened(0.2))
				for i in 60:
					var c: Color = [Color(1, 1, 1), Color(1, 0.9, 0.3), Color(1, 0.6, 0.7)][i % 3]
					_rect(img, rng.randi_range(0, 358), rng.randi_range(0, 638), 2, 2, c)
				_rect(img, 150, 0, 60, 640, base.lightened(0.08))
			"forest":
				for x0: int in [0, 300]:
					_rect(img, x0, 0, 60, 640, base.darkened(0.35))
					for i in 40:
						_circle(img, x0 + rng.randi_range(0, 60), rng.randi_range(0, 640), rng.randi_range(10, 20), Color(0.1, 0.4, 0.2))
				for i in 120:
					_rect(img, rng.randi_range(60, 300), rng.randi_range(0, 639), 2, 2, Color(0.75, 1, 0.5, 0.6))
			"crystal":
				for i in 40:
					var cx := rng.randi_range(0, 359)
					var cy := rng.randi_range(0, 639)
					var hgt := rng.randi_range(12, 30)
					var col := Color(0.4, 0.9, 1.0, 0.8) if i % 2 == 0 else Color(0.8, 0.5, 1.0, 0.8)
					_tri(img, Vector2(cx, cy - hgt), Vector2(cx - 6, cy), Vector2(cx + 6, cy), col)
				for i in 200:
					_px(img, rng.randi_range(0, 359), rng.randi_range(0, 639), Color(1, 1, 1, 0.6))
			"snow":
				for i in 30:
					_ellipse(img, rng.randi_range(0, 359), rng.randi_range(0, 639), rng.randi_range(10, 24), rng.randi_range(5, 10), Color(0.55, 0.6, 0.7))
				for i in 500:
					_rect(img, rng.randi_range(0, 359), rng.randi_range(0, 639), 1 + i % 2, 1 + i % 2, Color(1, 1, 1))
			"castle":
				for y in range(0, 640, 16):
					var off := 0 if (y / 16) % 2 == 0 else 16
					for x in range(-16, 360, 32):
						_rect(img, x + off, y, 31, 15, base.lightened(0.07 + rng.randf() * 0.06))
				for y in range(40, 640, 160):
					for x: int in [24, 330]:
						_rect(img, x, y, 6, 14, Color(0.4, 0.25, 0.1))
						_circle(img, x + 3, y - 3, 4, Color(1, 0.6, 0.2))
						_circle(img, x + 3, y - 4, 2, Color(1, 1, 0.6))
				_rect(img, 130, 0, 100, 640, Color(0.45, 0.08, 0.15))
				_rect(img, 134, 0, 2, 640, GOLD)
				_rect(img, 224, 0, 2, 640, GOLD)
		_save_png(img, BG + "%s.png" % id)
	# Home
	var home := _new(360, 640)
	for y in 640:
		var t := float(y) / 640.0
		var c := Color(0.35, 0.55, 0.9).lerp(Color(1.0, 0.75, 0.55), clampf(t * 1.6, 0, 1))
		if y > 430:
			c = Color(0.45, 0.62, 0.35).darkened((y - 430) / 600.0)
		for x in 360:
			home.set_pixel(x, y, c)
	rng.seed = 99
	for i in 6:
		var bx := 10 + i * 60
		var bh := rng.randi_range(60, 110)
		_rect(home, bx, 430 - bh, 46, bh, Color(0.85, 0.78, 0.65))
		_tri(home, Vector2(bx - 4, 430 - bh), Vector2(bx + 50, 430 - bh), Vector2(bx + 23, 430 - bh - 26), Color(0.7, 0.3, 0.25))
		_rect(home, bx + 18, 430 - 22, 10, 22, Color(0.4, 0.25, 0.15))
		_rect(home, bx + 6, 430 - bh + 12, 8, 8, Color(1, 0.95, 0.6))
	for i in 5:
		_ellipse(home, rng.randi_range(0, 360), rng.randi_range(40, 200), rng.randi_range(20, 40), 8, Color(1, 1, 1, 0.8))
	_save_png(home, BG + "home.png")


# ---------------------------------------------------------------- サウンド（簡易合成）

const RATE := 22050


func _write_wav(path: String, samples: PackedFloat32Array) -> void:
	if _skip(path):
		return
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_buffer("RIFF".to_ascii_buffer())
	f.store_32(36 + data.size())
	f.store_buffer("WAVEfmt ".to_ascii_buffer())
	f.store_32(16)
	f.store_16(1)
	f.store_16(1)
	f.store_32(RATE)
	f.store_32(RATE * 2)
	f.store_16(2)
	f.store_16(16)
	f.store_buffer("data".to_ascii_buffer())
	f.store_32(data.size())
	f.store_buffer(data)
	f.close()


func _osc(wave: String, phase: float) -> float:
	var p := fposmod(phase, 1.0)
	match wave:
		"square":
			return 1.0 if p < 0.5 else -1.0
		"pulse":
			return 1.0 if p < 0.25 else -1.0
		"tri":
			return 4.0 * absf(p - 0.5) - 1.0
		"saw":
			return 2.0 * p - 1.0
		"noise":
			return rng.randf_range(-1.0, 1.0)
	return sin(p * TAU)


## 周波数を f0→f1 に変化させる単音。
func _tone(f0: float, f1: float, dur: float, wave: String, vol: float, attack: float = 0.005) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		var freq := lerpf(f0, f1, t)
		phase += freq / RATE
		var env := minf(1.0, float(i) / (attack * RATE)) * pow(1.0 - t, 1.5)
		out[i] = _osc(wave, phase) * vol * env
	return out


func _concat(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for p: PackedFloat32Array in parts:
		out.append_array(p)
	return out


func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var n := maxi(a.size(), b.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = (a[i] if i < a.size() else 0.0) + (b[i] if i < b.size() else 0.0)
	return out


func _note(semi: int) -> float:
	return 440.0 * pow(2.0, (semi - 9) / 12.0) # semi=0 は C4


func _gen_sfx() -> void:
	var sfx := {
		"slash": _tone(1800, 500, 0.08, "noise", 0.35),
		"perfect": _concat([_tone(_note(24), _note(24), 0.06, "square", 0.25), _tone(_note(31), _note(31), 0.14, "square", 0.25)]),
		"good": _tone(_note(19), _note(19), 0.1, "square", 0.22),
		"whiff": _tone(600, 200, 0.12, "noise", 0.18, 0.03),
		"damage": _mix(_tone(300, 80, 0.3, "square", 0.3), _tone(800, 100, 0.2, "noise", 0.25)),
		"kill": _tone(900, 120, 0.12, "noise", 0.3),
		"coin": _concat([_tone(_note(35), _note(35), 0.04, "square", 0.15), _tone(_note(40), _note(40), 0.1, "square", 0.15)]),
		"reflect": _mix(_tone(_note(36), _note(43), 0.12, "tri", 0.4), _tone(2000, 1000, 0.06, "noise", 0.15)),
		"boss_kill": _mix(_tone(400, 40, 0.8, "noise", 0.45, 0.01), _tone(_note(12), _note(0), 0.6, "square", 0.2)),
		"windup": _tone(_note(12), _note(24), 0.25, "pulse", 0.12, 0.05),
		"gacha_1": _concat([_tone(_note(12), _note(12), 0.08, "square", 0.2), _tone(_note(19), _note(19), 0.2, "square", 0.2)]),
		"gacha_2": _concat([_tone(_note(12), _note(12), 0.07, "square", 0.2), _tone(_note(16), _note(16), 0.07, "square", 0.2), _tone(_note(19), _note(19), 0.07, "square", 0.2), _tone(_note(24), _note(24), 0.25, "square", 0.2)]),
		"gacha_3": _concat([_tone(_note(12), _note(12), 0.06, "square", 0.2), _tone(_note(16), _note(16), 0.06, "square", 0.2), _tone(_note(19), _note(19), 0.06, "square", 0.2), _tone(_note(24), _note(24), 0.06, "square", 0.2), _tone(_note(28), _note(28), 0.06, "square", 0.2), _tone(_note(31), _note(31), 0.45, "square", 0.22)]),
		"chest_shake": _tone(200, 150, 0.06, "noise", 0.15),
		"button": _tone(_note(26), _note(26), 0.04, "square", 0.15),
		"guard": _tone(_note(28), _note(40), 0.15, "tri", 0.35),
		"heal": _concat([_tone(_note(24), _note(24), 0.06, "tri", 0.3), _tone(_note(28), _note(28), 0.06, "tri", 0.3), _tone(_note(31), _note(31), 0.12, "tri", 0.3)]),
		"boss_appear": _tone(_note(0), _note(-12), 0.7, "saw", 0.2, 0.05),
	}
	for key: String in sfx:
		_write_wav("res://assets/sfx/%s.wav" % key, sfx[key])


## コード進行からアルペジオのメロディとベースを作る簡易シーケンサー。
func _song(bpm: float, chords: Array, pattern: Array, bars: int, lead_wave: String) -> PackedFloat32Array:
	var eighth := 60.0 / bpm / 2.0
	var step_n := int(eighth * RATE)
	var total := step_n * 8 * bars
	var out := PackedFloat32Array()
	out.resize(total)
	var lphase := 0.0
	var bphase := 0.0
	for bar in bars:
		var chord: Array = chords[bar % chords.size()]
		var pat: Array = pattern[bar % pattern.size()]
		for s in 8:
			var idx: int = pat[s]
			var bass_semi: int = chord[0] - 24
			for i in step_n:
				var gi := (bar * 8 + s) * step_n + i
				var t := float(i) / step_n
				var v := 0.0
				if idx >= 0:
					var semi: int = chord[idx % chord.size()] + 12 * (idx / chord.size())
					lphase += _note(semi) / RATE
					v += _osc(lead_wave, lphase) * 0.11 * (1.0 - t * 0.6)
				# ベース（4分音符でオクターブ跳躍）
				var bs := bass_semi + (12 if s % 4 == 2 else 0)
				bphase += _note(bs) / RATE
				v += _osc("tri", bphase) * 0.2 * (1.0 - fposmod(float(s % 2) + t, 2.0) * 0.3)
				# ハイハット
				if s % 2 == 1 and i < step_n / 6:
					v += rng.randf_range(-1, 1) * 0.04
				out[gi] = v
	return out


func _gen_bgm() -> void:
	# 和音は C4=0 基準の半音（ルート, 3度, 5度）
	var C := [12, 16, 19]
	var Am := [9, 12, 16]
	var F := [5, 9, 12]
	var G := [7, 11, 14]
	var Dm := [2, 5, 9]
	var Bb := [10, 14, 17]
	var A := [9, 13, 16]
	var E := [4, 8, 11]
	_write_wav("res://assets/bgm/home.wav", _song(96, [C, Am, F, G], [[0, -1, 1, -1, 2, -1, 1, -1], [3, -1, 2, -1, 1, -1, 2, -1]], 8, "tri"))
	_write_wav("res://assets/bgm/battle.wav", _song(150, [Am, F, C, G], [[0, 2, 1, 2, 3, 2, 1, 2], [0, 2, 1, 3, 4, 3, 2, 1], [3, 2, 1, 0, 1, 2, 3, 5], [4, 3, 2, 1, 2, 3, 4, -1]], 8, "pulse"))
	_write_wav("res://assets/bgm/boss.wav", _song(165, [Dm, Bb, C, A, Dm, Bb, E, A], [[0, 0, 2, 0, 1, 0, 3, 2], [0, 3, 2, 3, 1, 3, 4, 3]], 8, "square"))
	_write_wav("res://assets/bgm/result.wav", _song(120, [C, F, G, C], [[0, 1, 2, 3, 2, 1, 2, -1], [3, -1, 4, -1, 5, -1, 3, -1]], 4, "square"))
