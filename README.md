# odin-imgui

This is an odin wrapper for [dear imgui v1.82](https://github.com/ocornut/imgui) (Generated from the auto-generated [cimgui](https://github.com/cimgui/cimgui.git)).

It contains generated wrappers as well as handwritten ones to make it better fit with the odin language.
It will also contain extra utility functions that are not present in cimgui.

![scrshot](https://i.imgur.com/nOA6iSl.png)

You can download the latest release with pre-built cimgui binaries [here.](https://github.com/ThisDrunkDane/odin-dear_imgui/releases/latest)

## Examples

You can find examples of setting up `odin-imgui` using the provided [implementations](#implementations) inside the `examples` folder, current examples exists;

Done:
 - SDL with OpenGL 4.5

WIP:
 - SDL with D3D11

## Implementations

Implementations are reusable bits of code using popular odin libraries/bidings, inside the `impl` folder there currently are;

 - SDL using "vendor:sdl2"
 - OpenGL using "vendor:OpenGL"

## Notes:
* Most functions have been wrapped or bound, those missing will either be added by the maintainer over time or by PR (PRs VERY WELCOME)

## Building cimgui
### Windows
If you want to build cimgui yourself instead of using the binaries that exist in the repo, you can just call `make cimgui` from a command prompt that has `cl` and `link` in their path.

### Linux
In the `cimgui Makefile`, add `-fno-threadsafe-statics` to `CXXFLAGS`.

Example:
```
CXXFLAGS=-O2 -fno-exceptions -fno-rtti -fno-threadsafe-statics
```

Now, in the cimgui directory run the following:
1. `make`
2. `make static`

Rename the `libcimgui.a` library in the cimgui folder to `cimgui.a`.

Move `cimgui.a` to the `odin-imgui/external` folder.
