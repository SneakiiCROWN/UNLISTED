shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_disabled;
// Original procedural sole silhouette for the INACTIVE property-memory study.
// No raster artwork, identity clue, physical obstacle or new gameplay system.
uniform sampler2D mud_color : source_color,filter_nearest_mipmap,repeat_enable;
uniform float opacity : hint_range(0.0,1.0) = 0.34;
void fragment(){
	vec2 p=floor(UV*vec2(22.0,44.0))/vec2(22.0,44.0);
	float toe=1.0-smoothstep(.87,1.0,length((p-vec2(.52,.30))*vec2(2.55,2.85)));
	float heel=1.0-smoothstep(.85,1.0,length((p-vec2(.48,.79))*vec2(3.1,5.2)));
	float tread=step(.19,fract(p.y*12.0));
	float broken=.65+.35*texture(mud_color,p*2.4).r;
	ALBEDO=texture(mud_color,p*1.4).rgb*vec3(.26,.28,.25);
	ROUGHNESS=.74;SPECULAR=.12;
	ALPHA=max(toe,heel)*mix(.45,1.0,tread)*broken*opacity;
}
