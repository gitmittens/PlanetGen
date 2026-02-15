shader_type spatial;


uniform sampler2D planet_texture : filter_nearest;
uniform float height_scale = 0.5;


void vertex() {
	vec4 tex_data = texture(planet_texture, UV);
	float h = tex_data.a;
	VERTEX += NORMAL * h * height_scale;
}


void fragment() {
	vec4 tex_data = texture(planet_texture, UV);
	ALBEDO = tex_data.rgb;
}