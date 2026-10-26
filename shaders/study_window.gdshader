shader_type spatial;
render_mode blend_mix,depth_prepass_alpha,cull_disabled;
varying vec3 world_position;
float hash(float p){return fract(sin(p*127.1)*43758.5453);}
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float edge=min(min(UV.x,1.0-UV.x),min(UV.y,1.0-UV.y));
 float grime=1.0-smoothstep(.02,.16,edge);
 // Thin vertical trails on existing glass, not opaque mirror panels.
 float stripe=floor(UV.x*71.0);
 float run=fract(UV.y*1.2+TIME*.035+hash(stripe)*3.0);
 float bead=pow(max(0.0,1.0-abs(fract(UV.x*71.0)-.5)*12.0),3.0);
 float streak=bead*smoothstep(.25,.65,run)*(1.0-smoothstep(.72,.96,run));
 ALBEDO=mix(vec3(.13,.17,.18),vec3(.19,.18,.14),grime*.6);
 ALPHA=.055+grime*.09+streak*.04;
 ROUGHNESS=mix(.32,.63,grime);SPECULAR=.42;
 NORMAL=normalize(NORMAL+vec3(streak*.07,0.0,0.0));
}
