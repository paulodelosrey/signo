<#
.SYNOPSIS
  Builds the bundled sign-video assets for Signo.

.DESCRIPTION
  Reproducible pipeline: takes the raw 200-clip Drive export and produces a
  size-budgeted subset under signo_app/assets/signs/, plus a manifest that
  maps each bundled clip to its original source file.

  Design constraints:
  - Audio is stripped. Sign language is visual; the clips carry no useful audio.
  - Output is H.264 High + yuv420p so Android hardware decodes it.
  - -movflags +faststart so playback can begin before the file is fully read.
  - Every clip is capped at 960px wide: the phone screen is 1080px, so a
    1080p source gains nothing once the UI chrome is accounted for.

.PARAMETER Priority
  Folder names in descending priority order. A folder is taken whole until the
  clip budget is exhausted.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools/compress-signs.ps1 -MaxClips 63
#>
[CmdletBinding()]
param(
  [string]$SourceDir = (Join-Path (Split-Path $PSScriptRoot -Parent) 'LSC-project'),
  [string]$OutDir    = (Join-Path (Split-Path $PSScriptRoot -Parent) 'signo_app\assets\signs'),
  [int]   $MaxClips  = 63,
  [int]   $Crf       = 28
)

$ErrorActionPreference = 'Stop'

$ffmpeg = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
if (-not $ffmpeg) {
  $ffmpeg = (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue |
             Select-Object -First 1).FullName
}
if (-not $ffmpeg) { throw 'ffmpeg not found. Install it before running this pipeline.' }

# Abecedario first: dactilology is the most visually legible content and the
# clips are already small. Then the phrases a judge is most likely to type.
$Priority = @('ABECEDARIO', 'FRASES COMUNES', 'ACCIONES')

# Files that are byte-level duplicates left behind by the Drive export or by
# Windows copy-conflict renaming. Verified against the vocabulary index.
$DuplicateOf = @{
  'ANTONIMOS|bueno(1)' = 'bueno'
  'ANTONIMOS|nuevo(1)' = 'nuevo'
  'LUGAR|aquí'         = 'aqui'
}

function ConvertTo-Slug([string]$name) {
  $d = $name.Normalize([System.Text.NormalizationForm]::FormD)
  $sb = New-Object System.Text.StringBuilder
  foreach ($ch in $d.ToCharArray()) {
    if ([System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne 'NonSpacingMark') {
      [void]$sb.Append($ch)
    }
  }
  $ascii = $sb.ToString().ToLowerInvariant()
  $ascii = $ascii -replace '[^a-z0-9]+', '_'
  return $ascii.Trim('_')
}

# The ABECEDARIO export contains one file whose name lost its encoding on the
# way out of Drive (it sits between N and O, so it is the tilde-N). Recover it
# under a name that survives a round trip.
$FixName = @{}

if (-not (Test-Path $SourceDir)) { throw "Source not found: $SourceDir" }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$selected = New-Object System.Collections.Generic.List[object]
$used = @{}
foreach ($folder in $Priority) {
  $dir = Join-Path $SourceDir $folder
  if (-not (Test-Path $dir)) { Write-Host "  (skip: $folder not in source)"; continue }
  foreach ($f in Get-ChildItem $dir -File -Filter *.mp4 | Sort-Object Name) {
    if ($selected.Count -ge $MaxClips) { break }
    $key = "$folder|$($f.BaseName)"
    if ($DuplicateOf.ContainsKey($key)) {
      Write-Host "  dup   $key  -> $($DuplicateOf[$key])"
      continue
    }
    $slug = ConvertTo-Slug $f.BaseName

    # U+00D1 / U+00F1 fold to plain 'n' once diacritics are stripped, which
    # would collide with the letter N. Detect the tilde by CODEPOINT, never by
    # the folded slug, otherwise the letter N itself gets renamed.
    $isTilde = $false
    foreach ($ch in $f.BaseName.ToCharArray()) {
      $c = [int]$ch
      if ($c -eq 0x00D1 -or $c -eq 0x00F1) { $isTilde = $true }
    }
    if ($isTilde) { $slug = 'n_tilde' }

    # Never let a later clip silently overwrite an earlier one.
    if ($used.ContainsKey($slug)) {
      $n = 2
      while ($used.ContainsKey("${slug}_$n")) { $n++ }
      Write-Host "  clash $key  -> $slug taken, using ${slug}_$n"
      $slug = "${slug}_$n"
    }
    $used[$slug] = $true

    $selected.Add([PSCustomObject]@{ Folder = $folder; Source = $f.FullName; Slug = "$slug.mp4" })
  }
  if ($selected.Count -ge $MaxClips) { break }
}

Write-Host ""
Write-Host "Compressing $($selected.Count) clips at CRF $Crf -> $OutDir"
Write-Host ""

$manifest = New-Object System.Collections.Generic.List[object]
$totalIn = 0L; $totalOut = 0L; $i = 0
foreach ($c in $selected) {
  $i++
  $dest = Join-Path $OutDir $c.Slug
  & $ffmpeg -y -loglevel error -i $c.Source `
    -vf "scale='min(960,iw)':-2" `
    -c:v libx264 -profile:v high -crf $Crf -preset medium -pix_fmt yuv420p `
    -an -movflags +faststart $dest
  if ($LASTEXITCODE -ne 0) { Write-Host "  FAIL $($c.Slug)"; continue }
  $sz = (Get-Item $dest).Length
  $src = (Get-Item $c.Source).Length
  $totalIn += $src; $totalOut += $sz
  $manifest.Add([PSCustomObject]@{
    asset    = "assets/signs/$($c.Slug)"
    folder   = $c.Folder
    source   = Split-Path $c.Source -Leaf
    bytes    = $sz
  })
  Write-Host ("  [{0,2}/{1}] {2,-24} {3,8:N0} KB  (era {4,7:N0} KB)" -f $i, $selected.Count, $c.Slug, ($sz/1KB), ($src/1KB))
}

$manifest | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $OutDir 'manifest.json') -Encoding UTF8

Write-Host ""
Write-Host ("TOTAL: {0:N0} MB  ->  {1:N0} MB   ({2:P0} reduction)" -f ($totalIn/1MB), ($totalOut/1MB), (1 - $totalOut/$totalIn))
Write-Host "Manifest: $(Join-Path $OutDir 'manifest.json')"
