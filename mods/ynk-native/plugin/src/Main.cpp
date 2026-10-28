// ynk_native: native functions for redscript, loaded by RED4ext.
//
// YnkUnixTimeMs() -> Int64
//   Real-world time in milliseconds since 1970 (UTC). Redscript only has game and simulation
//   time, which pause in menus and slow down in Sandevistan; this is the wall clock.
// YnkNativeVersion() -> String
//   The plugin version, so a script can check that the DLL is installed.
//
// The matching declarations are in r6/scripts/YNK/Native.reds.

#include <chrono>
#include <cstdint>

#include <RED4ext/RED4ext.hpp>

namespace
{
constexpr auto kVersion = "0.1.0";

// Native function signature: the script VM calls this with its stack frame. Parameters (none
// here) are read from aFrame, then the frame is advanced past the end-of-parameters marker.
void YnkUnixTimeMs(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, int64_t* aOut, int64_t a4)
{
    RED4EXT_UNUSED_PARAMETER(aContext);
    RED4EXT_UNUSED_PARAMETER(a4);
    aFrame->code++; // skip ParamEnd

    if (aOut)
    {
        const auto now = std::chrono::system_clock::now().time_since_epoch();
        *aOut = std::chrono::duration_cast<std::chrono::milliseconds>(now).count();
    }
}

void YnkNativeVersion(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, RED4ext::CString* aOut,
                      int64_t a4)
{
    RED4EXT_UNUSED_PARAMETER(aContext);
    RED4EXT_UNUSED_PARAMETER(a4);
    aFrame->code++; // skip ParamEnd

    if (aOut)
    {
        *aOut = RED4ext::CString(kVersion);
    }
}
} // namespace

RED4EXT_C_EXPORT void RED4EXT_CALL RegisterTypes()
{
}

// Runs after the game registered its own types: our globals can now name Int64 and String.
RED4EXT_C_EXPORT void RED4EXT_CALL PostRegisterTypes()
{
    auto rtti = RED4ext::CRTTISystem::Get();
    RED4ext::CBaseFunction::Flags flags = {.isNative = true, .isStatic = true};

    {
        auto func = RED4ext::CGlobalFunction::Create("YnkUnixTimeMs", "YnkUnixTimeMs", &YnkUnixTimeMs);
        func->flags = flags;
        func->SetReturnType("Int64");
        rtti->RegisterFunction(func);
    }
    {
        auto func = RED4ext::CGlobalFunction::Create("YnkNativeVersion", "YnkNativeVersion", &YnkNativeVersion);
        func->flags = flags;
        func->SetReturnType("String");
        rtti->RegisterFunction(func);
    }
}

RED4EXT_C_EXPORT bool RED4EXT_CALL Main(RED4ext::v1::PluginHandle aHandle, RED4ext::v1::EMainReason aReason,
                                        const RED4ext::v1::Sdk* aSdk)
{
    RED4EXT_UNUSED_PARAMETER(aHandle);
    RED4EXT_UNUSED_PARAMETER(aSdk);

    if (aReason == RED4ext::v1::EMainReason::Load)
    {
        auto rtti = RED4ext::CRTTISystem::Get();
        rtti->AddRegisterCallback(RegisterTypes);
        rtti->AddPostRegisterCallback(PostRegisterTypes);
    }
    return true;
}

RED4EXT_C_EXPORT void RED4EXT_CALL Query(RED4ext::v1::PluginInfo* aInfo)
{
    aInfo->name = L"ynk_native";
    aInfo->author = L"YooNeqK";
    aInfo->version = RED4EXT_V1_SEMVER(0, 1, 0);
    aInfo->runtime = RED4EXT_V1_RUNTIME_VERSION_LATEST;
    aInfo->sdk = RED4EXT_V1_SDK_VERSION_CURRENT;
}

RED4EXT_C_EXPORT uint32_t RED4EXT_CALL Supports()
{
    return RED4EXT_API_VERSION_1;
}
