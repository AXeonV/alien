#version 330 core

in vec2 Ttexcoord;
in vec3 Tcolor;

in float clipW;

uniform vec2 u_resolution;
uniform float u_time;

uniform mat4 inv_transform;

uniform sampler2D Utexture1;
uniform sampler2D Utexture2;

const float EPS = 1e-3;

vec3 palette2(float t, float factor) {
	vec3 a = vec3(0.5) + 0.3 * sin(vec3(0.1, 0.3, 0.5) * factor);
	vec3 b = vec3(0.5) + 0.3 * cos(vec3(0.2, 0.4, 0.6) * factor);
	vec3 c = vec3(1.0) + 0.5 * sin(vec3(0.3, 0.7, 0.9) * factor);
	vec3 d = vec3(0.25, 0.4, 0.55) + 0.2 * cos(vec3(0.5, 0.6, 0.7) * factor);
	return a + b * cos(6.28318 * (c * t + d));
}
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y);
}

vec2 get_pos() {
	vec3 ndc;
	ndc.x = (gl_FragCoord.x / u_resolution.x) * 2.0 - 1.0;
	ndc.y = (gl_FragCoord.y / u_resolution.y) * 2.0 - 1.0;
	ndc.z = gl_FragCoord.z * 2.0 - 1.0;
	vec4 clipPos = vec4(ndc.xyz * clipW, clipW);
	vec4 modelPos = inv_transform * clipPos;
	modelPos *= 2.0f;
	if (1.0f - abs(modelPos.x) < EPS) return vec2(modelPos.y, modelPos.z);
	if (1.0f - abs(modelPos.y) < EPS) return vec2(modelPos.x, modelPos.z);
	if (1.0f - abs(modelPos.z) < EPS) return vec2(modelPos.x, modelPos.y);
}

void main() {
	vec3 color = vec3(0.0);
	vec2 FragPos = get_pos();
	vec2 uv = vec2(abs(FragPos.x), FragPos.y);
	float breath = 1.0 + 2.0 * sin(u_time * 0.2) * smoothstep(0.2, 1.5, length(uv));
	uv *= breath;
	uv *= 20.0;

	for (int i = 0; i < 30; i++) {
		float t = u_time * 0.01 - float(i);
		uv *= mat2(cos(t), sin(t), -sin(t), cos(t));
		uv += noise(sin(uv) * 0.6);
		uv += noise(-cos(uv) * 0.6);

		color += 0.002 / length(uv + sin(t));

		float intensity = 0.1 / length(uv - (10.3) * sin(t)) * (length(uv) * sin(float(i) + u_time));

		color += palette2(float(i) / u_time, u_time * 0.5) * intensity;
	}

	gl_FragColor = vec4(color, 1.0f) * vec4(Tcolor, 1.0f) * 2.0f;
}