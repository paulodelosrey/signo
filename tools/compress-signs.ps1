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
  - Every folder is taken, not a chosen few. The budget is a SAFETY valve for
    an unexpectedly large export, not a content decision: leaving folders out
    silently starved units that had finished recordings sitting in the Drive.

.PARAMETER Priority
  Folder names in descending priority order. A folder is taken whole until the
  clip budget is exhausted.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools/compress-signs.ps1 -MaxClips 200
#>
[CmdletBinding()]
param(
  [string]$SourceDir = (Join-Path (Split-Path $PSScriptRoot -Parent) 'LSC-project'),
  [string]$OutDir    = (Join-Path (Split-Path $PSScriptRoot -Parent) 'signo_app\assets\signs'),
  [int]   $MaxClips  = 200,
  [int]   $Crf       = 28
)

$ErrorActionPreference = 'Stop'

$ffmpeg = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
if (-not $ffmpeg) {
  $ffmpeg = (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue |
             Select-Object -First 1).FullName
}
if (-not $ffmpeg) { throw 'ffmpeg not found. Install it before running this pipeline.' }

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

# Preferred order, written WITHOUT diacritics and resolved against the real
# directory names below. PowerShell 5.1 reads a BOM-less .ps1 as ANSI, so an
# accented literal here becomes mojibake that never matches the folder on disk,
# and the folder is silently skipped. Writing them plain and resolving
# accent-insensitively makes the script immune to its own file encoding.
$PreferredOrder = @(
  'abecedario', 'frases_comunes', 'acciones', 'comida', 'calendario',
  'antonimos', 'lugar', 'tiempo', 'familia', 'negacion_afirmacion',
  'sujeto', 'calificativos', 'animales', 'colores', 'miscellaneous'
)

$allDirs = @(Get-ChildItem $SourceDir -Directory)
$Priority = New-Object System.Collections.Generic.List[string]
foreach ($want in $PreferredOrder) {
  foreach ($d in $allDirs) {
    if ((ConvertTo-Slug $d.Name) -eq $want -and -not $Priority.Contains($d.Name)) {
      $Priority.Add($d.Name)
    }
  }
}
# Any folder not in the preferred list still gets processed: silently skipping
# one is exactly the bug this ordering exists to prevent.
foreach ($d in $allDirs) { if (-not $Priority.Contains($d.Name)) { $Priority.Add($d.Name) } }

Write-Host ("Folders to process ({0}): {1}" -f $Priority.Count, ($Priority -join ', '))

# Files that are byte-level duplicates left behind by the Drive export or by
# Windows copy-conflict renaming. Verified against the vocabulary index.
#
# Both sides are compared through ConvertTo-Slug, so the keys below must be
# written the way a slug looks, not the way the file name reads. The previous
# literal 'LUGAR|aquí' could never match, because the lookup side had already
# been folded to 'lugar|aqui' - and since 'aquí' only exists in LUGAR, honouring
# that entry would have DROPPED the sign instead of de-duplicating it.
$DuplicateOf = @{
  'antonimos|bueno_1' = 'bueno'
  'antonimos|nuevo_1' = 'nuevo'
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
    $keyLookup = (ConvertTo-Slug $folder) + '|' + (ConvertTo-Slug $f.BaseName)
    if ($DuplicateOf.ContainsKey($keyLookup)) {
      Write-Host "  dup   $key  -> $($DuplicateOf[$keyLookup])"
      continue
    }
    $slug = ConvertTo-Slug $f.BaseName

    # The ABECEDARIO export contains one file whose name lost its encoding on
    # the way out of Drive: it is the letter Ñ, and once diacritics are stripped
    # its slug would collide with the letter N.
    #
    # The test must be "the WHOLE name is that one letter", NOT "the name
    # contains U+00D1/U+00F1 anywhere". The loose version also matched any word
    # with an enye - so `año`, `cumpleaños`, `baño` and `mañana` were all
    # written out as n_tilde_2..n_tilde_5, four real signs saved under a name
    # no course row could ever match.
    $isTilde = $false
    if ($f.BaseName.Length -eq 1) {
      foreach ($ch in $f.BaseName.ToCharArray()) {
        $c = [int]$ch
        if ($c -eq 0x00D1 -or $c -eq 0x00F1) { $isTilde = $true }
      }
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

# No BOM. PowerShell 5.1's `Set-Content -Encoding UTF8` prepends one, and Dart
# happens to tolerate it today, but a strict JSON reader downstream would choke
# on a file that is supposed to be plain UTF-8.
$manifestJson = $manifest | ConvertTo-Json -Depth 3
[System.IO.File]::WriteAllText(
  (Join-Path $OutDir 'manifest.json'),
  $manifestJson,
  (New-Object System.Text.UTF8Encoding($false))
)

Write-Host ""
Write-Host ("TOTAL: {0:N0} MB  ->  {1:N0} MB   ({2:P0} reduction)" -f ($totalIn/1MB), ($totalOut/1MB), (1 - $totalOut/$totalIn))
Write-Host "Manifest: $(Join-Path $OutDir 'manifest.json')"
