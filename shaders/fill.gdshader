shader_type spatial;
//render_mode blend_mix;

uniform vec3 color : source_color = vec3(1.0);
uniform vec3 emission_color : source_color = vec3(1.0);
uniform float emission_multiplier = 1.0;
instance uniform float fill : hint_range(0.0, 1.0, 0.1) = 0.0;

void fragment() {
	ALPHA = step(1.0 - fill, UV.y);
	//if (fill < sin(UV.y * TIME)) {
		//ALBEDO = color;
	//} else {
	EMISSION = emission_color * emission_multiplier;
	//}
	
	//if (fill < clamp(UV.y, fill_begin, fill_end)) {
	//} else {
		//ALPHA = 0.0;
	//}
	
}

//void light() {
	//
//}
