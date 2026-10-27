# Packs source\archive into ynk_unity_finish.archive, stages the game-folder tree and builds the
# release zip with tools\package.ps1. Run build\make-ynk-unity.ps1 first.
# Usage: build\pack.ps1 -Version 1.0.0 [-Deploy]   (-Deploy also copies the files into the mod lab)
param(
    [Parameter(Mandatory = $true)][string]$Version,
    [switch]$Deploy,
    [string]$Cli = 'C:\Modding\tools\WolvenKit.Console-9.1.0\WolvenKit.CLI.exe',
    [string]$Game = 'C:\Modding\Cyberpunk 2077'
)
$ErrorActionPreference = 'Stop'
$proj = Split-Path $PSScriptRoot
$repo = Split-Path (Split-Path $proj)
$work = Join-Path $env:TEMP 'ynk-unity-finish-pack'
if (Test-Path $work) { Remove-Item -Recurse -Force $work }

# WolvenKit names the archive after the folder it packs
$packIn = Join-Path $work 'ynk_unity_finish'
New-Item -ItemType Directory -Force $packIn | Out-Null
Copy-Item (Join-Path $proj 'source\archive\*') $packIn -Recurse
& $Cli pack $packIn -o $work -v Minimal | Out-Null
$archive = Join-Path $work 'ynk_unity_finish.archive'
if (-not (Test-Path $archive)) { throw 'pack failed: no archive' }

$stage = Join-Path $work 'stage'
$mod = Join-Path $stage 'archive\pc\mod'
$tweaks = Join-Path $stage 'r6\tweaks\YNK'
New-Item -ItemType Directory -Force $mod, $tweaks | Out-Null
Copy-Item $archive $mod
Copy-Item (Join-Path $proj 'source\resources\ynk-unity-finish.archive.xl') (Join-Path $mod 'ynk_unity_finish.archive.xl')
Copy-Item (Join-Path $proj 'source\resources\r6\tweaks\YNK\ynk-unity-finish.yaml') $tweaks
Copy-Item (Join-Path $proj 'README.md') $stage

& (Join-Path $repo 'tools\package.ps1') -Mod ynk-unity-finish -Version $Version -Name 'YNK-Unity-Edition' -Src $stage

if ($Deploy) {
    Copy-Item (Join-Path $mod '*') (Join-Path $Game 'archive\pc\mod') -Force
    New-Item -ItemType Directory -Force (Join-Path $Game 'r6\tweaks\YNK') | Out-Null
    Copy-Item (Join-Path $tweaks '*') (Join-Path $Game 'r6\tweaks\YNK') -Force
    Write-Host "deployed to $Game"
}
