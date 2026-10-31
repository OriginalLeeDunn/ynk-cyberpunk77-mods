# YNK Cyberpunk 2077 Mod Doctor
# Finds out why a modded Cyberpunk 2077 (PC) won't start or is broken, and says which mod or file to look at.
# Read-only: it never changes, moves or deletes anything in your game folder. It reads the logs the game and
# its frameworks leave behind, checks the install, and (with -Compile) recompiles every redscript mod in a
# temp folder with the game's own compiler to name the mod and line that fails.
# What it looks at:
#   - game version, and the RED4ext / redscript / TweakXL / ArchiveXL / Codeware / CET frameworks
#   - the newest RED4ext log: did it start, which plugin it was loading when it stopped, errors and warnings
#   - the redscript log: every compile error, grouped by mod, with file and line
#   - evidence of a crash with no log: CrashInfo.json, Windows "Application Error" events (faulting module)
#   - mods in the wrong place, known troublemakers (ReShade/OptiScaler hooks, leftover cybercmd)
#   - with -Compile: two mods adding the same method, and every compile error against THIS game version
# Usage (PowerShell, from anywhere):
#   .\Doctor.ps1                                  # finds the Steam/GOG/Epic install, or asks
#   .\Doctor.ps1 -GamePath "D:\Games\Cyberpunk 2077"
#   .\Doctor.ps1 -Compile                         # also compile-check all redscript mods (takes ~20 s)
#   .\Doctor.ps1 -ReportPath "$env:USERPROFILE\Desktop\doctor.txt"   # also save the report to paste for help
param(
    [string]$GamePath,
    [switch]$Compile,
    [string]$ReportPath,
    [switch]$NoPause
)
$ErrorActionPreference = "Stop"
function Wait-Close { if (-not $NoPause) { Write-Host ""; try { [void](Read-Host "Press Enter to close") } catch { } } }      # Run with PowerShell closes the window as soon as the script ends
trap { Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red; Wait-Close; exit 1 }
$findings = New-Object System.Collections.ArrayList
$script:log = New-Object System.Text.StringBuilder

function Say([string]$text, [string]$color = "Gray") {
    Write-Host $text -ForegroundColor $color
    [void]$script:log.AppendLine($text)
}

# severity: FAIL = this stops the game or a mod, WARN = likely a problem, INFO = good to know
function Add-Finding([string]$sev, [string]$title, [string]$detail, [string]$fix) {
    [void]$findings.Add([pscustomobject]@{ Sev = $sev; Title = $title; Detail = $detail; Fix = $fix })
}

