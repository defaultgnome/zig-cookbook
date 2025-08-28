# sokol hot reloading

Sokol App + Shader Recomplation and Game Code Hot Reloading.

Tested on Windows.
Mac reloading is broken,
 see this `ef1458291eeee5c1d84a0f31086e28d5665ca5bf` commit,
 for working example on mac. (It will be missing the static compilcaiton for release mode)

## Instructions
### Development
1. run `zig build --watch` in one terminal.
2. run `./zig-out/bin/sokol_hot_reload.exe`
3. modify the shader color or/and modify the rectangle position in the `app.zig#update` function
4. it should recomplie and load automaticlly

### Release
if you use `-Doptimize` other than `Debug`, the reloading of the of the dll will be skipped.
and the app will import the app.zig staticlly

