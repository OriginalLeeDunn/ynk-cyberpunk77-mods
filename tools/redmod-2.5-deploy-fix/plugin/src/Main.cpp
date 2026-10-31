// ynk_redmod_bridge: lets REDmod script mods and redscript mods run together on patch 2.5.
//
// REDmod's script compiler rejects the engine's root class ISerializable unless it has a parent,
// and the game refuses to start if it has one. Fix-REDmod-Deploy.ps1 gives it a parent so deploy
// succeeds; this plugin clears that parent in r6\cache\modded\final.redscripts at startup, before
// the game or redscript read the file. The class then matches the game's own scripts exactly.
//
// It changes that one value and nothing else, and does nothing to a file that doesn't match
// exactly what it expects (no REDmod scripts, already corrected, or a future patch's layout).

#include <Windows.h>

#include <cstdint>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <optional>
#include <string_view>
#include <vector>

#include <RED4ext/RED4ext.hpp>

namespace
{
constexpr uint32_t kBundleVersion = 14;
constexpr size_t kTableStart = 0x20;
constexpr size_t kTableSize = 12;
constexpr size_t kCNamesTable = 1;
constexpr size_t kDefinitionsTable = 4;
constexpr size_t kMinTables = 6;
constexpr size_t kDefinitionSize = 20;
constexpr uint16_t kTagClass = 1;
constexpr size_t kClassBaseOffset = 3; // visibility u8 + flags u16

struct Table
{
    uint32_t offset;
    uint32_t count;
};

template<typename T> std::optional<T> Read(const std::vector<uint8_t>& aData, size_t aOffset)
{
    if (aOffset > aData.size() || aData.size() - aOffset < sizeof(T))
        return std::nullopt;
    T value;
    std::memcpy(&value, aData.data() + aOffset, sizeof(T));
    return value;
}

std::optional<Table> ReadTable(const std::vector<uint8_t>& aData, size_t aIndex)
{
    const auto base = kTableStart + aIndex * kTableSize;
    const auto offset = Read<uint32_t>(aData, base);
    const auto count = Read<uint32_t>(aData, base + 4);
    if (!offset || !count)
        return std::nullopt;
    return Table{*offset, *count};
}

std::optional<uint32_t> FindCName(const std::vector<uint8_t>& aData, const Table& aStrings, const Table& aCNames,
                                  std::string_view aName)
{
    for (uint32_t i = 0; i < aCNames.count; i++)
    {
        const auto text = Read<uint32_t>(aData, aCNames.offset + size_t{i} * 4);
        if (!text)
            return std::nullopt;
        const size_t start = size_t{aStrings.offset} + *text;
        if (start + aName.size() < aData.size() &&
            std::memcmp(aData.data() + start, aName.data(), aName.size()) == 0 && aData[start + aName.size()] == 0)
            return i;
    }
    return std::nullopt;
}

struct ClassDef
{
    uint32_t index;
    uint32_t body;
};

std::optional<ClassDef> FindClass(const std::vector<uint8_t>& aData, const Table& aDefs, uint32_t aName)
{
    for (uint32_t i = 1; i < aDefs.count; i++)
    {
        const size_t entry = size_t{aDefs.offset} + size_t{i} * kDefinitionSize;
        const auto name = Read<uint32_t>(aData, entry);
        const auto offset = Read<uint32_t>(aData, entry + 8);
        const auto tag = Read<uint16_t>(aData, entry + 16);
        if (!name || !offset || !tag)
            return std::nullopt;
        if (*name == aName && *tag == kTagClass)
            return ClassDef{i, *offset};
    }
    return std::nullopt;
}

enum class Result
{
    NoFile,
    NotApplicable,
    AlreadyCorrect,
    Corrected,
    WriteFailed
};

bool WriteZero(const std::filesystem::path& aPath, uint64_t aOffset)
{
    const auto file = CreateFileW(aPath.c_str(), GENERIC_WRITE, FILE_SHARE_READ, nullptr, OPEN_EXISTING,
                                  FILE_ATTRIBUTE_NORMAL, nullptr);
    if (file == INVALID_HANDLE_VALUE)
        return false;

    LARGE_INTEGER position{};
    position.QuadPart = static_cast<LONGLONG>(aOffset);
    const uint32_t zero = 0;
    DWORD written = 0;
    const bool ok = SetFilePointerEx(file, position, nullptr, FILE_BEGIN) &&
                    WriteFile(file, &zero, sizeof(zero), &written, nullptr) && written == sizeof(zero);
    CloseHandle(file);
    return ok;
}

Result Correct(const std::filesystem::path& aPath)
{
    std::error_code error;
    if (!std::filesystem::exists(aPath, error))
        return Result::NoFile;

    std::ifstream in(aPath, std::ios::binary);
    if (!in)
        return Result::WriteFailed;
    const std::vector<uint8_t> data((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    in.close();

    const auto version = Read<uint32_t>(data, 4);
    if (data.size() < 4 || std::memcmp(data.data(), "REDS", 4) != 0 || !version || *version != kBundleVersion)
        return Result::NotApplicable;

    const auto strings = ReadTable(data, 0);
    if (!strings || strings->offset < kTableStart + kMinTables * kTableSize)
        return Result::NotApplicable;
    const auto cnames = ReadTable(data, kCNamesTable);
    const auto defs = ReadTable(data, kDefinitionsTable);
    if (!cnames || !defs)
        return Result::NotApplicable;

    const auto serializableName = FindCName(data, *strings, *cnames, "ISerializable");
    const auto scriptableName = FindCName(data, *strings, *cnames, "IScriptable");
    if (!serializableName || !scriptableName)
        return Result::NotApplicable;

    const auto serializable = FindClass(data, *defs, *serializableName);
    const auto scriptable = FindClass(data, *defs, *scriptableName);
    if (!serializable || !scriptable)
        return Result::NotApplicable;

    const uint64_t baseOffset = uint64_t{serializable->body} + kClassBaseOffset;
    const auto base = Read<uint32_t>(data, static_cast<size_t>(baseOffset));
    if (!base)
        return Result::NotApplicable;
    if (*base == 0)
        return Result::AlreadyCorrect;
    if (*base != scriptable->index)
        return Result::NotApplicable;

    return WriteZero(aPath, baseOffset) ? Result::Corrected : Result::WriteFailed;
}

std::filesystem::path GameRoot()
{
    std::wstring path(MAX_PATH, L'\0');
    for (;;)
    {
        const auto length = GetModuleFileNameW(nullptr, path.data(), static_cast<DWORD>(path.size()));
        if (length < path.size())
        {
            path.resize(length);
            break;
        }
        path.resize(path.size() * 2);
    }
    return std::filesystem::path(path).parent_path().parent_path().parent_path(); // bin\x64\game.exe
}
} // namespace

RED4EXT_C_EXPORT bool RED4EXT_CALL Main(RED4ext::v1::PluginHandle aHandle, RED4ext::v1::EMainReason aReason,
                                        const RED4ext::v1::Sdk* aSdk)
{
    if (aReason != RED4ext::v1::EMainReason::Load)
        return true;

    const auto blob = GameRoot() / L"r6" / L"cache" / L"modded" / L"final.redscripts";
    switch (Correct(blob))
    {
    case Result::NoFile:
        aSdk->logger->Info(aHandle, "No REDmod scripts deployed, nothing to do.");
        break;
    case Result::NotApplicable:
        aSdk->logger->Warn(aHandle, "REDmod scripts don't match the expected layout, left untouched.");
        break;
    case Result::AlreadyCorrect:
        aSdk->logger->Info(aHandle, "REDmod scripts are already correct.");
        break;
    case Result::Corrected:
        aSdk->logger->Info(aHandle, "Corrected ISerializable in REDmod scripts.");
        break;
    case Result::WriteFailed:
        aSdk->logger->Error(aHandle, "Could not update r6\\cache\\modded\\final.redscripts.");
        MessageBoxW(nullptr,
                    L"YNK REDmod Bridge could not update r6\\cache\\modded\\final.redscripts.\n\n"
                    L"Check that the file isn't read-only and that your game folder is writable, then start the "
                    L"game again.",
                    L"YNK REDmod Bridge", MB_OK | MB_ICONERROR);
        break;
    }
    return true;
}

RED4EXT_C_EXPORT void RED4EXT_CALL Query(RED4ext::v1::PluginInfo* aInfo)
{
    aInfo->name = L"ynk_redmod_bridge";
    aInfo->author = L"YooNeqK";
    aInfo->version = RED4EXT_V1_SEMVER(2, 0, 0);
    aInfo->runtime = RED4EXT_V1_RUNTIME_VERSION_INDEPENDENT;
    aInfo->sdk = RED4EXT_V1_SDK_VERSION_CURRENT;
}

RED4EXT_C_EXPORT uint32_t RED4EXT_CALL Supports()
{
    return RED4EXT_API_VERSION_1;
}
