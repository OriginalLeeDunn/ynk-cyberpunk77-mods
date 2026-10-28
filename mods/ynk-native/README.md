# YNK Native

A small [RED4ext](https://github.com/wopss/RED4ext) plugin (C++) that adds native functions for
redscript mods. It's the first native piece of the YNK mods and the base the next tools build on.

| Function | Returns |
|---|---|
| `YnkUnixTimeMs() -> Int64` | Real-world time in milliseconds since 1970 (UTC). Redscript only has game and simulation time, which pause in menus and slow down with time dilation; this is the wall clock. |
| `YnkNativeVersion() -> String` | The plugin version, so a script can check the DLL is installed. |

- **Version:** 0.1.0
- **Game:** Cyberpunk 2077 2.5
- **Requires:** [RED4ext](https://github.com/wopss/RED4ext) 1.31+ and [redscript](https://github.com/jac3km4/redscript) 0.5.32+

## Install
Copy `ynk_native.dll` to `Cyberpunk 2077\red4ext\plugins\ynk_native\` and `r6\scripts\YNK\Native.reds`
to the same path in your game folder. Install both or neither: without the DLL, the `.reds`
declarations stop the game from starting (RED4ext reports the missing native functions).

## Use from redscript

    let ms: Int64 = YnkUnixTimeMs();
    LogChannel(n"DEBUG", "ynk_native " + YnkNativeVersion() + " " + ToString(ms));

## Build
Needs Visual Studio 2022 (the "Desktop development with C++" workload or the Build Tools) and
CMake 3.23+. The RED4ext SDK is fetched by CMake, pinned to the commit with the patch 2.5 types.

    cmake -S plugin -B build -G "Visual Studio 17 2022" -A x64
    cmake --build build --config Release

The DLL is `build/Release/ynk_native.dll`.

## How it works
`Main()` runs when RED4ext loads the DLL and registers a callback with the game's type system
(RTTI). Once the game has registered its own types, `PostRegisterTypes()` adds the two functions as
global natives (`CGlobalFunction`), with their return types. Redscript sees them through the
`native func` declarations in `Native.reds`; the names must match exactly, and the file has no
`module` line because the DLL registers the names without a module prefix.

## How AI was used
Made with an AI coding assistant (Claude, through Claude Code). **AI:** set up the C++ toolchain,
wrote the plugin and the redscript declarations from the RED4ext SDK examples, and tested it in the
mod lab. **Me:** chose the native modding path, reviewed it, and decided to release it.

## Changelog
- **0.1.0** `YnkUnixTimeMs` and `YnkNativeVersion`.
