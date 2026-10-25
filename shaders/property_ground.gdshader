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
// Render-only wear follows the existing movement routes. No vertex displacement,
// new terrain, collision edits or puddle meshes laid over the service openings.
float segment_distance(vec2 p,vec2 a,vec2 b){vec2 d=b-a;return length(p-a-d*clamp(dot(p-a,d)/dot(d,d),0.0,1.0));}
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	vec2 p=world_position.xz;
	float macro=noise2(p*0.43);
	float fine=noise2(p*2.7+vec2(4.2,19.7));
	float edge=min(min(p.x+14.0,-3.0-p.x),min(p.y+15.5,-10.0-p.y));
	float pad=hardstanding?smoothstep(0.05,0.65,edge+macro*0.35):0.0;
	float path=(1.0-smoothstep(0.75,1.35,abs(p.x)+(macro-0.5)*0.28))*smoothstep(5.9,6.6,p.y)*(1.0-smoothstep(22.0,24.0,p.y));
	float lane=(1.0-smoothstep(1.7,2.6,abs(p.y-(23.0+0.006*p.x*p.x))+(macro-0.5)*0.35))*(1.0-smoothstep(65.0,82.0,abs(p.x)));
	pad=max(pad,max(path*0.45,lane*0.63));
	// Front-to-west service circuit, shed approach and the earned east return.
	// A varying feathered edge avoids a ruler-straight painted strip.
	float worn=segment_distance(p,vec2(0.0,8.0),vec2(-8.8,7.2));
	worn=min(worn,segment_distance(p,vec2(-8.8,7.2),vec2(-8.8,-8.8)));
	worn=min(worn,segment_distance(p,vec2(-8.8,-8.8),vec2(-8.8,-12.4)));
	worn=min(worn,segment_distance(p,vec2(-4.5,-10.7),vec2(-8.8,-12.4)));
	worn=min(worn,segment_distance(p,vec2(-8.8,-12.4),vec2(-13.7,-14.0)));
	worn=min(worn,segment_distance(p,vec2(12.3,-8.35),vec2(12.3,-3.0)));
	worn=min(worn,segment_distance(p,vec2(12.3,-3.0),vec2(9.0,6.5)));
	worn=min(worn,segment_distance(p,vec2(9.0,6.5),vec2(0.0,8.0)));
	float service_path=1.0-smoothstep(.27,.82,worn+(macro-.5)*.24+(fine-.5)*.10);
	float gate_wear=1.0-smoothstep(.7,1.8,length((p-vec2(0.0,17.0))*vec2(.65,1.0)));
	float doorstep=1.0-smoothstep(.4,1.45,length((p-vec2(-4.5,-10.7))*vec2(.8,1.2)));
	float traffic=max(service_path,max(path*.75,max(gate_wear,doorstep)));
	// Road wheel wear follows the lane curve, with a broken centre rather than
	// creating new kerbs or changing the parked car's ground support.
	float road_z=23.0+.006*p.x*p.x;
	float wheel_ruts=1.0-smoothstep(.12,.40,abs(abs(p.y-road_z)-.86)+(fine-.5)*.10);
	wheel_ruts*=lane;
	vec3 soil=texture(soil_color,p/2.8).rgb*vec3(0.59,0.64,0.66);
	vec3 concrete=texture(concrete_color,p/2.1).rgb*vec3(0.49,0.52,0.53);
	vec3 base=mix(soil,concrete,pad)*(0.84+macro*0.23);
	vec3 trodden=texture(soil_color,p/1.9).rgb*vec3(.40,.43,.40);
	base=mix(base,trodden,traffic*.34);
	base*=1.0-wheel_ruts*.16;
	// Damp splash/gravel transitions at the real foundations, not a square plate.
	float house_edge=min(abs(abs(p.x)-7.65),abs(p.y-4.15));
	float house_band=(1.0-smoothstep(.08,.42,house_edge+(fine-.5)*.13))*step(-10.25,p.y)*step(p.y,4.65)*step(abs(p.x),8.05);
	float shed_edge=min(abs(p.x+20.18),min(abs(p.y+17.16),abs(p.y+10.84)));
	float shed_band=(1.0-smoothstep(.06,.37,shed_edge+(fine-.5)*.12))*step(-20.7,p.x)*step(p.x,-13.5)*step(-17.55,p.y)*step(p.y,-10.5);
	base*=1.0-max(house_band,shed_band)*.13;
	// Damp organic material gathers beside actual fence toes and foundations.
	// Its broken edge follows the soil, not a second flat decal/terrain plate.
	float garden_toe=(1.0-smoothstep(.06,.48,abs(abs(p.x)-10.08)+(fine-.5)*.18))*step(5.7,p.y)*step(p.y,16.3);
	float yard_toe=(1.0-smoothstep(.06,.43,abs(p.y+15.51)+(fine-.5)*.17))*step(-12.25,p.x)*step(p.x,-3.0);
	float sheltered=max(max(house_band,shed_band),max(garden_toe,yard_toe));
	float organic=sheltered*smoothstep(.25,.72,fine)*.48;
	vec3 litter=texture(soil_color,p/1.1+vec2(.7,1.9)).rgb*vec3(.40,.37,.29);
	base=mix(base,litter,organic);
	// Damp, broken garden growth belongs beside the worn route, never across it.
	// This is surface colour, not a raised terrain plate or collision change.
	float garden=(1.0-smoothstep(8.8,10.0,abs(p.x)))*smoothstep(2.2,3.8,abs(p.x))*smoothstep(6.4,8.2,p.y)*(1.0-smoothstep(15.8,17.1,p.y));
	float growing=smoothstep(.30,.66,noise2(p*.7+vec2(23,7)))*garden*(1.0-traffic)*.72;
	vec3 wet_growth=texture(soil_color,p/1.1).rgb*vec3(.30,.40,.25);
	base=mix(base,wet_growth,growing);
	ALBEDO=base;
	NORMAL_MAP=mix(texture(soil_normal,p/2.8).rgb,texture(concrete_normal,p/2.1).rgb,pad);
	float puddle=smoothstep(0.68,0.87,noise2(p*0.32+vec2(17.0,9.0)));
	puddle=max(puddle,wheel_ruts*.50+gate_wear*fine*.28);
	ALBEDO*=0.91;
	NORMAL_MAP_DEPTH=mix(0.24,0.10,max(puddle,traffic*.55));
	float rough=mix(texture(soil_roughness,p/2.8).r,texture(concrete_roughness,p/2.1).r,pad);
	ROUGHNESS=mix(clamp(0.56+rough*0.22,0.62,0.82),0.43,puddle);SPECULAR=0.25;
	// Brief rain rings affect only shallow wet patches, without bright particles
	// or displaced collision. Each cell has its own phase; no travelling wave.
	vec2 cell=floor(p*2.2);
	float age=fract(TIME*.82+hash(cell+vec2(13.0,2.0)));
	vec2 centre=vec2(hash(cell),hash(cell+7.0))*.6+.2;
	vec2 offset=fract(p*2.2)-centre;
	float radius=length(offset);
	float ring=exp(-pow((radius-age*.42)*35.0,2.0))*sin(radius*70.0-age*20.0)*(1.0-age)*puddle;
	NORMAL_MAP.xy+=normalize(offset+vec2(.001))*ring*.035;
}
