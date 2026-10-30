class_name CostumeData
extends Resource
## 衣装 1 着の定義（見た目のみ）。res://config/costumes/*.tres
##
## sprite_frames を個別のドット絵に差し替えた場合は use_palette を false にする。
## use_palette が true のときは、ヒロインの仮スプライトのキー色（赤/緑/青）を
## 下の 3 色に置き換えるシェーダーで色違いを表現する。

@export var id: StringName = &""
@export var display_name: String = ""
@export_range(1, 3) var rarity: int = 1
## false ならガチャから出ない（初期衣装など）
@export var in_gacha: bool = true
## アニメ名: idle / slash / hurt / down
@export var sprite_frames: SpriteFrames
## ホーム画面の立ち絵（未設定なら共通の立ち絵を使う）
@export var portrait: Texture2D
@export var use_palette: bool = true
@export var primary_color: Color = Color(0.25, 0.45, 0.8)
@export var secondary_color: Color = Color(0.9, 0.85, 0.7)
@export var hair_color: Color = Color(0.85, 0.55, 0.25)


const PALETTE_SHADER := preload("res://assets/shaders/palette_swap.gdshader")
const DEFAULT_PORTRAIT := preload("res://assets/sprites/heroine_portrait.png")


## パレット差し替え用のマテリアル（use_palette が false なら null）
func make_material() -> ShaderMaterial:
	if not use_palette:
		return null
	var m := ShaderMaterial.new()
	m.shader = PALETTE_SHADER
	m.set_shader_parameter("primary_color", primary_color)
	m.set_shader_parameter("secondary_color", secondary_color)
	m.set_shader_parameter("hair_color", hair_color)
	return m


func get_portrait() -> Texture2D:
	return portrait if portrait != null else DEFAULT_PORTRAIT
