<#
generate-slides.ps1

Scans `assets/img/Main_Slider` (root only), parses filenames for main/sub headings
by splitting at the first '=' and builds a Bootstrap carousel section which will
replace the existing `<section id="hero-carousel">...</section>` inside
`index.html`.

Behavior (based on project requirements):
- Only root files from `assets/img/Main_Slider` are used (no subfolders).
- All common image extensions are allowed (jpg,jpeg,png,webp,avif,gif).
- Filenames are split at the first '=' into main heading (left) and subheading (right).
- Leading/trailing whitespace is trimmed from both headings.
- Ordering: if filename begins with a numeric prefix (e.g. '01-', '1 ', '001_'),
  that numeric value is used to sort slides ascending; otherwise natural filename sort.
- The script will call `scripts/generate-images.ps1` to create optimized images
  in `assets/img/optimized` (WebP/JPEG). The carousel will prefer optimized
  assets (via <picture>) and fall back to original files.

Usage:
  - From repository root run:
      .\scripts\generate-slides.ps1

This script will back up `index.html` to `index.html.bakTIMESTAMP` before editing.

#>

$ErrorActionPreference = 'Stop'

Write-Host "Generating slides from assets/img/Main_Slider..."

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = Split-Path -Parent $scriptDir
$sliderDir = Join-Path $repoRoot 'assets\img\Main_Slider'
$optimizedDir = Join-Path $repoRoot 'assets\img\optimized'
$indexFile = Join-Path $repoRoot 'index.html'
$generateScript = Join-Path $repoRoot 'scripts\generate-images.ps1'

if (-not (Test-Path $sliderDir)) {
    Write-Error "Slider directory not found: $sliderDir"
    exit 1
}
if (-not (Test-Path $indexFile)) {
    Write-Error "index.html not found at: $indexFile"
    exit 1
}

# Run image generator if present AND ImageMagick is available
if (Test-Path $generateScript) {
    # check for ImageMagick
    if (Get-Command magick -ErrorAction SilentlyContinue) {
        try {
            Write-Host "Running image optimization script: $generateScript"
            & $generateScript
        } catch {
            Write-Warning "Image generator script failed: $_. Exception: $($_.Exception.Message). Continuing."
        }
    } else {
        Write-Warning "ImageMagick not found (magick). Skipping image optimization. To enable optimized assets, install ImageMagick and re-run scripts/generate-images.ps1."
    }
} else {
    Write-Warning "Image generator script not found: $generateScript. Continuing without generating optimized images."
}

# Allowed extensions
$exts = @('.jpg', '.jpeg', '.png', '.webp', '.avif', '.gif')

# Collect files (root only)
$files = Get-ChildItem -Path $sliderDir -File | Where-Object { $exts -contains $_.Extension.ToLower() }

if (-not $files -or $files.Count -eq 0) {
    Write-Warning "No slider images found in $sliderDir"
    exit 0
}

function Get-NumericPrefix($name) {
    # match leading digits
    if ($name -match '^[\s\._-]*(\d+)(?:[\s\._-]+|[\-_.])?') { return [int]$matches[1] }
    return $null
}

[System.Collections.ArrayList]$slides = @()

foreach ($f in $files) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
    # split at first '='
    $parts = $baseName.Split('=',2)
    $main = $parts[0].Trim()
    $sub = if ($parts.Count -gt 1) { $parts[1].Trim() } else { '' }
    $numeric = Get-NumericPrefix $baseName
    $slides.Add([PSCustomObject]@{
        File = $f.FullName
        Name = $f.Name
        Base = $baseName
        Main = $main
        Sub = $sub
        Numeric = $numeric
    }) | Out-Null
}

# Sort: numeric prefix ascending (if present) then by basename
$slides = $slides | Sort-Object @{Expression={$_.Numeric -ne $null};Descending=$true}, Numeric, Base

# Build carousel HTML
$indicatorButtons = New-Object System.Text.StringBuilder
$carouselItems = New-Object System.Text.StringBuilder

