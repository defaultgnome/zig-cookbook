@vs vs_display
in vec2 position;
layout(binding = 0) uniform display_vs_uniforms {
    mat4 mvp;
};

void main() {
    gl_Position = mvp * vec4(position, 0.0, 1.0);
}
@end

@fs fs_display
out vec4 frag_color;

void main() {
    frag_color = vec4(1, 0, 1, 1);
}
@end

@program display vs_display fs_display

