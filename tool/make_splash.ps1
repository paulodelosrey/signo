# Build the branded Android launch splash at the device's native resolution.

# Why a generated PNG and not a layer-list bitmap: the only logo assets in the
# repo are 150x135 (assets/icon) and 192x192 (mipmap-xxxhdpi). Referencing either
# directly from launch_background.xml puts a ~150px mark on a 1080px-wide screen,
# which reads as a stray icon rather than a splash. Composing the full 1080x2436
# frame once, with the wordmark drawn in the app's own mint, gives a splash that
# matches the running UI instead of the stock Flutter logo.

# Colours are lifted from lib/theme.dart (KineticColors), not eyeballed:
#   background #10131A, mint #00F0A8
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$res = Join-Path $root 'signo_app\android\app\src\main\res'
$logo = Join-Path $root 'signo_app\assets\icon\signo_app_logo.png'
$outDir = Join-Path $res 'drawable-nodpi'
$out = Join-Path $outDir 'signo_splash.png'

$W = 1080; $H = 2436
$BG = [System.Drawing.Color]::FromArgb(0x10, 0x13, 0x1A)
$MINT = [System.Drawing.Color]::FromArgb(0x00, 0xF0, 0xA8)
$MINT_DIM = [System.Drawing.Color]::FromArgb(0x00, 0xA8, 0x78)

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$bmp = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'
$g.InterpolationMode = 'HighQualityBicubic'
$g.PixelOffsetMode = 'HighQuality'
$g.TextRenderingHint = 'AntiAliasGridFit'
$g.Clear($BG)

# logo: 150x135 source scaled to 300 wide, centred as a group
$src = [System.Drawing.Image]::FromFile($logo)
$lw = 300; $lh = [int]($src.Height * ($lw / $src.Width))
$gap = 64; $wordmark = 104
$groupH = $lh + $gap + $wordmark
$top = [int](($H - $groupH) / 2)
$lx = [int](($W - $lw) / 2)
$g.DrawImage($src, (New-Object System.Drawing.Rectangle $lx, $top, $lw, $lh))
$src.Dispose()

# wordmark
$font = New-Object System.Drawing.Font 'Segoe UI Semibold', 72, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
$fmt = New-Object System.Drawing.StringFormat
$fmt.Alignment = 'Center'
$fmt.LineAlignment = 'Center'
# RectangleF explicitly: PowerShell binds the PointF overload otherwise.
$rect = New-Object System.Drawing.RectangleF 0, ($top + $lh + $gap), $W, $wordmark
$brush = New-Object System.Drawing.SolidBrush $MINT
$g.DrawString('Signo', $font, $brush, $rect, $fmt)

# thin mint rule under the wordmark, echoing the app's accent use
$pen = New-Object System.Drawing.Pen $MINT_DIM, 4
$ruleY = $top + $lh + $gap + $wordmark + 26
$g.DrawLine($pen, [int](($W - 120) / 2), $ruleY, [int](($W + 120) / 2), $ruleY)

$g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
"wrote $out ($W x $H)"
