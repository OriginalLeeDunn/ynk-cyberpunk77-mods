# Build YNK Canto Blueprint the way mod.io does, and optionally install it for a
# local test. Needs the REDmod DLC.
#   .\build.ps1                 compile into ..\..\build\canto-blueprint-console (mod.io upload folder)
#   .\build.ps1 -Install        also copy the compiled patch to r6\c77 for a -LoadScriptMods test launch
#   .\build.ps1 -GamePath "D:\Games\Cyberpunk 2077"
# Two REDmod 2.5 quirks this works around:
# - validate-mod-scripts only compiles scripts under <mod>\r6\scripts (anywhere else it reports
#   success and does nothing);
# - it can't find the base game scripts when the game path contains spaces ("No Base Game blobs
#   found"), so it is given a junction to the game folder instead.
param(
    [string]$GamePath = "C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077",
    [switch]$Install
)
$ErrorActionPreference = "Stop"

$name = "YNK_CantoBlueprint"
$repo = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$out = Join-Path $repo "build\canto-blueprint-console"
if (Test-Path $out) { Remove-Item $out -Recurse -Force }
New-Item -ItemType Directory -Force (Join-Path $out "r6\scripts\YNK") | Out-Null
Copy-Item (Join-Path $PSScriptRoot "scripts\YNK\*.script") (Join-Path $out "r6\scripts\YNK")

$root = $GamePath
if ($GamePath.Contains(" ")) {
    $root = Join-Path $env:TEMP "cp77root"
    if (-not (Test-Path $root)) { New-Item -ItemType Junction -Path $root -Target $GamePath | Out-Null }
}
$redmod = Join-Path $root "tools\redmod\bin\redMod.exe"
if (-not (Test-Path $redmod)) { throw "REDmod isn't installed in '$GamePath'." }

Push-Location $root
try {
    $log = & $redmod validate-mod-scripts "-root=$root" -compile "-directory=$out" 2>&1
} finally {
    Pop-Location
}
$log | Where-Object { $_ -match "\.script\(|Success|Failed|rror" } | ForEach-Object { Write-Host $_ }
$blob = Join-Path $out "r6\cache\final.redscripts"
if (-not (Test-Path $blob)) { throw "Compile failed (no r6\cache\final.redscripts)." }
Write-Host "built  $out"

if ($Install) {
    if (Get-Process Cyberpunk2077 -ErrorAction SilentlyContinue) { throw "Close the game first." }
    $dest = Join-Path $GamePath "r6\c77\$name"
    New-Item -ItemType Directory -Force (Join-Path $dest "scripts") | Out-Null
    Copy-Item (Join-Path $out "about.json") $dest -Force
    Copy-Item $blob (Join-Path $dest "scripts\final.redscripts") -Force
    Copy-Item "$blob.h64" (Join-Path $dest "scripts\final.redscripts.h64") -Force
    Write-Host "installed  $dest  (launch the game with -LoadScriptMods)"
}
