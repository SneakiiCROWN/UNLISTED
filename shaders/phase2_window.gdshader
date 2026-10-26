shader_type spatial;
render_mode blend_mix,depth_prepass_alpha,cull_disabled;
uniform samplerCube room_return : source_color,filter_linear_mipmap,hint_default_black;
uniform float reflection_strength : hint_range(0.0,1.0)=.32;
uniform float motion=1.0;
varying vec3 world_position;
varying vec3 world_normal;
float hash(float p){return fract(sin(p*127.1)*43758.5453);}
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 float edge=min(min(UV.x,1.0-UV.x),min(UV.y,1.0-UV.y));
 float dirt=(1.0-smoothstep(.015,.12,edge))*(.7+.3*hash(floor(UV.x*91.0)));
 float column=floor(UV.x*83.0);
 float phase=fract(UV.y*1.4+TIME*.027*motion+hash(column)*4.0);
 float stripe=pow(max(0.0,1.0-abs(fract(UV.x*83.0)-.5)*15.0),3.0);
 float drop=stripe*smoothstep(.15,.55,phase)*(1.0-smoothstep(.7,.95,phase));
 vec3 eye=INV_VIEW_MATRIX[3].xyz;
 vec3 n=normalize(world_normal)*(FRONT_FACING?1.0:-1.0);
 vec3 ray=reflect(normalize(world_position-eye),n);
 // Box-projected precomputed actual lounge. Never reflects dynamic actors.
 vec3 p=clamp(world_position,vec3(1.61,.01,-2.99),vec3(7.39,2.79,3.89));
 vec3 inv=1.0/(ray+vec3(.00001));
 vec3 t=max((vec3(1.6,0.0,-3.0)-p)*inv,(vec3(7.4,2.8,3.9)-p)*inv);
 float hit=min(t.x,min(t.y,t.z));
 vec3 lookup=normalize(p+ray*hit-vec3(5.0,1.4,1.0));
 bool interior=eye.x>1.5 && eye.x<7.45 && eye.z>-3.0 && eye.z<4.0;
 float fresnel=pow(1.0-abs(dot(normalize(eye-world_position),n)),3.0);
 vec3 returned=textureLod(room_return,lookup,2.0+dirt*2.0).rgb;
 ALBEDO=mix(vec3(.12,.16,.17),vec3(.18,.16,.12),dirt);
 ALPHA=.028+dirt*.055+drop*.03+fresnel*.022;
 ROUGHNESS=.30+dirt*.32+hash(column)*.035;SPECULAR=.14;
 EMISSION=returned*reflection_strength*(interior?1.0:0.0)*(.8+fresnel*.7);
 NORMAL=normalize(NORMAL+vec3(drop*.06,0.0,0.0));
}
