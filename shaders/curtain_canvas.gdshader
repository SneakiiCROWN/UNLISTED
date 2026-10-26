shader_type spatial;
render_mode cull_disabled;
uniform sampler2D canvas : source_color, filter_nearest_mipmap, repeat_enable;
uniform float response=0.0;
uniform float drawn=0.0;
void vertex(){
	// Original pleats widen along their actual pole. Never covers more than the
	// existing glazed opening; no collision or doorway changes.
	float target_z=VERTEX.z<2.0 ? 1.04+UV.x*.92 : 2.04+UV.x*.94;
	VERTEX.z=mix(VERTEX.z,target_z,drawn);
	VERTEX.x+=response*UV.y*UV.y;
}
void fragment(){
	vec3 weave=texture(canvas,UV*vec2(.6,3.0)).rgb;
	ALBEDO=mix(vec3(.43,.42,.33),weave*vec3(.65,.64,.52),.27);
	ROUGHNESS=1.0;SPECULAR=.12;
}
