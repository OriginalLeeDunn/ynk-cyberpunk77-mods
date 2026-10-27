# Copy one mod into the local mod-lab game for testing.
# Usage: .\tools\deploy.ps1 -Mod unity-extended-magazine [-Game 'C:\Modding\Cyberpunk 2077']
param(
    [Parameter(Mandatory = $true)][string]$Mod,
    [string]$Game = 'C:\Modding\Cyberpunk 2077'
)
$ErrorActionPreference = 'Stop'
$src = Join-Path (Split-Path $PSScriptRoot) "mods\$Mod"
if (-not (Test-Path $src)) { throw "no such mod: $src" }
if (-not (Test-Path $Game)) { throw "game folder not found: $Game" }

# everything except the mod's README mirrors the game folder
$items = Get-ChildItem $src | Where-Object { $_.Name -ne 'README.md' }
foreach ($i in $items) { Copy-Item -Path $i.FullName -Destination $Game -Recurse -Force }
$files = Get-ChildItem $src -Recurse -File | Where-Object { $_.Name -ne 'README.md' -or $_.DirectoryName -ne $src }
foreach ($f in $files) { Write-Host ("  deployed " + $f.FullName.Substring($src.Length + 1)) }
Write-Host "deployed $Mod to $Game (restart the game to load TweakXL/redscript changes)"
