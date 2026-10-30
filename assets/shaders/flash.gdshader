shader_type canvas_item;
// 白く点滅させる（撃破時・ボスの攻撃予備動作）。flash = 1 で真っ白。

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);

varying vec4 modulate;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	c.rgb = mix(c.rgb, flash_color.rgb, flash);
	COLOR = c * modulate;
}
