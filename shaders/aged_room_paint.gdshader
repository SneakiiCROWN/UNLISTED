shader_type spatial;
uniform sampler2D paper : source_color, filter_nearest_mipmap, repeat_enable;
varying vec3 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	float wear=texture(paper,vec2(world_position.x+world_position.z,world_position.y)*.65).r;
	float foot=1.0-smoothstep(.04,.26,world_position.y);
	ALBEDO=vec3(.14,.18,.14)*(.88+wear*.16-foot*.08);
	ROUGHNESS=.96;SPECULAR=.12;
}
