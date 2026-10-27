# Builds the YNK Unity finish source files from vanilla JSON exports.
# Input: WolvenKit CLI JSON exports in $Work (see README "Rebuilding").
# Output: CR2W files in source\archive, ready for WolvenKit to pack.
# Two variants share one layout and differ only in the green of the accent stripes.
param(
    [string]$Work = 'C:\Modding\work',
    [string]$Cli = 'C:\Modding\tools\WolvenKit.Console-9.1.0\WolvenKit.CLI.exe'
)
$ErrorActionPreference = 'Stop'
Add-Type -Path (Join-Path (Split-Path $Cli) 'Newtonsoft.Json.dll')

$proj = Split-Path $PSScriptRoot
$stage = Join-Path $Work 'ynk-unity-stage'
$base = 'ynk\weapons\unity_ynk'
$outDir = Join-Path $proj "source\archive\$base"

$vanillaMesh  = 'base\weapons\firearms\handgun\constitutional_unity\entities\meshes\w_handgun__constitutional_unity__base1_01.mesh'
$metalGeneric = 'base\surfaces\materials\metal\metal_generic_hq\metal_generic_hq_01_30.mltemplate'
$techPlastic  = 'base\surfaces\materials\plastic\plastic_hq\plastic_tech_hq_01_30.mltemplate'

# Colorway: black + rust orange + neon green (YooNeqK logo)
$black      = '3eaf77_d42857'
$blackAlt   = '3eaf77_b0f317'
$rust       = '10896e_null'   # metal palettes
$rustPaint  = '2b21e0_null'   # paint_thick palette

# Variants: Id is the file/factory suffix, Template null keeps layer 11's paint material
$variants = @(
    @{ Id = '';       Factory = 'Preset_YNK_Unity';       Green = 'e76cbd_null'; Template = $null },        # brightest, reads lime-yellow
    @{ Id = '_green'; Factory = 'Preset_YNK_Unity_Green'; Green = '768da5_null'; Template = $techPlastic }  # truer green, plastic palette only
)

# PowerShell enumerates JObjects, so all access goes through SelectToken.
# '$value' keys need bracket syntax: "colorScale['`$value']".
function Read-J([string]$path) {
    # -NoEnumerate: otherwise the pipeline unrolls the JObject into its properties
    Write-Output -NoEnumerate ([Newtonsoft.Json.Linq.JObject]::Parse([IO.File]::ReadAllText($path)))
}
function Write-J($obj, [string]$path) {
    New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
    [IO.File]::WriteAllText($path, $obj.ToString([Newtonsoft.Json.Formatting]::Indented))
}
function Find-One([string]$pattern) {
    $f = Get-ChildItem (Join-Path $Work 'unity-json') -Recurse -Filter $pattern | Select-Object -First 1
    if (-not $f) { throw "Missing export: $pattern" }
    $f.FullName
}
function Set-Tok($obj, [string]$path, $value) {
    $t = $obj.SelectToken($path)
    if ($null -eq $t) { throw "Token not found: $path" }
    $t.Value = $value
}
function Set-Color($layer, [string]$name) { Set-Tok $layer "colorScale['`$value']" $name }

if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
New-Item -ItemType Directory -Force $stage | Out-Null
if (Test-Path $outDir) { Remove-Item -Recurse -Force $outDir }

