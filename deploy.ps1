# Copy this mod into the mod lab game (C:\Modding\Cyberpunk 2077). Run from the repo root.
$game = 'C:\Modding\Cyberpunk 2077'
Copy-Item -Path (Join-Path $PSScriptRoot 'r6') -Destination $game -Recurse -Force
Write-Host "deployed r6\tweaks\YNK to $game"
