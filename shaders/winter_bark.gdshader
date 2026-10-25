shader_type spatial;
varying vec3 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	float groove=sin(world_position.x*39.0+sin(world_position.y*2.1)+world_position.z*33.0);
	float fleck=sin(world_position.y*31.0+world_position.x*17.0)*sin(world_position.z*29.0);
	ALBEDO=vec3(.095,.092,.072)*(0.85+groove*.10+fleck*.09)*COLOR.rgb;
	ROUGHNESS=.93;SPECULAR=.13;
}
