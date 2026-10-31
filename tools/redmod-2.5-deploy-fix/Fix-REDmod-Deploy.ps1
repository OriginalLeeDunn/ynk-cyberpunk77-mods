# YNK REDmod 2.5 Deploy Fix
# Since patch 2.5, every REDmod deploy fails at "Stage 2/5 - Script Compilation" with:
#   ScriptCompiler: ERROR: Imported classes (like 'ISerializable') must derive from something.
# and, once that is fixed, with:
#   ScriptCompiler: ERROR: Unable to convert from '&script_ref<inkCompoundRef>' to 'inkWidgetRef'
# Both come from the script sources REDmod ships in tools\redmod\scripts, not from any mod:
# - mods\codeware\callbackSystem.script declares ISerializable (the engine's root class) as an imported
#   class with no parent, which this compiler only allows for IScriptable. This script gives it a
#   parent so deploy succeeds. The game refuses to start with that parent, so the ynk_redmod_bridge
#   RED4ext plugin clears it in the deployed scripts at every startup, before anything reads them.
#   Everything stays declared, so redscript mods that need ISerializable or CResource keep working.
# - tarot_main.script and inventoryItemMode.script pass a ref< inkCompoundRef > parameter to
#   inkWidgetRef.Get, which this compiler can't convert. Taking the parameter by value fixes it;
#   inkCompoundRef is a handle to a widget, so a copy refers to the same widget.
# Without RED4ext the plugin can't run, so those two classes are left out of REDmod's compile
# instead. That only suits REDmod-only setups: redscript mods need RED4ext anyway, and running this
# again after installing RED4ext switches to the full fix.
# The script edits these files in place (it ships no CDPR files), keeps a backup of each next to it
# (*.ynkfix-backup), and -Undo restores the backups. Deployed scripts in r6\cache\modded are removed
# whenever the fix changes, because REDmod reuses them otherwise.
# Usage (PowerShell, from anywhere):
#   .\Fix-REDmod-Deploy.ps1                       # finds the Steam/GOG/Epic install, or asks
#   .\Fix-REDmod-Deploy.ps1 -GamePath "D:\Games\Cyberpunk 2077"
#   .\Fix-REDmod-Deploy.ps1 -Undo
param(
    [string]$GamePath,
    [switch]$Undo,
    [switch]$NoPause
)
$ErrorActionPreference = "Stop"
$PluginName = "ynk_redmod_bridge"

function Find-Game {
    $candidates = @(
        "C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077",
        "C:\Program Files\Steam\steamapps\common\Cyberpunk 2077",
        "C:\GOG Games\Cyberpunk 2077",
        "C:\Program Files (x86)\GOG Galaxy\Games\Cyberpunk 2077",
        "C:\Program Files\Epic Games\Cyberpunk 2077",
        "C:\Program Files\Epic Games\Cyberpunk2077"
    )
    foreach ($d in [IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq "Fixed" }) {
        $candidates += Join-Path $d.RootDirectory "SteamLibrary\steamapps\common\Cyberpunk 2077"
    }
    foreach ($c in $candidates) {
        if (Test-Path (Join-Path $c "bin\x64\Cyberpunk2077.exe")) { return $c }
    }
    return $null
}

# callbackSystem.script: give ISerializable a parent, or leave both classes out without RED4ext (see
# the header). Regexes, so CRLF or LF line endings both match.
function Fix-CallbackSystem([string]$text, [bool]$bridge) {
    if ($bridge) {
        return $text -replace "importonly abstract class ISerializable(\r?\n)\{", 'importonly abstract class ISerializable extends IScriptable$1{'
    }
    $text = $text -replace "importonly abstract class ISerializable\r?\n\{\s*\}\r?\n(\r?\n)?", ""
    $text = $text -replace "import abstract class CResource extends ISerializable\r?\n\{[^}]*\}\r?\n(\r?\n)?", ""
    $text = $text -replace "[ \t]*import var resource : CResource;\r?\n(\r?\n)?", ""
    $text = $text -replace "[ \t]*public import function GetResource\(\) : CResource;\r?\n", ""
    return $text
}

function Remove-Deployed {
    $modded = Join-Path $GamePath "r6\cache\modded"
    if (Test-Path $modded) { Remove-Item $modded -Recurse -Force; Write-Host "removed   r6\cache\modded (rebuilt by the next deploy)" }
}