$i = 0
foreach ($s in $slides) {
    # determine active class and attributes
    $activeClass = if ($i -eq 0) { 'active' } else { '' }
    $attr = if ($activeClass -ne '') { ' class="active" aria-current="true"' } else { '' }
    $indicatorLine = '            <button type="button" data-bs-target="#carouselHero" data-bs-slide-to="' + $i + '"' + $attr + ' aria-label="Slide ' + ($i+1) + '"></button>'
    $indicatorButtons.AppendLine($indicatorLine) | Out-Null

    # build picture sources (optimized path)
    $webp = Join-Path $optimizedDir ($s.Base + '.webp')
    $jpg = Join-Path $optimizedDir ($s.Base + '.jpg')
    # relative paths used in HTML
    $relWebp = "./assets/img/optimized/" + ($s.Base + '.webp')
    $relJpg = "./assets/img/optimized/" + ($s.Base + '.jpg')
    $relOrig = "./assets/img/Main_Slider/" + $s.Name

    $itemBuilder = New-Object System.Text.StringBuilder
    $itemBuilder.AppendLine('            <div class="carousel-item ' + $activeClass + '">') | Out-Null
    $itemBuilder.AppendLine('              <picture>') | Out-Null
    if (Test-Path $webp) { $itemBuilder.AppendLine('                <source srcset="' + $relWebp + '" type="image/webp">') | Out-Null }
    if (Test-Path $jpg) { $itemBuilder.AppendLine('                <source srcset="' + $relJpg + '" type="image/jpeg">') | Out-Null }
    # encode main heading for alt text
    $mainEsc = [System.Web.HttpUtility]::HtmlEncode($s.Main)
    $subEsc = [System.Web.HttpUtility]::HtmlEncode($s.Sub)
    $imgLine = '                <img src="' + $relOrig + '" class="d-block w-100" alt="' + $mainEsc + '" loading="lazy" decoding="async">'
    $itemBuilder.AppendLine($imgLine) | Out-Null
    $itemBuilder.AppendLine('              </picture>') | Out-Null

    # caption (use H2 main, p sub, two CTAs)
    $mainEsc = [System.Web.HttpUtility]::HtmlEncode($s.Main)
    $subEsc = [System.Web.HttpUtility]::HtmlEncode($s.Sub)
    $itemBuilder.AppendLine('              <div class="carousel-caption d-md-block text-start p-3" style="max-width: 640px; left: 5%; right: auto">') | Out-Null
    $itemBuilder.AppendLine('                <h2 class="display-6 fw-bold">' + $mainEsc + '</h2>') | Out-Null
    if ($s.Sub -ne '') { $itemBuilder.AppendLine('                <p class="lead">' + $subEsc + '</p>') | Out-Null }
    $waText = [System.Web.HttpUtility]::UrlEncode("Hi, I'm interested in $($s.Main)")
    # Only include WhatsApp CTA as requested
    $itemBuilder.AppendLine('                <p class="mt-3">') | Out-Null
    $itemBuilder.AppendLine('                  <a href="https://wa.me/919676003945?text=' + $waText + '" class="btn btn-outline-light btn-lg" target="_blank" rel="noopener">Book on WhatsApp</a>') | Out-Null
    $itemBuilder.AppendLine('                </p>') | Out-Null
    $itemBuilder.AppendLine('              </div>') | Out-Null
    $itemBuilder.AppendLine('            </div>') | Out-Null

    $carouselItems.Append($itemBuilder.ToString()) | Out-Null

    $i++
}

# Build full section HTML (indicators + inner + controls)
$sectionBuilder = New-Object System.Text.StringBuilder
$sectionBuilder.AppendLine('      <!-- Carousel Hero (static-friendly for GitHub Pages) -->') | Out-Null
$sectionBuilder.AppendLine('      <section id="hero-carousel" class="mb-5">') | Out-Null
$sectionBuilder.AppendLine('        <div id="carouselHero" class="carousel slide" data-bs-ride="carousel" data-bs-interval="5000" data-bs-pause="hover">') | Out-Null
$sectionBuilder.AppendLine('          <div class="carousel-indicators">') | Out-Null
$sectionBuilder.Append($indicatorButtons.ToString()) | Out-Null
$sectionBuilder.AppendLine('          </div>') | Out-Null
$sectionBuilder.AppendLine('          <div class="carousel-inner">') | Out-Null
$sectionBuilder.Append($carouselItems.ToString()) | Out-Null
$sectionBuilder.AppendLine('          </div>') | Out-Null
$sectionBuilder.AppendLine('          <button class="carousel-control-prev" type="button" data-bs-target="#carouselHero" data-bs-slide="prev">') | Out-Null
$sectionBuilder.AppendLine('            <span class="carousel-control-prev-icon" aria-hidden="true"></span>') | Out-Null
$sectionBuilder.AppendLine('            <span class="visually-hidden">Previous</span>') | Out-Null
$sectionBuilder.AppendLine('          </button>') | Out-Null
$sectionBuilder.AppendLine('          <button class="carousel-control-next" type="button" data-bs-target="#carouselHero" data-bs-slide="next">') | Out-Null
$sectionBuilder.AppendLine('            <span class="carousel-control-next-icon" aria-hidden="true"></span>') | Out-Null
$sectionBuilder.AppendLine('            <span class="visually-hidden">Next</span>') | Out-Null
$sectionBuilder.AppendLine('          </button>') | Out-Null
$sectionBuilder.AppendLine('        </div>') | Out-Null
$sectionBuilder.AppendLine('      </section>') | Out-Null

$newSection = $sectionBuilder.ToString()

# Read index.html and replace the section
$content = Get-Content -Path $indexFile -Raw -ErrorAction Stop

$startIdx = $content.IndexOf('<section id="hero-carousel"')
if ($startIdx -lt 0) {
    Write-Error "Could not find existing <section id=\"hero-carousel\"> in index.html. Aborting."
    exit 1
}

# find the end of that section (first closing </section> after start)
$after = $content.Substring($startIdx)
$endRel = $after.IndexOf('</section>')
if ($endRel -lt 0) {
    Write-Error "Could not find closing </section> for hero-carousel. Aborting."
    exit 1
}

$endIdx = $startIdx + $endRel + '</section>'.Length

# Backup
$bak = $indexFile + ".bak$(Get-Date -Format yyyyMMddHHmmss)"
Copy-Item -Path $indexFile -Destination $bak -Force
Write-Host "Backed up index.html to $bak"

# Replace
$newContent = $content.Substring(0,$startIdx) + $newSection + $content.Substring($endIdx)

Set-Content -Path $indexFile -Value $newContent -Encoding UTF8

Write-Host "index.html updated with $($slides.Count) slides."
Write-Host "Done. Commit the changes and push to GitHub Pages to publish."
