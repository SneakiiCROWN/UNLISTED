shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float visibility = 1.0;
uniform float retro = 0.32;
uniform float raster_height = 540.0;
uniform float cover = 0.0;
float bayer2(vec2 p) {
    vec2 q = mod(floor(p), 2.0);
    return mod(2.0*q.x+3.0*q.y,4.0);
}
void fragment() {
    // Square world pixels keep a consistent apparent size across resolutions.
    // UI is drawn afterwards, at native resolution. No blur, temporal noise or wobble.
    float stride = raster_height > 1.0 ? max(1.0,1.0/(SCREEN_PIXEL_SIZE.y*raster_height)) : 1.0;
    vec2 step_uv = SCREEN_PIXEL_SIZE * stride;
    vec2 sampled_uv = (floor(SCREEN_UV/step_uv)+0.5)*step_uv;
    vec3 c = texture(screen_texture,sampled_uv).rgb * visibility;
    vec2 p = SCREEN_UV*2.0-1.0;
    float vignette = smoothstep(0.32,1.65,length(p));
    c *= 1.0-vignette*(0.28+cover*0.18);
    vec2 cell = floor(FRAGCOORD.xy/stride);
    float pattern = (4.0*bayer2(cell)+bayer2(floor(cell/2.0)))/16.0-0.46875;
    // Restrained RGB555-style colour steps with stationary ordered dithering.
    vec3 poster = floor(clamp(c+pattern/31.0,0.0,1.0)*31.0+0.5)/31.0;
    c = mix(c,poster,clamp(retro*1.25,0.0,1.0));
    COLOR = vec4(c,1.0);
}
