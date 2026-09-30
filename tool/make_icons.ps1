# Generate the Signo launcher icons from assets/icon/signo_app_logo.png.

# Why: the shipped mipmap-*/ic_launcher.png was still the stock Flutter logo, so
# the home-screen icon -- and, on Android 12+, the system splash, which defaults
# to the app icon -- showed Flutter instead of Signo. Pointing the mipmaps at the
# real mark fixes the icon and the splash at the same time.
#
# Two outputs per density:
#   ic_launcher.png            legacy square icon (pre-Android 8 launchers)
#   ic_launcher_foreground.png adaptive foreground (mipmap-anydpi-v26)
#
# Adaptive icons crop to the centre 72/108 of the canvas, so the mark is scaled
# to 60% and centred: anything larger gets its edges shaved by the mask.

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root 'signo_app\assets\icon\signo_app_logo.png'
$res = Join-Path $root 'signo_app\android\app\src\main\res'

# Matches KineticColors.surfaceContainerLow in lib/theme.dart
$BG = [System.Drawing.Color]::FromArgb(0x19, 0x1C, 0x23)

# density -> (legacy icon px, adaptive foreground px)
$densities = @{
  'mdpi'    = @(48, 108)
  'hdpi'    = @(72, 162)
  'xhdpi'   = @(96, 216)
  'xxhdpi'  = @(144, 324)
  'xxxhdpi' = @(192, 432)
}

$logo = [System.Drawing.Image]::FromFile($src)

function New-Canvas([int]$size, [System.Drawing.Color]$bg) {
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'
  $g.InterpolationMode = 'HighQualityBicubic'
  $g.PixelOffsetMode = 'HighQuality'
  $g.Clear($bg)
  return @($bmp, $g)
}

function Draw-Centered($g, $size, [double]$fill) {
  # Fit the mark inside $fill of the canvas, preserving its aspect ratio.
  $target = $size * $fill
  $scale = [math]::Min($target / $logo.Width, $target / $logo.Height)
  $w = [int]($logo.Width * $scale)
  $h = [int]($logo.Height * $scale)
  $x = [int](($size - $w) / 2)
  $y = [int](($size - $h) / 2)
  $g.DrawImage($logo, (New-Object System.Drawing.Rectangle $x, $y, $w, $h))
}

foreach ($d in $densities.Keys) {
  $dir = Join-Path $res "mipmap-$d"
  New-Item -ItemType Directory -Force -Path $dir | Out-Null

  # legacy: the mark nearly fills the tile
  $c = New-Canvas $densities[$d][0] $BG
  Draw-Centered $c[1] $densities[$d][0] 0.92
  $c[1].Dispose()
  $c[0].Save((Join-Path $dir 'ic_launcher.png'), [System.Drawing.Imaging.ImageFormat]::Png)
  $c[0].Dispose()

  # adaptive foreground: transparent outside the mask-safe centre
  $f = New-Canvas $densities[$d][1] ([System.Drawing.Color]::Transparent)
  Draw-Centered $f[1] $densities[$d][1] 0.60
  $f[1].Dispose()
  $f[0].Save((Join-Path $dir 'ic_launcher_foreground.png'), [System.Drawing.Imaging.ImageFormat]::Png)
  $f[0].Dispose()

  "mipmap-$d  icon=$($densities[$d][0])px  foreground=$($densities[$d][1])px"
}

$logo.Dispose()

# Adaptive icon declaration, so Android 8+ uses the background/foreground pair
# instead of the legacy bitmap.
$any = Join-Path $res 'mipmap-anydpi-v26'
New-Item -ItemType Directory -Force -Path $any | Out-Null
@'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
'@ | Set-Content -Path (Join-Path $any 'ic_launcher.xml') -Encoding UTF8

$colors = Join-Path $res 'values\colors.xml'
@'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Matches KineticColors.surfaceContainerLow in lib/theme.dart -->
    <color name="ic_launcher_background">#191C23</color>
</resources>
'@ | Set-Content -Path $colors -Encoding UTF8

"wrote mipmap-anydpi-v26/ic_launcher.xml and values/colors.xml"
