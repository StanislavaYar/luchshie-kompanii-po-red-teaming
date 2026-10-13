# Local static server for docs/ on http://localhost:4317 (no Node/Python needed)
$root = Join-Path $PSScriptRoot 'docs'
$l = New-Object System.Net.HttpListener
$l.Prefixes.Add('http://localhost:4317/')
$l.Start()
Write-Host "Serving $root at http://localhost:4317/"
$types = @{'.html'='text/html; charset=utf-8';'.css'='text/css; charset=utf-8';'.js'='text/javascript; charset=utf-8';'.svg'='image/svg+xml';'.png'='image/png';'.woff2'='font/woff2';'.xml'='application/xml; charset=utf-8';'.txt'='text/plain; charset=utf-8'}
while ($l.IsListening) {
  $ctx = $l.GetContext()
  try {
    $p = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath).TrimStart('/')
    $f = Join-Path $root $p
    if (Test-Path $f -PathType Container) {
      if (-not $ctx.Request.Url.AbsolutePath.EndsWith('/')) { $ctx.Response.Redirect($ctx.Request.Url.AbsolutePath + '/'); $ctx.Response.Close(); continue }
      $f = Join-Path $f 'index.html'
    }
    if (Test-Path $f -PathType Leaf) {
      $b = [IO.File]::ReadAllBytes($f)
      $ext = [IO.Path]::GetExtension($f).ToLower()
      $ctx.Response.ContentType = $(if ($types[$ext]) { $types[$ext] } else { 'application/octet-stream' })
      $ctx.Response.Headers.Add('Cache-Control','no-store')
      $ctx.Response.OutputStream.Write($b, 0, $b.Length)
    } else { $ctx.Response.StatusCode = 404 }
  } catch { $ctx.Response.StatusCode = 500 }
  $ctx.Response.Close()
}
