shader_type spatial;
uniform sampler2D soil_color : source_color,filter_nearest_mipmap,repeat_enable;
uniform sampler2D concrete_color : source_color,filter_nearest_mipmap,repeat_enable;
uniform sampler2D soil_normal : hint_normal,filter_linear_mipmap,repeat_enable;
uniform sampler2D concrete_normal : hint_normal,filter_linear_mipmap,repeat_enable;
uniform sampler2D soil_roughness : filter_linear_mipmap,repeat_enable;
uniform sampler2D concrete_roughness : filter_linear_mipmap,repeat_enable;
uniform bool hardstanding = false;
varying vec3 world_position;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise2(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	vec2 p=world_position.xz;
	float macro=noise2(p*0.43);
	float edge=min(min(p.x+14.0,-3.0-p.x),min(p.y+15.5,-10.0-p.y));
	float pad=hardstanding?smoothstep(0.05,0.65,edge+macro*0.35):0.0;
	float path=(1.0-smoothstep(0.75,1.35,abs(p.x)+(macro-0.5)*0.28))*smoothstep(5.9,6.6,p.y)*(1.0-smoothstep(22.0,24.0,p.y));
	float lane=(1.0-smoothstep(1.7,2.6,abs(p.y-(23.0+0.006*p.x*p.x))+(macro-0.5)*0.35))*(1.0-smoothstep(65.0,82.0,abs(p.x)));
	pad=max(pad,max(path*0.45,lane*0.63));
	vec3 soil=texture(soil_color,p/2.8).rgb*vec3(0.59,0.64,0.66);
	vec3 concrete=texture(concrete_color,p/2.1).rgb*vec3(0.49,0.52,0.53);
	ALBEDO=mix(soil,concrete,pad)*(0.84+macro*0.23);
	NORMAL_MAP=mix(texture(soil_normal,p/2.8).rgb,texture(concrete_normal,p/2.1).rgb,pad);
	float puddle=smoothstep(0.68,0.87,noise2(p*0.32+vec2(17.0,9.0)));
	ALBEDO*=0.91;
	NORMAL_MAP_DEPTH=mix(0.24,0.10,puddle);
	float rough=mix(texture(soil_roughness,p/2.8).r,texture(concrete_roughness,p/2.1).r,pad);
	ROUGHNESS=mix(clamp(0.56+rough*0.22,0.62,0.82),0.43,puddle);SPECULAR=0.25;
}
