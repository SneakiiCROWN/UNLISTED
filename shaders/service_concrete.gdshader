shader_type spatial;
uniform sampler2D concrete : source_color,filter_nearest_mipmap,repeat_enable;
uniform sampler2D roughness_map : filter_linear_mipmap,repeat_enable;
uniform float floor_level = -3.0;
varying vec3 world_position;
varying vec3 wall_normal;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;wall_normal=normalize((MODEL_MATRIX*vec4(NORMAL,0.0)).xyz);}
void fragment(){
	vec2 plane=abs(wall_normal.x)>.5?world_position.zy:world_position.xy;
	vec2 uv=plane/2.1;
	vec3 stone=texture(concrete,uv).rgb;
	float aggregate=texture(concrete,uv*2.3+vec2(.31,.17)).r;
	float low=1.0-smoothstep(.12,.72,world_position.y-floor_level+(aggregate-.5)*.32);
	float run=pow(.5+.5*sin(plane.x*19.0+sin(plane.x*3.7)),9.0)*.05;
	ALBEDO=stone*vec3(.62,.65,.59)*(1.0-low*.12-run);
	ROUGHNESS=mix(.79,.95,texture(roughness_map,uv).r)-low*.05;
	SPECULAR=.16;
}