function Find-Game {
    $candidates = New-Object System.Collections.ArrayList
    foreach ($d in [IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq "Fixed" }) {
        $r = $d.RootDirectory.FullName
        foreach ($rel in "Program Files (x86)\Steam\steamapps\common", "Program Files\Steam\steamapps\common", "SteamLibrary\steamapps\common", "GOG Games", "Program Files (x86)\GOG Galaxy\Games", "Program Files\Epic Games", "Games") {
            [void]$candidates.Add((Join-Path $r "$rel\Cyberpunk 2077"))
        }
    }
    # extra Steam libraries listed by Steam itself
    $vdf = "C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf"
    if (Test-Path $vdf) {
        foreach ($m in [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"')) {
            [void]$candidates.Add((Join-Path ($m.Groups[1].Value -replace '\\\\', '\') "steamapps\common\Cyberpunk 2077"))
        }
    }
    foreach ($c in $candidates) { if (Test-Path (Join-Path $c "bin\x64\Cyberpunk2077.exe")) { return $c } }
    return $null
}

# "C:\...\r6\scripts\SomeMod\x.reds" or "...\red4ext\plugins\TweakXL\Scripts\..." -> "SomeMod" / "TweakXL"
function Get-ModName([string]$path, [string]$game) {
    $rel = $path
    if ($path.StartsWith($game, [StringComparison]::OrdinalIgnoreCase)) { $rel = $path.Substring($game.Length).TrimStart('\') }
    $parts = $rel -split '\\'
    if ($parts.Count -ge 3 -and $parts[0] -eq 'r6' -and $parts[1] -eq 'scripts') { if ($parts.Count -gt 3) { return $parts[2] } else { return "(loose file) " + $parts[2] } }
    if ($parts.Count -ge 3 -and $parts[0] -eq 'red4ext' -and $parts[1] -eq 'plugins') { return $parts[2] + " (framework)" }
    if ($parts.Count -ge 2 -and $parts[0] -eq 'mods') { return $parts[1] + " (REDmod)" }
    return $rel
}

if (-not $GamePath) { $GamePath = Find-Game }
if (-not $GamePath) { $GamePath = Read-Host "Could not find Cyberpunk 2077. Enter the game folder (the one that contains bin\x64)" }
$GamePath = $GamePath.Trim('"').TrimEnd('\')
$exe = Join-Path $GamePath "bin\x64\Cyberpunk2077.exe"
if (-not (Test-Path $exe)) { Write-Host "No bin\x64\Cyberpunk2077.exe under '$GamePath'." -ForegroundColor Red; Wait-Close; exit 1 }

Say "YNK Cyberpunk 2077 Mod Doctor" "Cyan"
Say "Game folder: $GamePath"
$ver = (Get-Item $exe).VersionInfo
Say "Game exe: $($ver.ProductVersion)  (file date $((Get-Item $exe).LastWriteTime.ToString('yyyy-MM-dd')))"

# --- is the game running right now? Logs of a running game are incomplete by design.
$running = Get-Process Cyberpunk2077 -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe }
if ($running) { Add-Finding "INFO" "The game is running right now" "Logs from a running game are still being written, so 'missing' lines below may just mean it has not got there yet." "Close the game and run the Doctor again for a full picture." }

# --- frameworks present
$red4extDll = Join-Path $GamePath "red4ext\RED4ext.dll"
$hasRed4ext = Test-Path $red4extDll
$cet = Join-Path $GamePath "bin\x64\plugins\cyber_engine_tweaks.asi"
$scc = Join-Path $GamePath "engine\tools\scc.exe"
$hasRedscript = Test-Path $scc
$frameworks = @(
    @("RED4ext", $hasRed4ext), @("redscript (scc.exe)", $hasRedscript), @("Cyber Engine Tweaks", (Test-Path $cet)),
    @("TweakXL", (Test-Path (Join-Path $GamePath "red4ext\plugins\TweakXL\TweakXL.dll"))),
    @("ArchiveXL", (Test-Path (Join-Path $GamePath "red4ext\plugins\ArchiveXL\ArchiveXL.dll"))),
    @("Codeware", (Test-Path (Join-Path $GamePath "red4ext\plugins\Codeware\Codeware.dll")))
)
Say ""
Say "Frameworks:" "Cyan"
foreach ($f in $frameworks) { Say ("  {0,-22} {1}" -f $f[0], $(if ($f[1]) { "installed" } else { "-" })) }

# RED4ext loads through a proxy dll in bin\x64; without it RED4ext (and everything on it) silently never starts.
if ($hasRed4ext) {
    $proxy = @("winmm.dll", "version.dll") | Where-Object { Test-Path (Join-Path $GamePath "bin\x64\$_") }
    if (-not $proxy) {
        Add-Finding "FAIL" "RED4ext is installed but its loader is missing" "RED4ext starts through a proxy dll in bin\x64 (winmm.dll). None is there, so RED4ext, redscript, TweakXL, ArchiveXL and Codeware never run and the game starts with no mods and no log." "Reinstall RED4ext (the zip from its Nexus/GitHub page) over the game folder."
    }
}
if ((Test-Path (Join-Path $GamePath "bin\x64\plugins\cyber_engine_tweaks.asi")) -and -not (Test-Path (Join-Path $GamePath "bin\x64\version.dll")) -and -not (Test-Path (Join-Path $GamePath "bin\x64\winmm.dll"))) {
    Add-Finding "WARN" "CET is installed but no ASI loader found" "Cyber Engine Tweaks needs an ASI loader (version.dll) next to it." "Reinstall Cyber Engine Tweaks."
}
foreach ($bad in @(@("dxgi.dll", "ReShade / OptiScaler hook"), @("d3d11.dll", "graphics hook (ReShade/other)"), @("OptiScaler.dll", "OptiScaler"), @("ReShade64.dll", "ReShade"))) {
    $p = Join-Path $GamePath ("bin\x64\" + $bad[0])
    if (Test-Path $p) { Add-Finding "WARN" ("Found " + $bad[0] + " in bin\x64 (" + $bad[1] + ")") "Graphics hooks and upscaler injectors are a common cause of the game closing at startup after a patch, with nothing in any log." ("Move " + $bad[0] + " out of bin\x64 temporarily and try again.") }
}
if (Test-Path (Join-Path $GamePath "red4ext\plugins\cybercmd")) { Add-Finding "WARN" "Old 'cybercmd' plugin present" "cybercmd is obsolete and conflicts with current RED4ext/redscript." "Remove red4ext\plugins\cybercmd." }

# --- RED4ext log
$logDir = Join-Path $GamePath "red4ext\logs"
$rlog = $null
if (Test-Path $logDir) { $rlog = Get-ChildItem $logDir -Filter "*.log" | Sort-Object LastWriteTime | Select-Object -Last 1 }
$loadedPlugins = @{}
Say ""
Say "RED4ext log:" "Cyan"
if (-not $hasRed4ext) {
    Say "  RED4ext is not installed (mods that need it won't load)."
} elseif (-not $rlog) {
    Say "  No log found."
    Add-Finding "FAIL" "RED4ext is installed but has never written a log" "The game was either never started since RED4ext was installed, or RED4ext was blocked before it could run (antivirus, missing Visual C++ runtime, wrong game version, or the proxy dll was removed)." "Check your antivirus quarantine for RED4ext.dll/winmm.dll and restore them; install the Microsoft Visual C++ Redistributable (x64); reinstall RED4ext for your game version."
} else {
    Say "  $($rlog.Name)  ($($rlog.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')))"
    $lines = Get-Content $rlog.FullName
    $started = $false; $sccOk = $false; $sccFailed = $false; $blob = $false; $shutdown = $false; $pending = $null; $err = New-Object System.Collections.ArrayList
    foreach ($l in $lines) {
        if ($l -match "Loading plugin from '([^']+)'") { $pending = $Matches[1] }
        if ($l -match "\[RED4ext\] (.+?) \(version: ([^,]+),.*has been loaded") { $loadedPlugins[$Matches[1]] = $Matches[2]; $pending = $null }
        if ($l -match "scc invocation failed") { $sccFailed = $true }
        if ($l -match "RED4ext has been started") { $started = $true }
        if ($l -match "scc invoked successfully") { $sccOk = $true }
        if ($l -match "Modded scripts blob is set") { $blob = $true }
        if ($l -match "RED4ext has been shut down") { $shutdown = $true }
        if ($l -match "\[(error|warning|critical)\s*\]") { [void]$err.Add($l) }
    }
    foreach ($k in $loadedPlugins.Keys) { Say ("  plugin {0} {1}" -f $k, $loadedPlugins[$k]) }
    if ($pending -and $pending -notmatch 'Cyberpunk2077\.exe') {
        Add-Finding "FAIL" ("The game stopped while loading the plugin " + (Split-Path $pending -Leaf)) "The last thing RED4ext did was start loading '$pending' and it never finished. That plugin crashed the game, usually because it is outdated for this game version." ("Update or remove " + (Split-Path $pending -Leaf) + " (folder: " + (Split-Path $pending -Parent) + ") and start the game again.")
    }
    foreach ($e in $err | Select-Object -First 15) {
        $sev = "WARN"; if ($e -match "\[(error|critical)") { $sev = "FAIL" }
        $msg = ($e -replace '^\[[^\]]*\]\s*\[[^\]]*\]\s*\[[^\]]*\]\s*\[RED4ext\]\s*', '')
        $fix = "Look up that message in the RED modding wiki troubleshooting guide; if it names a plugin, update or remove it."
        if ($msg -match 'version|compat|requires') { $fix = "That plugin does not match this game version. Update it (or the game) so they agree." }
        if ($msg -match 'scc invocation failed') { $fix = "A script mod failed to compile: see the 'redscript could not compile' finding for the mod and line. The game still starts, but no redscript mod works until it is fixed." }
        Add-Finding $sev "RED4ext reported: $msg" "From $($rlog.Name)." $fix
    }
    if ($started -and -not $sccOk -and -not $sccFailed -and -not $blob -and -not $running) {
        Add-Finding "FAIL" "The game stopped before redscript finished" "RED4ext started but never reported that the script compiler ran. The game likely closed while compiling scripts (a script mod or a stale script cache)." "Close the game, delete the folder r6\cache\modded (if it exists), then run the Doctor with -Compile to find the failing script."
    }
    if ($started -and $sccOk -and -not $shutdown -and -not $running) {
        Add-Finding "WARN" "The last session ended without a normal shutdown" "RED4ext did not log 'shut down', so the game most likely crashed or was killed while playing, after mods loaded fine." "Check the crash evidence below (CrashInfo.json / Windows event log) for the faulting file."
    }
    if (-not $started) { Add-Finding "FAIL" "RED4ext never reached 'started'" "The log ends before RED4ext finished loading." "See the plugin line above, or reinstall RED4ext." }
}

# --- redscript log: every compile error with its mod
$rsLog = Join-Path $GamePath "r6\logs\redscript_rCURRENT.log"
$compileErrors = New-Object System.Collections.ArrayList
Say ""
Say "redscript log:" "Cyan"
if (Test-Path $rsLog) {
    $rsLines = Get-Content $rsLog
    $okLine = $rsLines | Where-Object { $_ -match "Compilation complete" } | Select-Object -Last 1
    for ($i = 0; $i -lt $rsLines.Count; $i++) {
        if ($rsLines[$i] -match '\[(?:ERROR|FATAL)[^\]]*\]\s+(?:\[(\w+)\]\s+)?At\s+(.+?):(\d+):(\d+):') {
            $code = $Matches[1]; $file = $Matches[2]; $ln = $Matches[3]
            $msg = ""; for ($j = $i + 1; $j -lt [Math]::Min($i + 6, $rsLines.Count); $j++) { if ($rsLines[$j] -match '^\[') { break }; if ($rsLines[$j].Trim()) { $msg = $rsLines[$j].Trim() } }
            [void]$compileErrors.Add([pscustomobject]@{ Mod = (Get-ModName $file $GamePath); File = $file; Line = $ln; Code = $code; Msg = $msg })
        }
    }
    Say "  $($rsLog)  ($((Get-Item $rsLog).LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')))"
    if ($compileErrors.Count -gt 0) {
        foreach ($g in $compileErrors | Group-Object Mod) {
            $first = $g.Group | Select-Object -First 3 | ForEach-Object { "$(Split-Path $_.File -Leaf):$($_.Line)  [$($_.Code)] $($_.Msg)" }
            if (-not (Test-Path $g.Group[0].File)) {
                Add-Finding "INFO" ("Old compile error from a mod that is gone: " + $g.Name) (($first -join "`n    ")) "The log is from an earlier launch and that file no longer exists. Start the game once to refresh the log."
                continue
            }
            Add-Finding "FAIL" ("redscript could not compile: " + $g.Name) (($first -join "`n    ")) ("Update " + $g.Name + " to a version made for your game version, or remove it. While any script fails to compile, NO redscript mod works (the game still starts).")
        }
    } elseif ($okLine) {
        Say "  last compile succeeded."
    } else {
        Say "  no compile result in the log."
    }
} else {
    Say "  no redscript log (redscript not installed, or the game never ran with it)."
}

# --- crash with no log: CrashInfo.json and the Windows event log
Say ""
Say "Crash evidence:" "Cyan"
$ci = Join-Path $env:LOCALAPPDATA "CD Projekt Red\Cyberpunk 2077\CrashInfo.json"
if (Test-Path $ci) {
    try {
        $c = (Get-Content $ci -Raw | ConvertFrom-Json).Data.postMortem
        $when = [datetime]::Parse($c.timeCrash).ToLocalTime()
        Say ("  CrashInfo.json: crash on patch {0} at {1}, {2} s into the session" -f $c.crashPatch, $when.ToString("yyyy-MM-dd HH:mm"), [int]$c.sessionLength)
        if ($c.sessionLength -lt 120) { Add-Finding "WARN" "The last recorded crash happened within 2 minutes of starting" ("CrashInfo.json: patch " + $c.crashPatch + ", " + $when.ToString("yyyy-MM-dd HH:mm") + ", session length " + [int]$c.sessionLength + " s. A crash this early points at a mod, a plugin or a graphics hook rather than gameplay.") "Start with the plugin / compile findings above; if there are none, disable mods in halves to find the culprit." }
    } catch { Say "  CrashInfo.json present but unreadable." }
} else { Say "  no CrashInfo.json." }
try {
    $ev = Get-WinEvent -FilterHashtable @{ LogName = 'Application'; ProviderName = 'Application Error'; StartTime = (Get-Date).AddDays(-14) } -MaxEvents 300 -ErrorAction Stop | Where-Object { $_.Message -match 'Cyberpunk2077' } | Select-Object -First 3
    foreach ($e in $ev) {
        $mod = ""; if ($e.Message -match 'Faulting module name:\s*([^,\r\n]+)') { $mod = $Matches[1].Trim() }
        $code = ""; if ($e.Message -match 'Exception code:\s*(\S+)') { $code = $Matches[1] }
        Say ("  Windows event {0}: faulting module {1}, exception {2}" -f $e.TimeCreated.ToString("yyyy-MM-dd HH:mm"), $mod, $code)
        $fixText = "Update or remove whatever that module belongs to."
        if ($mod -match 'Cyberpunk2077\.exe') { $fixText = "The crash was inside the game itself. A mod is usually still the trigger: update or disable mods and test again." }
        Add-Finding "WARN" ("Windows recorded a crash in " + $mod + " (" + $e.TimeCreated.ToString("yyyy-MM-dd HH:mm") + ")") ("Exception code " + $code + ". This is recorded even when the game writes no log.") $fixText
    }
    if (-not $ev) { Say "  no Cyberpunk2077.exe crashes in the Windows event log (last 14 days)." }
} catch { Say "  could not read the Windows event log." }

# --- mod inventory and mods in the wrong place
Say ""
Say "Installed mods:" "Cyan"
$scriptsDir = Join-Path $GamePath "r6\scripts"
$redsFiles = @(); if (Test-Path $scriptsDir) { $redsFiles = Get-ChildItem $scriptsDir -Recurse -Filter *.reds -File }
$archives = @(); $archDir = Join-Path $GamePath "archive\pc\mod"; if (Test-Path $archDir) { $archives = Get-ChildItem $archDir -File | Where-Object { $_.Extension -in ".archive", ".xl" } }
$tweaks = @(); $twDir = Join-Path $GamePath "r6\tweaks"; if (Test-Path $twDir) { $tweaks = Get-ChildItem $twDir -Recurse -File }
$cetMods = @(); $cetDir = Join-Path $GamePath "bin\x64\plugins\cyber_engine_tweaks\mods"; if (Test-Path $cetDir) { $cetMods = Get-ChildItem $cetDir -Directory }
$redmods = @(); $rmDir = Join-Path $GamePath "mods"; if (Test-Path $rmDir) { $redmods = Get-ChildItem $rmDir -Directory }
Say "  redscript files: $($redsFiles.Count)   archives: $($archives.Count)   TweakXL files: $($tweaks.Count)   CET mods: $($cetMods.Count)   REDmod mods: $($redmods.Count)"
foreach ($f in Get-ChildItem $GamePath -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in ".reds", ".archive", ".lua", ".yaml" }) {
    Add-Finding "WARN" ("Mod file in the game root: " + $f.Name) "Mod files directly in the game folder are not loaded, and usually mean a mod was extracted to the wrong place." "Move it to the folder its page says (r6\scripts, archive\pc\mod, r6\tweaks ...)."
}
foreach ($f in Get-ChildItem $scriptsDir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq ".zip" -or $_.Extension -eq ".rar" -or $_.Extension -eq ".7z" }) {
    Add-Finding "WARN" ("Archive file inside r6\scripts: " + $f.Name) "A zip left in the scripts folder is ignored." "Extract it properly or delete it."
}
# nested duplicate: r6\scripts\Mod\Mod\x.reds is fine, but a mod folder with no .reds inside is a leftover
foreach ($d in Get-ChildItem $scriptsDir -Directory -ErrorAction SilentlyContinue) {
    if (-not (Get-ChildItem $d.FullName -Recurse -Filter *.reds -File -ErrorAction SilentlyContinue)) { Add-Finding "INFO" ("Empty script folder: r6\scripts\" + $d.Name) "No .reds files inside; leftover of an uninstalled mod." "Safe to delete." }
}

# --- two mods adding the same method to the same class (text scan, no compile needed)
$added = @{}
foreach ($f in $redsFiles) {
    $txt = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $txt) { continue }
    foreach ($m in [regex]::Matches($txt, '@addMethod\((\w+)\)\s*(?:public|protected|private|final|static|\s)*func\s+(\w+)')) {
        $key = $m.Groups[1].Value + "." + $m.Groups[2].Value
        if (-not $added.ContainsKey($key)) { $added[$key] = New-Object System.Collections.ArrayList }
        [void]$added[$key].Add((Get-ModName $f.FullName $GamePath))
    }
}
foreach ($k in $added.Keys) {
    $mods = $added[$k] | Select-Object -Unique
    if (@($mods).Count -gt 1) {
        Add-Finding "FAIL" ("Two mods add the same method: " + $k) ("Added by: " + ($mods -join ", ") + ". The game's compiler rejects duplicate added methods, so NO redscript mod works until one of them is removed.") ("Remove or update one of: " + ($mods -join ", ") + ". Ask the authors to prefix their added names.")
    }
}

# --- offline compile against THIS game version, into a temp folder (never touches your cache)
if ($Compile) {
    Say ""
    Say "Compile check:" "Cyan"
    $blobSrc = Join-Path $GamePath "r6\cache\final.redscripts"
    if (-not $hasRedscript) { Say "  redscript (scc.exe) is not installed, nothing to compile with."; }
    elseif (-not (Test-Path $blobSrc)) { Say "  r6\cache\final.redscripts not found: start the game once (or verify files) so it exists." ; Add-Finding "WARN" "The game's base script cache is missing" "r6\cache\final.redscripts does not exist." "Verify the game files in Steam/GOG, then start the game once." }
    else {
        $tmp = Join-Path $env:TEMP ("cp77-doctor-" + [guid]::NewGuid().ToString("N").Substring(0, 8))
        New-Item -ItemType Directory -Force (Join-Path $tmp "cache") | Out-Null
        Copy-Item $blobSrc (Join-Path $tmp "cache\final.redscripts")
        foreach ($ext in ".ts") { $x = $blobSrc + $ext; if (Test-Path $x) { Copy-Item $x (Join-Path $tmp "cache\final.redscripts$ext") } }
        $paths = Join-Path $GamePath "red4ext\redscript_paths.txt"
        # compile a temp COPY of r6\scripts: scc puts its log under <scripts folder>\..\logs, which would be the game's own
        $tmpScripts = Join-Path $tmp "r6\scripts"
        New-Item -ItemType Directory -Force $tmpScripts | Out-Null
        if (Test-Path $scriptsDir) { Copy-Item (Join-Path $scriptsDir "*") $tmpScripts -Recurse -Force }
        $sccArgs = @("-compile", $tmpScripts, (Join-Path $tmp "cache\final.redscripts"), "-Wnone", "-threads", "4", "-no-testonly", "-no-breakpoint", "-no-exec", "-no-debug", "-profile=off")
        if (Test-Path $paths) { $sccArgs += @("-compilePathsFile", $paths) }
        $outFile = Join-Path $tmp "scc-out.txt"
        # scc writes its log next to where it lives (<root>\r6\logs), so run a copy from the temp folder
        # instead of the game's own copy, or the check would overwrite the game's real redscript log.
        $tmpTools = Join-Path $tmp "engine\tools"
        New-Item -ItemType Directory -Force $tmpTools | Out-Null
        Copy-Item $scc $tmpTools
        $lib = Join-Path (Split-Path $scc -Parent) "scc_lib.dll"; if (Test-Path $lib) { Copy-Item $lib $tmpTools }
        $sccTmp = Join-Path $tmpTools "scc.exe"
        Push-Location $tmp
        try { & $sccTmp @sccArgs *> $outFile } catch { }
        Pop-Location
        $text = ""; if (Test-Path $outFile) { $text = (Get-Content $outFile -Raw).Replace($tmpScripts, $scriptsDir) }   # show the real paths
        $cl = @(); if ($text) { $cl = $text -split "`r?`n" }   # scc prints its errors on stdout
        $errs = New-Object System.Collections.ArrayList
        # warnings worth a line: an added method that clashes with an existing one
        for ($i = 0; $i -lt $cl.Count; $i++) {
            if ($cl[$i] -match '\[WARN[^\]]*\]\s+At\s+(.+?):(\d+):(\d+):' -and (($cl[$i..([Math]::Min($i + 6, $cl.Count - 1))] -join " ") -match 'conflicts with an existing method')) {
                $m = Get-ModName $Matches[1] $GamePath; $where = (Split-Path $Matches[1] -Leaf) + ":" + $Matches[2]
                Add-Finding "WARN" ("Compile check: " + $m + " adds a method that already exists (" + $where + ")") "Another mod or the game already has a method with that name on the same class, which can cause a runtime error." "Ask the author to prefix the name, or remove one of the two mods."
            }
        }
        for ($i = 0; $i -lt $cl.Count; $i++) {
            if ($cl[$i] -match '\[(?:ERROR|FATAL)[^\]]*\]\s+(?:\[(\w+)\]\s+)?At\s+(.+?):(\d+):(\d+):') {
                $code = $Matches[1]; $file = $Matches[2]; $ln = $Matches[3]
                $msg = ""; for ($j = $i + 1; $j -lt [Math]::Min($i + 6, $cl.Count); $j++) { if ($cl[$j] -match '^\[') { break }; if ($cl[$j].Trim()) { $msg = $cl[$j].Trim() } }
                [void]$errs.Add([pscustomobject]@{ Mod = (Get-ModName $file $GamePath); File = $file; Line = $ln; Code = $code; Msg = $msg })
            }
        }
        if ($errs.Count -gt 0) {
            Say "  FAILED: $($errs.Count) error(s)."
            foreach ($g in $errs | Group-Object Mod) {
                if ($compileErrors | Where-Object { $_.Mod -eq $g.Name }) { continue }   # already reported from the real log
                $first = $g.Group | Select-Object -First 3 | ForEach-Object { "$(Split-Path $_.File -Leaf):$($_.Line)  [$($_.Code)] $($_.Msg)" }
                Add-Finding "FAIL" ("Compile check: " + $g.Name + " does not compile on this game version") ($first -join "`n    ") ("Update " + $g.Name + " or remove it. (Found by recompiling in a temp folder: your files were not touched.)")
            }
        } elseif ($text -match 'REDScript compilation has failed') {
            Say "  FAILED (see below)."
            $names = [regex]::Matches($text, '(?m)^- (.+?)\s*$') | ForEach-Object { $_.Groups[1].Value }
            Add-Finding "FAIL" "Compile check failed" ("The compiler named these mods: " + ($names -join ", ")) "Update or remove the named mods."
        } elseif ($text -match 'Compilation complete|Output successfully|successfully' -or (Test-Path (Join-Path $tmp "cache\final.redscripts.modded"))) {
            Say "  all redscript files compile against this game version."
        } else {
            Say "  the compiler produced no result (output kept at $outFile)."
            Add-Finding "INFO" "Compile check was inconclusive" "scc.exe ran but reported neither success nor errors." "Run with the game closed, and make sure r6\cache\final.redscripts is the untouched original (verify game files if unsure)."
            $tmp = $null
        }
        if ($tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    }
} else {
    Say ""
    Say "(Run again with -Compile to recompile every redscript mod and name the one that fails.)"
}

# --- verdict
Say ""
Say "================ RESULT ================" "Cyan"
$order = @{ "FAIL" = 0; "WARN" = 1; "INFO" = 2 }
$sorted = $findings | Sort-Object { $order[$_.Sev] }
if (-not $sorted) {
    Say "No problems found by these checks." "Green"
    Say "If the game still won't start with no log at all, the cause is outside mods: verify game files, update GPU drivers, and check antivirus quarantine."
} else {
    $n = 1
    foreach ($f in $sorted) {
        $c = "Yellow"; if ($f.Sev -eq "FAIL") { $c = "Red" } elseif ($f.Sev -eq "INFO") { $c = "Gray" }
        Say ("[{0}] #{1} {2}" -f $f.Sev, $n, $f.Title) $c
        if ($f.Detail) { Say ("    " + $f.Detail) }
        if ($f.Fix) { Say ("    -> " + $f.Fix) "White" }
        $n++
    }
}
if ($ReportPath) { Set-Content -Path $ReportPath -Value $script:log.ToString() -Encoding UTF8; Write-Host "`nReport saved to $ReportPath" -ForegroundColor Cyan }
Wait-Close
