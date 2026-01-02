#include <metal_stdlib>
using namespace metal;

struct Vertex {
	float4 position [[position]];
};

struct Uniforms {
	float time;
	float2 mouse;
	float2 resolution;
	float scale;
};

vertex Vertex vertexFunc(uint vertexId [[vertex_id]]) {
	float4 positions[] = {
		float4(-1.0, -1.0, 0.0, 1.0),
		float4( 1.0, -1.0, 0.0, 1.0),
		float4( 1.0,  1.0, 0.0, 1.0),
		
		float4(-1.0, -1.0, 0.0, 1.0),
		float4( 1.0,  1.0, 0.0, 1.0),
		float4(-1.0,  1.0, 0.0, 1.0)
	};
	return Vertex { .position = positions[vertexId] };
}

fragment float4 fragmentFunc(Vertex in [[stage_in]],
							 constant Uniforms& uniforms [[buffer(0)]]) {
	
	float3 colorA = float3(0.149, 0.141, 0.912);
	float3 colorB = float3(1.000, 0.833, 0.224);
	
	float3 color = float3(0);
	
	float pct = abs(sin(uniforms.time));
	
	// Mix uses pct (a value from 0-1) to
	// mix the two colors
	color = mix(colorA, colorB, pct);

	return float4(color,1.0);
}