function Invoke-Fix {
    if (-not $script:GamePath) { $script:GamePath = Find-Game }
    if (-not $script:GamePath) { $script:GamePath = Read-Host "Cyberpunk 2077 folder (the one containing bin, r6, tools)" }
    $script:GamePath = $script:GamePath.Trim('"').TrimEnd('\')
    $scripts = Join-Path $GamePath "tools\redmod\scripts"
    if (-not (Test-Path $scripts)) {
        throw "REDmod isn't installed in '$GamePath' (no tools\redmod\scripts). Install the free REDmod DLC first."
    }
    Write-Host "Game folder: $GamePath"

    $pluginDir = Join-Path $GamePath "red4ext\plugins\$PluginName"
    $hasRed4ext = Test-Path (Join-Path $GamePath "red4ext\RED4ext.dll")

    # relative path, text that is broken, text that fixes it
    $fixes = @(
        @{ File = "mods\codeware\callbackSystem.script"; Func = $true },
        @{ File = "cyberpunk\UI\fullscreen\tarot\tarot_main.script"
           Old  = "widgetRef : ref< inkCompoundRef > )"
           New  = "widgetRef : inkCompoundRef )" },
        @{ File = "cyberpunk\UI\inventory\inventoryItemMode.script"
           Old  = "CreateItemChooser( itemCategoryList : ref< inkCompoundRef >,"
           New  = "CreateItemChooser( itemCategoryList : inkCompoundRef," }
    )

    if ($Undo) {
        foreach ($f in $fixes) {
            $path = Join-Path $scripts $f.File
            $backup = "$path.ynkfix-backup"
            if (Test-Path $backup) {
                Copy-Item $backup $path -Force
                Remove-Item $backup
                Write-Host "restored  $($f.File)"
            } else {
                Write-Host "no backup $($f.File) (nothing to undo)"
            }
        }
        if (Test-Path $pluginDir) { Remove-Item $pluginDir -Recurse -Force; Write-Host "removed   red4ext\plugins\$PluginName" }
        Remove-Deployed
        Write-Host ""
        Write-Host "Undone. Note that REDmod deploys with scripts fail again until CDPR fixes them."
        return
    }

    $bridge = $hasRed4ext
    if ($bridge) {
        $dll = Join-Path $PSScriptRoot "red4ext\plugins\$PluginName\$PluginName.dll"
        if (-not (Test-Path $dll)) { $dll = Join-Path $pluginDir "$PluginName.dll" }
        if (-not (Test-Path $dll)) { throw "$PluginName.dll is missing. Unpack the whole zip and run this script from that folder." }
    } else {
        Write-Warning "RED4ext isn't installed, so this is the REDmod-only fix. If you add redscript or Codeware mods later, install RED4ext and run this again."
    }

    $changed = $false
    foreach ($f in $fixes) {
        $path = Join-Path $scripts $f.File
        $backup = "$path.ynkfix-backup"
        if (-not (Test-Path $path)) { Write-Warning "missing   $($f.File) (REDmod version differs; skipped)"; continue }
        # Always start from the original, so a fix from an older version is replaced cleanly
        $text = if (Test-Path $backup) { [IO.File]::ReadAllText($backup) } else { [IO.File]::ReadAllText($path) }
        $current = [IO.File]::ReadAllText($path)
        if ($f.Func) {
            if ($text -notmatch "(?m)^importonly abstract class ISerializable\r?$") { Write-Warning "skipped   $($f.File) (unexpected layout; CDPR may have changed it)"; continue }
            $fixed = Fix-CallbackSystem $text $bridge
            if ($fixed -eq $text) { Write-Warning "skipped   $($f.File) (unexpected layout; CDPR may have changed it)"; continue }
        } else {
            if ($text.Contains($f.New)) { Write-Host "ok        $($f.File) (already fixed)"; continue }
            $count = ([regex]::Matches($text, [regex]::Escape($f.Old))).Count
            if ($count -ne 1) { Write-Warning "skipped   $($f.File) (expected the broken line once, found $count; CDPR may have fixed it)"; continue }
            $fixed = $text.Replace($f.Old, $f.New)
        }
        if ($fixed -ceq $current) { Write-Host "ok        $($f.File) (already fixed)"; continue }
        if (-not (Test-Path $backup)) { Copy-Item $path $backup }
        [IO.File]::WriteAllText($path, $fixed)
        Write-Host "fixed     $($f.File)"
        $changed = $true
    }

    if ($bridge) {
        $target = Join-Path $pluginDir "$PluginName.dll"
        if ($dll -ne $target) { New-Item -ItemType Directory -Force $pluginDir | Out-Null; Copy-Item $dll $target -Force; Write-Host "installed red4ext\plugins\$PluginName" }
    } elseif (Test-Path $pluginDir) {
        Remove-Item $pluginDir -Recurse -Force; Write-Host "removed   red4ext\plugins\$PluginName"
    }
    if ($changed) { Remove-Deployed }

    Write-Host ""
    Write-Host "Done. Deploy again from the launcher or your mod manager. To deploy by hand:"
    Write-Host "  & `"$GamePath\tools\redmod\bin\redMod.exe`" deploy -root `"$GamePath`" -rttiSchemaPath `"$GamePath\tools\redmod\metadata.json`""
    Write-Host "(-rttiSchemaPath matters only when running redMod.exe yourself: its default is relative to the current folder.)"
}

try {
    Invoke-Fix
} catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    $failed = $true
}
if (-not $NoPause) { Write-Host ""; [void](Read-Host "Press Enter to close") }
if ($failed) { exit 1 }
