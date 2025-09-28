# Sokol Triangle Starter

A simple Zig 0.15.1 project using Sokol to display a triangle in the center of the screen with proper viewport scaling.

## Features

- Simple triangle rendering using Sokol graphics API
- Proper viewport scaling that maintains aspect ratio
- Handles window resizing gracefully
- Uses applyViewport for proper scaling

## Building and Running

```bash
zig build run
```

## Controls

- **ESC**: Exit the application
- The window can be resized and the triangle will maintain its aspect ratio

## Project Structure

- `src/main.zig` - Main application code with sokol setup, triangle rendering, and viewport management
- `src/shader.glsl` - Vertex and fragment shaders for the triangle
- `build.zig` - Build configuration with sokol and zmath dependencies
- `build.zig.zon` - Package configuration with dependencies

## Dependencies

- [sokol-zig](https://github.com/floooh/sokol-zig) - Cross-platform graphics API
- [zmath](https://github.com/zig-gamedev/zmath) - Math library for matrices

## Implementation Details

The triangle is rendered using:

- Simple vertex data in NDC coordinates (-0.5 to 0.5 range)
- Basic vertex and fragment shaders
- Identity MVP matrix (no transformations)
- Orange colored triangle (`vec4(1.0, 0.5, 0.2, 1.0)`)
- 4:3 aspect ratio preservation with viewport scaling
