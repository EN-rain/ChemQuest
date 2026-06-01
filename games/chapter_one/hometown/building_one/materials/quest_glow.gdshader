shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 0.9, 0.2, 1.0);
uniform float glow_size = 2.0;
uniform float glow_strength = 1.4;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float alpha = base.a;
	vec2 px = TEXTURE_PIXEL_SIZE * glow_size;

	float outline = 0.0;
	outline += texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
	outline += texture(TEXTURE, UV + vec2(-px.x, 0.0)).a;
	outline += texture(TEXTURE, UV + vec2(0.0, px.y)).a;
	outline += texture(TEXTURE, UV + vec2(0.0, -px.y)).a;
	outline += texture(TEXTURE, UV + vec2(px.x, px.y)).a;
	outline += texture(TEXTURE, UV + vec2(-px.x, px.y)).a;
	outline += texture(TEXTURE, UV + vec2(px.x, -px.y)).a;
	outline += texture(TEXTURE, UV + vec2(-px.x, -px.y)).a;
	outline = clamp(outline, 0.0, 1.0) * (1.0 - alpha);

	vec3 glow = glow_color.rgb * outline * glow_strength;
	COLOR = vec4(base.rgb + glow, max(alpha, outline * glow_color.a));
}
