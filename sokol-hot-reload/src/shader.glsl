@vs vs_display
in vec2 position;

void main() {
    gl_Position = vec4(position, 0.0, 1.0);
}
@end

@fs fs_display
out vec4 frag_color;

void main() {
    frag_color = vec4(0.2, 0.2, 0.2, 1);
}
@end

@program display vs_display fs_display

