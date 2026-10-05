param([string]$OutputPath)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$build = Join-Path $root 'build\uwp'
if (!$OutputPath) { $OutputPath = Join-Path $build 'MegaManX4RecompUWP-v0.0.5-x64.zip' }
$required = @(
    'MegaManX4RecompUWP.appx',
    'Dependencies\x64\Microsoft.VCLibs.x64.14.00.appx'
)
foreach ($relativePath in $required) {
    if (!(Test-Path -LiteralPath (Join-Path $build $relativePath) -PathType Leaf)) { throw "Missing release file: $relativePath" }
}
$appxPath = Join-Path $build 'MegaManX4RecompUWP.appx'
$licenseDirectory = Join-Path $build 'licenses'
if (!(Test-Path -LiteralPath $licenseDirectory -PathType Container)) { throw 'Missing license files.' }
$signature = Get-AuthenticodeSignature -LiteralPath $appxPath
if (!$signature.SignerCertificate) {
    throw 'The APPX is not signed. Run tools/sign_uwp_package.ps1 before making a release.'
}
$stage = Join-Path $build ('.release-stage-' + [Guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path (Join-Path $stage 'Dependencies\x64') -Force | Out-Null
    foreach ($relativePath in $required) {
        Copy-Item -LiteralPath (Join-Path $build $relativePath) -Destination (Join-Path $stage $relativePath)
    }
    Copy-Item -LiteralPath $licenseDirectory -Destination (Join-Path $stage 'licenses') -Recurse
    @'
Mega Man X4 Recomp UWP

1. Open Xbox Device Portal and add MegaManX4RecompUWP.appx.
2. Add Dependencies\x64\Microsoft.VCLibs.x64.14.00.appx as a dependency if requested.
3. Launch the app and choose Internal storage or External Storage (opens E:\ when available).
4. Browse to your Mega Man X4 USA SLUS-00561 .BIN, then press PLAY MEGA MAN X4.

Keep the CUE and BIN together if your image has both. The retail game is not included in this archive.
'@ | Set-Content -LiteralPath (Join-Path $stage 'INSTALL.txt') -Encoding utf8NoBOM
    Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $OutputPath -CompressionLevel Optimal -Force
} finally {
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
}
Write-Output "Created release archive: $OutputPath"
exit 0
