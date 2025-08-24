# Zig DLL Reload Demo

This project demonstrates dynamic library (DLL) reloading with Zig.
It allows you to modify and recompile a shared library while the main program is running,
then see the changes take effect without restarting the application.

## Prerequisites

- [Zig compiler](https://ziglang.org/download/) (latest version recommended)

## Building and Running

### Build Everything

To build the main application and the dynamic library:

```bash
zig build
```

### Build and Run in One Step

To build everything and immediately run the demo:

```bash
zig build run
```

### Build Just the DLL

If you only want to rebuild the dynamic library (useful for hot reloading):

```bash
zig build dll
```

## Testing Hot Reloading

1. Build and start the demo application:

```bash
zig build
./zig-out/bin/hot_reload_demo
```

2. While the application is running, modify the `src/dll.zig` file to change the behavior.

3. Recompile just the DLL:

```bash
zig build dll
```

4. Trigger a Reload in the running application.

5. You should see the new behavior (without having to restart the application).
