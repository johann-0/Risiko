shader_type canvas_item;

uniform int num_of_provinces;
const int max_num_of_provinces = 100;
uniform vec4 base_color : source_color;
uniform vec4 colors[max_num_of_provinces] : source_color;
const float EPSILON = 1.0/256.0;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	// If COLOR is white, then make it transparent
	if(COLOR.r >= 0.999 && COLOR.g >= 0.999 && COLOR.b >= 0.9999) {
		COLOR = vec4(1.0,1.0,1.0,0.0);
	} else if(COLOR.g == 0.0 && COLOR.b == 0.0) {
		// Get the index of the color
		int idx = 0;
		float idx_f = 0.0;
		while(idx < num_of_provinces) {
			if(EPSILON >= abs(COLOR.r - base_color.r - idx_f/256.0))
				break;
			idx_f += 1.0;
			++idx;
		}
		// If the index is acceptable, then set it to its mapped color
		if(idx != num_of_provinces)
			COLOR = colors[idx];
	}
}
