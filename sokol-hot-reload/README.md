# sokol hot reloading

## Instructions
### Development
1. run `zig build --watch` in one terminal.
2. run `./zig-out/bin/sokol_hot_reload.exe`
3. modify the shader color or/and modify the rectangle position in the `app.zig#update` function
4. it should recomplie and load automaticlly

### Release
if you use `-Doptimize` other than `Debug`, the reloading of the of the dll will be skipped.
and the app will import the app.zig staticlly

