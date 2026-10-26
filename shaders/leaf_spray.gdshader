shader_type spatial;
render_mode cull_disabled;
uniform vec4 tint:source_color=vec4(.20,.26,.17,1.0);
void vertex(){
	vec3 w=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	VERTEX.x+=sin(TIME*.65+w.x*.24+w.z*.16)*.0018*smoothstep(.3,1.0,VERTEX.y);
}
void fragment(){
	ALBEDO=tint.rgb*COLOR.rgb;
	ROUGHNESS=.91;SPECULAR=.18;
	if(!FRONT_FACING){NORMAL=-NORMAL;}
}
