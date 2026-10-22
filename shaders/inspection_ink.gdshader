shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform sampler2D ink_texture : source_color;
uniform vec3 beam_origin;
uniform vec3 beam_forward = vec3(0.0,0.0,-1.0);
uniform float beam_active = 0.0;
varying vec3 world_point;
void vertex(){world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec3 offset=world_point-beam_origin;
 float distance_to_light=length(offset);
 float cone=smoothstep(0.84,0.97,dot(normalize(offset),beam_forward));
 float light=cone*(1.0-smoothstep(4.0,7.0,distance_to_light))*beam_active;
 float ink=texture(ink_texture,UV).a;
 ALBEDO=vec3(0.22,0.76,0.52);EMISSION=vec3(0.18,0.65,0.42)*light;
 ALPHA=ink*light*0.92;
}
