shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float opacity : hint_range(0.0, 1.0) = 0.4;
varying vec3 world_point;

void vertex() {
	// Fixed upright billboard, with the actual world fragment available below.
	vec3 right = normalize(vec3(INV_VIEW_MATRIX[0].x, 0.0, INV_VIEW_MATRIX[0].z));
	world_point = MODEL_MATRIX[3].xyz + right * VERTEX.x + vec3(0.0, VERTEX.y, 0.0);
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world_point, 1.0);
}

void fragment() {
	// The GPU roof heightfield remains the primary collision. This conservative
	// interior mask also removes fast drops which cross its texels at roof edges.
	// It clips fragments inside the real shells, never the rain beyond a window.
	bool house = abs(world_point.x) < 7.48 && world_point.z > -10.02 && world_point.z < 4.02 && world_point.y < 2.94;
	bool shed = world_point.x > -20.02 && world_point.x < -13.98 && world_point.z > -17.02 && world_point.z < -10.98 && world_point.y < 2.94;
	bool porch = abs(world_point.x) < 1.91 && world_point.z > 4.0 && world_point.z < 6.4 && world_point.y < 2.84;
	bool annex = abs(world_point.x) < 1.78 && world_point.z > -15.25 && world_point.z < -10.0 && world_point.y < 3.0;
	// The basement and the new service void are below the collision heightfield.
	// Discard penetrated fragments only inside their actual roofed volumes.
	bool cellar = abs(world_point.x) < 5.08 && world_point.z > -24.08 && world_point.z < -14.98 && world_point.y < 0.0;
	bool service_void = world_point.x > 2.30 && world_point.x < 4.20 && world_point.z > -15.28 && world_point.z < -10.10 && world_point.y < -1.58;
	bool records_store = world_point.x > 2.0 && world_point.x < 6.10 && world_point.z > -10.50 && world_point.z < -6.20 && world_point.y < -0.10;
	if (house || shed || porch || annex || cellar || service_void || records_store) { discard; }
	ALBEDO = vec3(0.47, 0.56, 0.63);
	ALPHA = opacity;
}
