shader_type spatial;
render_mode cull_disabled;
uniform sampler2D canvas : source_color, filter_nearest_mipmap, repeat_enable;
uniform float response=0.0;
void vertex(){VERTEX.x+=response*UV.y*UV.y;}
void fragment(){
	vec3 weave=texture(canvas,UV*vec2(.6,3.0)).rgb;
	ALBEDO=mix(vec3(.43,.42,.33),weave*vec3(.65,.64,.52),.27);
	ROUGHNESS=1.0;SPECULAR=.12;
}
