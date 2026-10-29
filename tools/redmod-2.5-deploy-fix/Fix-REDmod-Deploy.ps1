# YNK REDmod 2.5 Deploy Fix
# Since patch 2.5, every REDmod deploy fails at "Stage 2/5 - Script Compilation" with:
#   ScriptCompiler: ERROR: Imported classes (like 'ISerializable') must derive from something.
# and, once that is fixed, with:
#   ScriptCompiler: ERROR: Unable to convert from '&script_ref<inkCompoundRef>' to 'inkWidgetRef'
# Both come from the script sources REDmod ships in tools\redmod\scripts, not from any mod:
# - mods\codeware\callbackSystem.script declares ISerializable (the engine's root class) as an imported
#   class with no parent, which this compiler only allows for IScriptable. Giving it a parent compiles
#   but the game then refuses to start ("Native class 'ISerializable' has declared base class ... that
#   is different"), so instead the fix removes the ISerializable and CResource declarations and the two
#   ResourceEvent members that return a CResource. Scripts may declare fewer native members than the
#   engine has; the only loss is ResourceEvent.GetResource() / .resource for REDmod scripts (GetPath()
#   stays). Nothing in the game's own scripts uses them.
# - tarot_main.script and inventoryItemMode.script pass a ref< inkCompoundRef > parameter to
#   inkWidgetRef.Get, which this compiler can't convert. Taking the parameter by value fixes it;
#   inkCompoundRef is a handle to a widget, so a copy refers to the same widget.
# The script edits these files in place (it ships no CDPR files), keeps a backup of each next to it
# (*.ynkfix-backup), skips anything already fixed, and -Undo restores the backups.
# Usage (PowerShell, from anywhere):
#   .\Fix-REDmod-Deploy.ps1                       # finds the Steam/GOG install, or asks
#   .\Fix-REDmod-Deploy.ps1 -GamePath "D:\Games\Cyberpunk 2077"
#   .\Fix-REDmod-Deploy.ps1 -Undo
param(
    [string]$GamePath,
    [switch]$Undo
)
$ErrorActionPreference = "Stop"

function Find-Game {
    $candidates = @(
        "C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077",
        "C:\Program Files\Steam\steamapps\common\Cyberpunk 2077",
        "C:\GOG Games\Cyberpunk 2077",
        "C:\Program Files (x86)\GOG Galaxy\Games\Cyberpunk 2077",
        "C:\Program Files\Epic Games\Cyberpunk 2077"
    )
    foreach ($d in [IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq "Fixed" }) {
        $candidates += Join-Path $d.RootDirectory "SteamLibrary\steamapps\common\Cyberpunk 2077"
    }
    foreach ($c in $candidates) {
        if (Test-Path (Join-Path $c "bin\x64\Cyberpunk2077.exe")) { return $c }
    }
    return $null
}

if (-not $GamePath) { $GamePath = Find-Game }
if (-not $GamePath) { $GamePath = Read-Host "Cyberpunk 2077 folder (the one containing bin, r6, tools)" }
$scripts = Join-Path $GamePath "tools\redmod\scripts"
if (-not (Test-Path $scripts)) {
    throw "REDmod isn't installed in '$GamePath' (no tools\redmod\scripts). Install the free REDmod DLC first."
}

# callbackSystem.script: drop the declarations the compiler can't accept (see the header). Regexes,
# so CRLF or LF line endings both match.
function Fix-CallbackSystem([string]$text) {
    $text = $text -replace "importonly abstract class ISerializable\r?\n\{\s*\}\r?\n(\r?\n)?", ""
    $text = $text -replace "import abstract class CResource extends ISerializable\r?\n\{[^}]*\}\r?\n(\r?\n)?", ""
    $text = $text -replace "[ \t]*import var resource : CResource;\r?\n(\r?\n)?", ""
    $text = $text -replace "[ \t]*public import function GetResource\(\) : CResource;\r?\n", ""
    return $text
}

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

foreach ($f in $fixes) {
    $path = Join-Path $scripts $f.File
    $backup = "$path.ynkfix-backup"
    if ($Undo) {
        if (Test-Path $backup) {
            Copy-Item $backup $path -Force
            Remove-Item $backup
            Write-Host "restored  $($f.File)"
        } else {
            Write-Host "no backup $($f.File) (nothing to undo)"
        }
        continue
    }
    if (-not (Test-Path $path)) { Write-Warning "missing   $($f.File) (REDmod version differs; skipped)"; continue }
    $text = [IO.File]::ReadAllText($path)
    if ($f.Func) {
        if ($text -notmatch "ISerializable|CResource") { Write-Host "ok        $($f.File) (already fixed)"; continue }
        $fixed = Fix-CallbackSystem $text
        if ($fixed -match "ISerializable|CResource") { Write-Warning "skipped   $($f.File) (unexpected layout; CDPR may have changed it)"; continue }
    } else {
        if ($text.Contains($f.New)) { Write-Host "ok        $($f.File) (already fixed)"; continue }
        $count = ([regex]::Matches($text, [regex]::Escape($f.Old))).Count
        if ($count -ne 1) { Write-Warning "skipped   $($f.File) (expected the broken line once, found $count; CDPR may have fixed it)"; continue }
        $fixed = $text.Replace($f.Old, $f.New)
    }
    if (-not (Test-Path $backup)) { Copy-Item $path $backup }
    [IO.File]::WriteAllText($path, $fixed)
    Write-Host "fixed     $($f.File)"
}

if (-not $Undo) {
    Write-Host ""
    Write-Host "Done. Deploy again from the launcher or your mod manager. To deploy by hand:"
    Write-Host "  & `"$GamePath\tools\redmod\bin\redMod.exe`" deploy -root `"$GamePath`" -rttiSchemaPath `"$GamePath\tools\redmod\metadata.json`""
    Write-Host "(-rttiSchemaPath matters only when running redMod.exe yourself: its default is relative to the current folder.)"
}
