shader_type spatial;
uniform sampler2D concrete:source_color,filter_nearest_mipmap,repeat_enable;
varying vec3 world_point;
varying vec3 wall_normal;
void vertex(){world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;wall_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
	vec2 uv=abs(wall_normal.x)>.5 ? world_point.zy : world_point.xy;
	vec3 aggregate=texture(concrete,uv*.46).rgb;
	float streak=sin(uv.x*19.0+sin(uv.x*4.7)*2.0)*.5+.5;
	float damp=(1.0-smoothstep(-2.95,-1.50+streak*.27,world_point.y))*.22;
	float lift=smoothstep(.015,.045,abs(fract((world_point.y+3.0)/.72)-.5));
	ALBEDO=aggregate*vec3(.62,.64,.59)*(1.0-damp)*mix(.94,1.0,lift);
	ROUGHNESS=.94-damp*.45;SPECULAR=.18;
}
