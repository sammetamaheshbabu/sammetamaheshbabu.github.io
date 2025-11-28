<#
Generate optimized images for the site using ImageMagick (magick).

Requirements:
- ImageMagick installed and `magick` available in PATH.
- Run from repository root (where this script lives).

What it does:
- Creates optimized WebP and resized PNG versions of slider images.
- Creates favicon PNGs (16x16, 32x32, 180x180) and a multi-size ICO from `TOOR_INDIA_LOGO.png`.

Usage (PowerShell):
    cd e:\project\sammetamaheshbabu.github.io
    .\scripts\generate-images.ps1

Outputs:
- assets/img/optimized/ (webp & png optimized images)
- assets/img/favicon-*.png and favicon.ico

#>

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$srcLogo = Join-Path $repoRoot 'assets\img\TOOR_INDIA_LOGO.png'
$sliderDir = Join-Path $repoRoot 'assets\img\Main_Slider'
$outDir = Join-Path $repoRoot 'assets\img\optimized'

if (-not (Get-Command magick -ErrorAction SilentlyContinue)) {
  Write-Error "ImageMagick 'magick' not found in PATH. Please install ImageMagick and ensure 'magick' is available."
  exit 1
}

if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

# Optimize slider images: create webp and a large optimized jpeg
Get-ChildItem -Path $sliderDir -File | Where-Object { $_.Extension -match '\.(jpg|jpeg|png|webp|avif)$' } | ForEach-Object {
  $file = $_.FullName
  $base = $_.BaseName
  $webpOut = Join-Path $outDir ($base + '.webp')
  $jpegOut = Join-Path $outDir ($base + '.jpg')
  Write-Host "Processing $($_.Name) -> webp + jpg"
  magick convert `"$file`" -strip -quality 75 -resize 1600x900^> `"$webpOut`"
  magick convert `"$file`" -strip -quality 80 -resize 1600x900^> `"$jpegOut`"
}

# Generate favicon PNGs and apple-touch
if (Test-Path $srcLogo) {
  Write-Host "Generating favicon PNGs and ICO from TOOR_INDIA_LOGO.png"
  $fav16 = Join-Path $repoRoot 'assets\img\favicon-16.png'
  $fav32 = Join-Path $repoRoot 'assets\img\favicon-32.png'
  $apple = Join-Path $repoRoot 'assets\img\apple-touch-icon.png'
  $icoOut = Join-Path $repoRoot 'assets\img\favicon.ico'

  magick convert `"$srcLogo`" -strip -resize 16x16 `"$fav16`"
  magick convert `"$srcLogo`" -strip -resize 32x32 `"$fav32`"
  magick convert `"$srcLogo`" -strip -resize 180x180 `"$apple`"

  # Multi-size ICO
  magick convert `"$srcLogo`" -define icon:auto-resize=64, 48, 32, 16 `"$icoOut`"

  Write-Host "Favicons written: $fav16, $fav32, $apple, $icoOut"
}
else {
  Write-Warning "Logo source not found at $srcLogo; skipping favicon generation."
}

Write-Host "Done. Optimized images are in: $outDir"

