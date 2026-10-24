shader_type spatial;
render_mode unshaded,cull_disabled;
uniform sampler2D reflected_room : source_color,filter_linear;
void fragment(){
	// Preserve the old horizontal reflection flip and sharp central image. Only
	// the narrow silvered edge has wear; no blur, new feed or distortion pass.
	vec3 reflected=texture(reflected_room,vec2(1.0-UV.x,UV.y)).rgb;
	float edge=min(min(UV.x,1.0-UV.x),min(UV.y,1.0-UV.y));
	float wear=1.0-smoothstep(.004,.025,edge);
	float fleck=.45+.55*step(.55,fract(sin(dot(floor(UV*180.0),vec2(12.7,31.1)))*4375.8));
	ALBEDO=mix(reflected,vec3(.17,.19,.16),wear*fleck*.55);
}
