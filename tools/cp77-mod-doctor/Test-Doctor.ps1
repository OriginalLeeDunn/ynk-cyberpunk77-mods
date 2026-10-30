# Builds small fake game folders for each kind of failure and checks that Doctor.ps1 reports the right thing.
# Usage: .\Test-Doctor.ps1      (nothing outside %TEMP% is touched)
$ErrorActionPreference = "Stop"
$doctor = Join-Path $PSScriptRoot "Doctor.ps1"
$root = Join-Path $env:TEMP ("doctor-tests-" + [guid]::NewGuid().ToString("N").Substring(0, 8))
$fail = 0

function New-Game([string]$name) {
    $g = Join-Path $root $name
    New-Item -ItemType Directory -Force (Join-Path $g "bin\x64") | Out-Null
    Set-Content (Join-Path $g "bin\x64\Cyberpunk2077.exe") "x"
    $g
}
function Add-Red4ext([string]$g, [bool]$loader = $true) {
    New-Item -ItemType Directory -Force (Join-Path $g "red4ext\logs") | Out-Null
    Set-Content (Join-Path $g "red4ext\RED4ext.dll") "x"
    if ($loader) { Set-Content (Join-Path $g "bin\x64\winmm.dll") "x" }
}
function Add-Log([string]$g, [string[]]$lines) {
    Set-Content (Join-Path $g "red4ext\logs\red4ext-2026-01-01-00-00-00.log") $lines
}
function Run-Doctor([string]$g) { (& $doctor -GamePath $g *>&1 | Out-String) }
function Check([string]$case, [string]$out, [string[]]$must, [string[]]$mustNot = @()) {
    $bad = @()
    foreach ($m in $must) { if ($out -notmatch [regex]::Escape($m)) { $bad += "missing: $m" } }
    foreach ($m in $mustNot) { if ($out -match [regex]::Escape($m)) { $bad += "unexpected: $m" } }
    if ($bad) { Write-Host "FAIL  $case  ($($bad -join '; '))" -ForegroundColor Red; $script:fail++ } else { Write-Host "ok    $case" -ForegroundColor Green }
}
$ts = "[2026-01-01 00:00:00.000] [info    ] [ 1] [RED4ext]"

# 1. RED4ext installed, never wrote a log
$g = New-Game "nolog"; Add-Red4ext $g
Check "no log at all" (Run-Doctor $g) @("has never written a log")

# 2. RED4ext installed but its loader dll is missing
$g = New-Game "noloader"; Add-Red4ext $g $false
Check "loader missing" (Run-Doctor $g) @("its loader is missing")

# 3. game stopped while a plugin was loading
$g = New-Game "plugincrash"; Add-Red4ext $g
Add-Log $g @("$ts Loading plugin from 'C:\game\red4ext\plugins\OldMod\OldMod.dll'...")
Check "crash while loading a plugin" (Run-Doctor $g) @("while loading the plugin OldMod.dll")

# 4. healthy session: no FAIL
$g = New-Game "healthy"; Add-Red4ext $g
Add-Log $g @("$ts Loading plugin from 'C:\game\red4ext\plugins\TweakXL\TweakXL.dll'...", "$ts TweakXL (version: 1.12.0, author(s): psiberx) has been loaded", "$ts RED4ext has been started", "$ts scc invoked successfully, 100 source refs were registered", "$ts RED4ext is shutting down...", "$ts RED4ext has been shut down")
Check "healthy install" (Run-Doctor $g) @("TweakXL 1.12.0", "No problems found") @("[FAIL]")

# 5. started but never reached the compiler, no failure line
$g = New-Game "nocompile"; Add-Red4ext $g
Add-Log $g @("$ts RED4ext has been started")
Check "stopped before redscript" (Run-Doctor $g) @("stopped before redscript finished")

# 6. graphics hook next to the exe
$g = New-Game "dxgi"; Set-Content (Join-Path $g "bin\x64\dxgi.dll") "x"
Check "graphics hook" (Run-Doctor $g) @("Found dxgi.dll")

# 7. two mods add the same method
$g = New-Game "dupes"
foreach ($m in "ModA", "ModB") { New-Item -ItemType Directory -Force (Join-Path $g "r6\scripts\$m") | Out-Null; Set-Content (Join-Path $g "r6\scripts\$m\x.reds") "@addMethod(PlayerPuppet)`npublic func Helper() -> Void {}" }
Check "duplicate added method" (Run-Doctor $g) @("Two mods add the same method: PlayerPuppet.Helper", "ModA", "ModB")

# 8. compile error from an installed mod is a FAIL; from a mod that is gone it is only INFO
$g = New-Game "rserr"; New-Item -ItemType Directory -Force (Join-Path $g "r6\logs"), (Join-Path $g "r6\scripts\Bad") | Out-Null
Set-Content (Join-Path $g "r6\scripts\Bad\y.reds") "x"
Set-Content (Join-Path $g "r6\logs\redscript_rCURRENT.log") @("[ERROR - Thu, 01 Jan 2026 00:00:00 -0700] [UNRESOLVED_METHOD] At $g\r6\scripts\Bad\y.reds:4:18:", "  let x = this.Nope();", "method 'Nope' not found on 'PlayerPuppet'", "[ERROR - Thu, 01 Jan 2026 00:00:00 -0700] [UNRESOLVED_METHOD] At $g\r6\scripts\Gone\z.reds:1:1:", "  x", "method 'Y' not found")
$out = Run-Doctor $g
Check "compile error, mod installed" $out @("[FAIL] #1 redscript could not compile: Bad", "y.reds:4")
Check "compile error, mod gone" $out @("Old compile error from a mod that is gone: Gone")

Remove-Item $root -Recurse -Force -ErrorAction SilentlyContinue
if ($fail) { Write-Host "`n$fail test(s) failed." -ForegroundColor Red; exit 1 } else { Write-Host "`nAll tests passed." -ForegroundColor Green }
