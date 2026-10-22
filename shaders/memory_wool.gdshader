shader_type spatial;
render_mode cull_disabled;
uniform bool rug = false;
uniform sampler2D weave : filter_nearest, repeat_enable;
void fragment(){
 vec2 p=UV*vec2(12.0,18.0);
 float a=step(.50,fract(p.x));float b=step(.50,fract(p.y));
 vec3 base=mix(vec3(.20,.27,.29),vec3(.34,.37,.34),.24*a+.24*b);
 float stripe=step(.945,fract(p.x*.5))+step(.96,fract(p.y*.5));
 if(rug){
  float border=step(UV.x,.08)+step(.92,UV.x)+step(UV.y,.06)+step(.94,UV.y);
  base=mix(vec3(.26,.23,.16),vec3(.38,.32,.22),.24*a+.24*b);
  base=mix(base,vec3(.17,.20,.16),clamp(border,0.,1.));
 }
 ALBEDO=mix(base,vec3(.46,.42,.32),stripe*.20)*(.76+texture(weave,UV*7.0).r*.65);
 ROUGHNESS=.98;
}
