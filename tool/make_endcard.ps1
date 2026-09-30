# Build the closing card for the demo video.

# Why a generated frame: the end card has to carry the repo URL, the licence and
# the award category, none of which exist anywhere in the app UI. It is rendered at
# the same 1080x2436 as every device shot so the cut into it needs no scaling.
#
# The credit wording is deliberate and matches the narration: "solo student
# project ... with a certified interpreter and a Deaf collaborator". Next Gen is a
# student-only category, so this must not read as a team.

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$logo = Join-Path $root 'signo_app\assets\icon\signo_app_logo.png'
$outDir = Join-Path $root 'video-shots'
$out = Join-Path $outDir 'endcard.png'

$W = 1080; $H = 2436
# KineticColors.background and .mint from lib/theme.dart
$BG = [System.Drawing.Color]::FromArgb(0x10, 0x13, 0x1A)
$MINT = [System.Drawing.Color]::FromArgb(0x00, 0xF0, 0xA8)
$MINT_DIM = [System.Drawing.Color]::FromArgb(0x00, 0xA8, 0x78)
$TEXT = [System.Drawing.Color]::FromArgb(0xF2, 0xF4, 0xF8)
$MUTED = [System.Drawing.Color]::FromArgb(0x8B, 0x93, 0xA3)

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$bmp = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'
$g.InterpolationMode = 'HighQualityBicubic'
$g.PixelOffsetMode = 'HighQuality'
$g.TextRenderingHint = 'AntiAliasGridFit'
$g.Clear($BG)

$fmt = New-Object System.Drawing.StringFormat
$fmt.Alignment = 'Center'
$fmt.LineAlignment = 'Center'

function Draw-Centered-Text([string]$text, [int]$sizePx, $color, [int]$y, [int]$height, [string]$face = 'Segoe UI') {
  $font = New-Object System.Drawing.Font $face, $sizePx, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
  $brush = New-Object System.Drawing.SolidBrush $color
  $rect = New-Object System.Drawing.RectangleF 0, $y, $W, $height
  $g.DrawString($text, $font, $brush, $rect, $fmt)
  $font.Dispose(); $brush.Dispose()
}

function Draw-Rule([int]$y, [int]$halfWidth, $color, [int]$thickness = 3) {
  $pen = New-Object System.Drawing.Pen $color, $thickness
  $g.DrawLine($pen, [int](($W - $halfWidth) / 2), $y, [int](($W + $halfWidth) / 2), $y)
  $pen.Dispose()
}

# logo
$src = [System.Drawing.Image]::FromFile($logo)
$lw = 230; $lh = [int]($src.Height * ($lw / $src.Width))
$g.DrawImage($src, (New-Object System.Drawing.Rectangle ([int](($W - $lw) / 2)), 700, $lw, $lh))
$src.Dispose()

Draw-Centered-Text 'Signo' 132 $TEXT 990 150 'Segoe UI Semibold'
Draw-Centered-Text 'Speak with your hands.' 54 $MINT 1150 80
Draw-Rule 1300 90 $MINT_DIM

Draw-Centered-Text 'github.com/paulodelosrey/signo' 46 $TEXT 1400 70 'Segoe UI Semibold'
# U+00B7 written as a code point, not a literal: PowerShell 5.1 reads a BOM-less
# .ps1 as Windows-1252, and a literal middle dot renders as "A-circumflex-dot".
$dot = [char]0x00B7
Draw-Centered-Text "MIT License  $dot  Open Source" 40 $MUTED 1490 64

Draw-Centered-Text 'Built for RevenueCat Shipaton 2026' 38 $MUTED 1690 60
Draw-Centered-Text 'Next Gen Award' 56 $MINT 1755 84 'Segoe UI Semibold'

Draw-Rule 1940 60 ([System.Drawing.Color]::FromArgb(0x2A, 0x30, 0x3C))

# credit: the honest framing, and the answer to "how do you know this LSC is real"
Draw-Centered-Text 'A solo student project, with a certified' 34 $MUTED 2010 54
Draw-Centered-Text 'LSC interpreter and a Deaf collaborator.' 34 $MUTED 2060 54

$g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
"wrote $out ($W x $H)"
