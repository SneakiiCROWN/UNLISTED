shader_type sky;
uniform vec2 cloud_drift = vec2(0.0);
uniform vec3 moon_direction = vec3(-0.42,0.61,0.67);
uniform sampler2D cloud_map : filter_linear_mipmap,repeat_enable;
void sky(){
	vec3 d=normalize(EYEDIR);
	float altitude=max(d.y,0.0);
	vec3 night=mix(vec3(0.052,0.067,0.082),vec3(0.009,0.017,0.032),pow(altitude,0.45));
	vec2 plane=d.xz/(altitude+0.19)*1.4+cloud_drift;
	float cloud=smoothstep(0.33,0.74,texture(cloud_map,plane*0.18).r);
	float moon_dot=dot(d,normalize(moon_direction));
	float halo=pow(max(moon_dot,0.0),220.0)*0.025;
	float disc=smoothstep(0.99980,0.99994,moon_dot)*0.32;
	float lining=pow(max(moon_dot,0.0),22.0)*0.016*cloud;
	night=mix(night,vec3(0.022,0.031,0.044)+lining,cloud*0.78);
	night+=vec3(0.68,0.78,0.90)*(disc+halo)*(1.0-cloud*0.9)*smoothstep(0.0,0.12,altitude);
	night=mix(vec3(0.045,0.055,0.064),night,smoothstep(-0.06,0.08,d.y));
	night+=vec3((texture(cloud_map,SKY_COORDS*227.0).r-0.5)*0.002);
	COLOR=night;
}