$factoryRows = @()
foreach ($v in $variants) {
    $setup = "$base\ml_unity_ynk$($v.Id).mlsetup"
    $mesh  = "$base\w_handgun__unity_ynk$($v.Id)__base1_01.mesh"
    $appP  = "$base\w_handgun__unity_ynk$($v.Id).app"

    # 1. Paint job. Layers 11 and 12 are full body coats (12 on top, worn through in places).
    #    Hiding 12 leaves 11 as slide/side stripes over black metal, with layer 6 showing at the grip.
    $ml = Read-J (Find-One '*base1_01_default_unity.mlsetup.json')
    $neon1 = Read-J (Find-One '*base1_01_neon1_unity.mlsetup.json')
    $L = $ml.SelectToken('Data.RootChunk.layers')
    $N = $neon1.SelectToken('Data.RootChunk.layers')
    foreach ($i in 6, 11, 12) { $L[$i].Replace($N[$i].DeepClone()) }
    Set-Color $L[0] $black       # main brushed steel
    Set-Color $L[1] $black       # main metal
    Set-Color $L[3] $rust        # secondary metal
    Set-Color $L[4] $blackAlt    # metal parts
    Set-Color $L[6] $rustPaint   # shows at the grip
    Set-Color $L[11] $v.Green    # accent stripes
    if ($v.Template) { Set-Tok $L[11] "material.DepotPath['`$value']" $v.Template }
    Set-Tok $L[12] 'opacity' 0   # outer coat off
    foreach ($i in 7, 8) {       # brass/copper trim -> rust metal
        Set-Tok $L[$i] "material.DepotPath['`$value']" $metalGeneric
        Set-Color $L[$i] $rust
    }
    Write-J $ml (Join-Path $stage "ml_unity_ynk$($v.Id).mlsetup.json")

    # 2. Mesh: point the default fpp/tpp materials at this paint, tint the sight glow neon green
    $m = Read-J (Find-One 'w_handgun__constitutional_unity__base1_01.mesh.json')
    $mats = $m.SelectToken('Data.RootChunk.localMaterialBuffer.materials')
    foreach ($i in 0, 8) {
        Set-Tok $mats[$i] "values[?(@.MultilayerSetup)].MultilayerSetup.DepotPath['`$value']" $setup
    }
    $glow = $mats[1].SelectToken('values[?(@.EmissiveColor)].EmissiveColor')
    Set-Tok $glow 'Red' 120; Set-Tok $glow 'Green' 255; Set-Tok $glow 'Blue' 30
    Write-J $m (Join-Path $stage "w_handgun__unity_ynk$($v.Id)__base1_01.mesh.json")

    # 3. Appearance file: the vanilla "default" appearance only, using this mesh
    $app = Read-J (Find-One 'w_handgun__constitutional_unity.app.json')
    $apps = $app.SelectToken('Data.RootChunk.appearances')
    if ($apps[0].SelectToken("Data.name['`$value']").Value -ne 'default') { throw 'First appearance is not default' }
    while ($apps.Count -gt 1) { $apps.RemoveAt(1) }
    $text = $app.ToString([Newtonsoft.Json.Formatting]::Indented)
    $escapedOld = $vanillaMesh.Replace('\', '\\')
    $count = ([regex]::Matches($text, [regex]::Escape($escapedOld))).Count
    if ($count -lt 2) { throw "Expected the body mesh path in components and compiledData, found $count" }
    $text = $text.Replace($escapedOld, $mesh.Replace('\', '\\'))
    [IO.File]::WriteAllText((Join-Path $stage "w_handgun__unity_ynk$($v.Id).app.json"), $text)
    "variant '$($v.Factory)': green $($v.Green), mesh path replaced $count times"

    $factoryRows += , @($v.Factory, $appP, 'false')
}

# 4. Factory: register the appearance resource names used by the TweakXL items
$csv = Read-J (Get-ChildItem (Join-Path $Work 'factories-base-json') -Filter 'weapons_appearances.csv.json').FullName
$rows = New-Object Newtonsoft.Json.Linq.JArray
foreach ($r in $factoryRows) { $rows.Add([Newtonsoft.Json.Linq.JArray]::FromObject([string[]]$r)) }
foreach ($k in 'compiledData', 'data') { $csv.SelectToken("Data.RootChunk.$k").Replace($rows.DeepClone()) }
Write-J $csv (Join-Path $stage 'ynk_unity.csv.json')

# 5. English item names and description
$loc = Read-J (Get-ChildItem (Join-Path $Work 'loc-json') -Recurse -File | Select-Object -First 1).FullName
$entries = [Newtonsoft.Json.Linq.JArray]::Parse(@'
[
  { "$type": "localizationPersistenceOnScreenEntry", "femaleVariant": "Unity YNK Edition", "maleVariant": "",
    "primaryKey": "0", "secondaryKey": "ynk-unity-finish-name" },
  { "$type": "localizationPersistenceOnScreenEntry", "femaleVariant": "Unity YNK Edition (Green)", "maleVariant": "",
    "primaryKey": "0", "secondaryKey": "ynk-unity-finish-green-name" },
  { "$type": "localizationPersistenceOnScreenEntry", "femaleVariant": "A Unity in YooNeqK colors: blacked-out steel, rust orange trim and neon green accents.", "maleVariant": "",
    "primaryKey": "0", "secondaryKey": "ynk-unity-finish-desc" }
]
'@)
$loc.SelectToken('Data.RootChunk.root.Data.entries').Replace($entries)
Write-J $loc (Join-Path $stage 'ynk_unity_finish.en-us.json.json')

# 6. JSON -> CR2W into the WolvenKit project
New-Item -ItemType Directory -Force $outDir | Out-Null
& $Cli convert deserialize $stage -o $outDir -v Minimal | Out-Null
$built = Get-ChildItem $outDir
if ($built.Count -ne 8) { throw "Expected 8 built files, got $($built.Count)" }
$built | Select-Object Name, Length
