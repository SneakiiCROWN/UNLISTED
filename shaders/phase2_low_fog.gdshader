shader_type fog;
uniform float density=.022;
void fog(){
 vec3 edge=max(vec3(0.0),vec3(1.0)-abs(UVW*2.0-1.0));
 float feather=pow(edge.x*edge.z,1.5)*edge.y;
 DENSITY=density*feather;
 ALBEDO=vec3(.30,.36,.41);
}
