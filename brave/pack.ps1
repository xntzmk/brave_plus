#Requires -Version 7.0
param(
  [string]$Version = '1.18.3-brave.1',
  [switch]$SkipBuild
)
$ErrorActionPreference = 'Stop'

$repo = Split-Path $PSScriptRoot -Parent
if (-not $SkipBuild) {
  Push-Location $repo
  try { & .\build.cmd vs x64 release; if ($LASTEXITCODE -ne 0) { throw 'build failed' } }
  finally { Pop-Location }
}

$dll = Join-Path $repo 'out\x64\release\version.dll'
foreach ($f in @($dll, (Join-Path $PSScriptRoot 'chrome++.ini'))) {
  if (-not (Test-Path $f)) { throw "missing: $f" }
}

$stage = Join-Path $env:TEMP "braveplus-$Version"
Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $stage | Out-Null

Copy-Item $dll $stage
Copy-Item (Join-Path $PSScriptRoot 'chrome++.ini')   $stage
Copy-Item (Join-Path $PSScriptRoot 'install.bat')    $stage
Copy-Item (Join-Path $PSScriptRoot 'uninstall.bat')  $stage
Copy-Item (Join-Path $repo 'README.brave.md')        $stage -ErrorAction SilentlyContinue

$dist = Join-Path $repo "out\dist"
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$zip = Join-Path $dist "BravePlus_${Version}_x64.zip"
Remove-Item $zip -ErrorAction SilentlyContinue
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -CompressionLevel Optimal

$hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
"$hash  $(Split-Path $zip -Leaf)" | Out-File (Join-Path $dist 'SHA256.txt') -Encoding ascii
Remove-Item $stage -Recurse -Force

Write-Host "zip    : $zip"
Write-Host "sha256 : $hash"