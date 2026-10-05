$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$upstream = Join-Path $root 'upstream'
$upstreamCommit = '51f5f446a37f7e32d7bce6b9134865ee36b9c4ad'

if (!(Test-Path -LiteralPath (Join-Path $upstream '.git'))) {
    git clone --no-checkout https://github.com/mstan/MegaManX4Recomp.git $upstream
    if ($LASTEXITCODE -ne 0) { throw 'Could not clone MegaManX4Recomp.' }
    git -C $upstream checkout --detach $upstreamCommit
    if ($LASTEXITCODE -ne 0) { throw "Could not check out pinned upstream commit $upstreamCommit." }
} else {
    $actualCommit = (git -C $upstream rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or $actualCommit -ne $upstreamCommit) {
        throw "Existing upstream checkout is not at pinned commit $upstreamCommit."
    }
}

git -C $upstream submodule update --init --recursive
if ($LASTEXITCODE -ne 0) { throw 'Could not initialize upstream submodules.' }

function Apply-TrackedPatch([string]$Repository, [string]$Patch) {
    git -C $Repository apply --unidiff-zero --check $Patch 2>$null
    if ($LASTEXITCODE -eq 0) {
        git -C $Repository apply --unidiff-zero $Patch
        if ($LASTEXITCODE -ne 0) { throw "Could not apply $Patch" }
        return
    }
    git -C $Repository apply --unidiff-zero --reverse --check $Patch 2>$null
    if ($LASTEXITCODE -ne 0) { throw "Patch does not apply cleanly: $Patch" }
}

Apply-TrackedPatch $upstream (Join-Path $root 'patches\mmx4-uwp.patch')
Apply-TrackedPatch (Join-Path $upstream 'psxrecomp-v4') (Join-Path $root 'patches\psxrecomp-uwp.patch')
Write-Output 'Pinned upstream source and UWP patches are ready.'
