# Build the release zip for one mod: the game-folder tree plus the mod's README.
# Usage: .\tools\package.ps1 -Mod unity-extended-magazine -Version 1.0.0 [-Name 'YNK-Unity-Extended-Magazine'] [-Src <staged tree>]
param(
    [Parameter(Mandatory = $true)][string]$Mod,
    [Parameter(Mandatory = $true)][string]$Version,
    [string]$Name = '',
    [string]$OutDir = '',
    # Staged game-folder tree to zip instead of mods\<Mod> (for mods built from a WolvenKit project)
    [string]$Src = ''
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$src = if ($Src) { (Resolve-Path $Src).Path } else { Join-Path $root "mods\$Mod" }
if (-not (Test-Path $src)) { throw "no such mod: $src" }
if (-not $Name) { $Name = 'YNK-' + ((($Mod -split '-') | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) }) -join '-') }
if (-not $OutDir) { $OutDir = Join-Path $root 'dist' }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$zip = Join-Path $OutDir "$Name-$Version.zip"
if (Test-Path $zip) { Remove-Item $zip }
# Built by hand: Compress-Archive in Windows PowerShell 5.1 writes backslash paths, which the zip
# spec does not allow and some mod managers mishandle.
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::Open($zip, 'Create')
try {
    foreach ($f in Get-ChildItem $src -Recurse -File) {
        $entry = $f.FullName.Substring($src.Length + 1) -replace '\\', '/'
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entry, 'Optimal')
    }
} finally { $archive.Dispose() }
$hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
Write-Host "$zip"
Write-Host "sha256 $hash"
