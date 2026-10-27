shader_type spatial;
// Existing licensed timber, weathered in world space; no geometry displacement.
uniform sampler2D boards : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D boards_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(.54,.59,.57,1.0);
uniform float tile_scale = .55;
uniform float diffuse_lift = 1.0;
varying vec3 world_position;
varying vec3 world_normal;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise2(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
	// World projection keeps board grain at a physical scale across long rails.
	vec3 n=abs(world_normal);
	vec2 plane=n.y>max(n.x,n.z)?world_position.xz:(n.x>n.z?world_position.zy:world_position.xy);
	vec2 uv=plane*tile_scale;
	float streak=noise2(vec2((world_position.x+world_position.z)*6.0,world_position.y*.32));
	float splash=(1.0-smoothstep(.08,.65,world_position.y))*smoothstep(.23,.72,streak);
	float damp=.10+streak*.13+splash*.16;
	vec3 wood=texture(boards,uv).rgb*tint.rgb;
	ALBEDO=mix(wood,wood*vec3(.64,.69,.63),damp);
	NORMAL_MAP=texture(boards_normal,uv).rgb;NORMAL_MAP_DEPTH=.22;
	float exposed=1.0-step(abs(world_position.x),1.92)*step(4.0,world_position.z)*step(world_position.z,6.4);
 float run=exposed*(.28+streak*.38+splash*.34);
 ALBEDO*=mix(1.0,.93,run)*diffuse_lift;
 ROUGHNESS=mix(mix(.91,.70,damp),.62,run);SPECULAR=.23;
}
