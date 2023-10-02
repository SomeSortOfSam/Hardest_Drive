shader_type canvas_item;

uniform vec2 motion = vec2(0.0);
uniform float scale = 1.0;
uniform vec2 offset = vec2(0.0);

void vertex(){
	UV.x = (VERTEX.x + offset.x + TIME * motion.x) * TEXTURE_PIXEL_SIZE.x * (1.0/scale);
}