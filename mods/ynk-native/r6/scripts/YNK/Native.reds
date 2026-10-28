// Declarations for the ynk_native RED4ext plugin (red4ext/plugins/ynk_native/ynk_native.dll).
// Without the DLL these functions don't exist and the script compile fails, so only install
// this file together with the plugin.
// No module line: the DLL registers these globals without a module prefix.

// Real-world time in milliseconds since 1970 (UTC). Unlike game or simulation time it keeps
// running in menus and is not slowed by time dilation.
public static native func YnkUnixTimeMs() -> Int64

// The plugin version, e.g. "0.1.0".
public static native func YnkNativeVersion() -> String

// Test hook for the mod lab: CET can call player:YnkNativeSelfTest().
@addMethod(PlayerPuppet)
public func YnkNativeSelfTest() -> String {
  return "ynk_native " + YnkNativeVersion() + " unix_ms=" + ToString(YnkUnixTimeMs());
}
