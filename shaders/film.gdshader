shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float visibility = 1.0;
uniform float retro = 0.18;
uniform float pixel_stride = 1.35;
void fragment() {
    vec2 step_uv = SCREEN_PIXEL_SIZE * max(pixel_stride, 1.0);
    vec2 sampled_uv = pixel_stride > 1.01 ? (floor(SCREEN_UV / step_uv)+0.5)*step_uv : SCREEN_UV;
    vec3 c = texture(screen_texture, sampled_uv).rgb;
    c *= visibility;
    vec2 p = SCREEN_UV * 2.0 - 1.0;
    float vignette = smoothstep(0.32, 1.65, length(p));
    c *= 1.0 - vignette * 0.28;
    float pattern = mod(FRAGCOORD.x,2.0) + 2.0*mod(FRAGCOORD.y,2.0);
    float dither = (pattern/4.0-0.375)/40.0;
    vec3 poster = floor((c+dither) * 40.0 + 0.5) / 40.0;
    c = mix(c, poster, retro * 0.5);
    float grain = fract(sin(dot(FRAGCOORD.xy,vec2(12.9898,78.233)))*43758.5453)-0.5;
    c += grain * 0.009 * retro;
    COLOR = vec4(c, 1.0);
}
