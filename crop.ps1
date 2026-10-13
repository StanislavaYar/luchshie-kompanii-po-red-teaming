# Usage: powershell -File crop.ps1 <png> <segmentHeight>  -> writes <png>-partN.png
param([string]$src, [int]$seg = 1200)
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile($src)
$n = [math]::Ceiling($img.Height / $seg)
for ($i = 0; $i -lt $n; $i++) {
  $h = [math]::Min($seg, $img.Height - $i*$seg)
  $bmp = New-Object System.Drawing.Bitmap $img.Width, $h
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.DrawImage($img, (New-Object System.Drawing.Rectangle 0,0,$img.Width,$h), (New-Object System.Drawing.Rectangle 0,($i*$seg),$img.Width,$h), [System.Drawing.GraphicsUnit]::Pixel)
  $bmp.Save(($src -replace '\.png$', "-part$($i+1).png"), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
}
$img.Dispose(); Write-Host "$n parts"
