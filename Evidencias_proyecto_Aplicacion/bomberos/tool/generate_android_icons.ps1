# Genera iconos Android desde assets/icon/app_icon.png
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path $PSScriptRoot -Parent
$srcPath = Join-Path $root "assets\icon\app_icon.png"
$resRoot = Join-Path $root "android\app\src\main\res"

if (-not (Test-Path $srcPath)) {
    throw "No se encuentra $srcPath"
}

function Resize-Png {
    param(
        [string]$Source,
        [string]$Dest,
        [int]$Size
    )
    $dir = Split-Path $Dest -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $src = [System.Drawing.Image]::FromFile($Source)
    try {
        $bmp = New-Object System.Drawing.Bitmap $Size, $Size
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        try {
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $g.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
            $g.DrawImage($src, 0, 0, $Size, $Size)
        } finally { $g.Dispose() }
        $bmp.Save($Dest, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $src.Dispose()
        if ($bmp) { $bmp.Dispose() }
    }
}

$legacy = @{
    "mipmap-mdpi"    = 48
    "mipmap-hdpi"    = 72
    "mipmap-xhdpi"   = 96
    "mipmap-xxhdpi"  = 144
    "mipmap-xxxhdpi" = 192
}
$foreground = @{
    "drawable-mdpi"    = 108
    "drawable-hdpi"    = 162
    "drawable-xhdpi"   = 216
    "drawable-xxhdpi"  = 324
    "drawable-xxxhdpi" = 432
}

foreach ($entry in $legacy.GetEnumerator()) {
    $out = Join-Path $resRoot "$($entry.Key)\ic_launcher.png"
    Resize-Png -Source $srcPath -Dest $out -Size $entry.Value
}

foreach ($entry in $foreground.GetEnumerator()) {
    $out = Join-Path $resRoot "$($entry.Key)\ic_launcher_foreground.png"
    Resize-Png -Source $srcPath -Dest $out -Size $entry.Value
}

$anydpi = Join-Path $resRoot "mipmap-anydpi-v26"
New-Item -ItemType Directory -Path $anydpi -Force | Out-Null
@'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
'@ | Set-Content -Path (Join-Path $anydpi "ic_launcher.xml") -Encoding UTF8

$values = Join-Path $resRoot "values"
New-Item -ItemType Directory -Path $values -Force | Out-Null
$colorsPath = Join-Path $values "colors.xml"
@'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#00000000</color>
</resources>
'@ | Set-Content -Path $colorsPath -Encoding UTF8

Write-Host "Iconos Android generados en $resRoot"
