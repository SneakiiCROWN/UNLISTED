shader_type spatial;
uniform vec4 tint : source_color = vec4(0.2,0.18,0.15,1.0);
uniform float sway = 1.0;
varying vec3 world_position;
void vertex(){
	vec3 w=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	VERTEX.x+=sin(TIME*0.41+w.x*0.13+w.z*0.09)*0.005*sway*smoothstep(0.12,1.0,VERTEX.y);
	world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment(){
	float grain=sin(world_position.y*41.0+sin(world_position.x*9.0))*0.025;
	ALBEDO=tint.rgb*COLOR.rgb*(0.975+grain);
	ROUGHNESS=0.97;SPECULAR=0.12;
}
