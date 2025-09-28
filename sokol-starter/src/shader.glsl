@vs triangle_vs
layout(binding = 0) uniform vs_params {
    mat4 mvp;
};

in vec2 position;

void main() {
    gl_Position = mvp * vec4(position, 0.0, 1.0);
}
@end

@fs triangle_fs
out vec4 frag_color;

void main() {
    frag_color = vec4(1.0, 0.5, 0.2, 1.0);
}
@end

@program triangle triangle_vs triangle_fs
