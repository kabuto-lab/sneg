param([string]$Server = 'zomro')
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
Push-Location $repo
try {
    if ((git remote get-url origin) -ne 'https://github.com/kabuto-lab/sneg.git') {
        throw 'Unexpected origin. Expected https://github.com/kabuto-lab/sneg.git'
    }
    if (git status --porcelain) { throw 'Commit or stash local changes before deploying.' }
    git fetch origin main
    if ($LASTEXITCODE -ne 0) { throw 'Cannot fetch origin/main.' }
    $revision = (git rev-parse HEAD).Trim()
    $published = (git rev-parse origin/main).Trim()
    if ($revision -ne $published) { throw 'HEAD must match origin/main. Push or update main first.' }
    # Native PowerShell pipelines append CRLF; normalize it before Bash reads stdin.
    Get-Content -LiteralPath (Join-Path $PSScriptRoot 'deploy.sh') -Raw |
        ssh -o BatchMode=yes -o ConnectTimeout=12 -o StrictHostKeyChecking=yes $Server "tr -d '\r' | bash -s -- $revision"
    if ($LASTEXITCODE -ne 0) { throw 'Deployment failed. Inspect the output above.' }
} finally {
    Pop-Location
}
