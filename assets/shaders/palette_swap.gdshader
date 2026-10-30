shader_type canvas_item;
// ヒロイン仮スプライトのキー色（赤/緑/青）を衣装の色に置き換える。
// 個別のドット絵に差し替えた衣装では CostumeData.use_palette = false にしてこのシェーダーを外す。

uniform vec4 primary_color : source_color = vec4(0.25, 0.45, 0.8, 1.0);
uniform vec4 secondary_color : source_color = vec4(0.9, 0.85, 0.7, 1.0);
uniform vec4 hair_color : source_color = vec4(0.85, 0.55, 0.25, 1.0);
uniform float tolerance = 0.1;
uniform float flash : hint_range(0.0, 1.0) = 0.0;

const vec3 KEY_PRIMARY = vec3(1.0, 0.0, 0.0);
const vec3 KEY_SECONDARY = vec3(0.0, 1.0, 0.0);
const vec3 KEY_HAIR = vec3(0.0, 0.0, 1.0);

varying vec4 modulate;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (distance(c.rgb, KEY_PRIMARY) < tolerance) {
		c.rgb = primary_color.rgb;
	} else if (distance(c.rgb, KEY_SECONDARY) < tolerance) {
		c.rgb = secondary_color.rgb;
	} else if (distance(c.rgb, KEY_HAIR) < tolerance) {
		c.rgb = hair_color.rgb;
	}
	c.rgb = mix(c.rgb, vec3(1.0), flash);
	COLOR = c * modulate;
}
