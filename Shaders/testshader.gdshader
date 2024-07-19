shader_type canvas_item;

uniform vec4 base_color : source_color;
const int num_of_provinces = 42;
uniform vec4 colors[num_of_provinces] : source_color;
const float EPSILON = 1.0/256.0;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	
	int idx = 0;
	float idx_f = 0.0;
	while(idx < num_of_provinces) {
		if(EPSILON >= abs(COLOR.r - base_color.r - idx_f/256.0))
			break;
		idx_f += 1.0;
		++idx;
	}
	if(idx != num_of_provinces && COLOR.g == 0.0 && COLOR.b == 0.0)
		COLOR = colors[idx];
	if(COLOR.r >= 0.99 && COLOR.g >= 0.99 && COLOR.b >= 0.99)
		COLOR = vec4(1.0,1.0,1.0,0.0);
}
