#Requires -Version 5.1
<#
.SYNOPSIS
    discord-luau create_app bootstrap for Windows.
.DESCRIPTION
    Clones discord-luau, installs dependencies with pesde, then runs create_app.
.EXAMPLE
    .\run.ps1
    .\run.ps1 --ide=vscode C:\Projects\MyBot
#>
param(
    [Parameter(ValueFromRemainingArguments)]
    [string[]] $CreateAppArgs = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info  { param($msg) Write-Host "[discord-luau] $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "[discord-luau] $msg" -ForegroundColor Yellow }
function Write-Err   { param($msg) Write-Host "[discord-luau] error: $msg" -ForegroundColor Red }

# ---------------------------------------------------------------------------
# Dependency checks
# ---------------------------------------------------------------------------

$missing = @()

if (-not (Get-Command git   -ErrorAction SilentlyContinue)) {
    $missing += "git   — https://git-scm.com/downloads"
}
if (-not (Get-Command zune  -ErrorAction SilentlyContinue)) {
    $missing += "zune  — https://zune.sh/"
}
if (-not (Get-Command pesde -ErrorAction SilentlyContinue)) {
    $missing += "pesde — https://pesde.dev"
}

if ($missing.Count -gt 0) {
    Write-Err "The following required tools were not found in PATH:"
    $missing | ForEach-Object { Write-Host "  • $_" -ForegroundColor Red }
    exit 1
}

$zuneVersion  = (zune  --version 2>$null) -replace "`n",""
$pesdeVersion = (pesde --version 2>$null) -replace "`n",""
Write-Info "Found zune  $zuneVersion"
Write-Info "Found pesde $pesdeVersion"

# ---------------------------------------------------------------------------
# Resolve temp directory and clone
# ---------------------------------------------------------------------------

$tmpBase = if ($env:TEMP) { $env:TEMP } elseif ($env:TMPDIR) { $env:TMPDIR } else { '/tmp' }
$cloneDir = Join-Path $tmpBase "discord-luau"

if (Test-Path $cloneDir) {
    Write-Warn "Removing existing clone at $cloneDir"
    Remove-Item -Recurse -Force $cloneDir
}

Write-Info "Cloning discord-luau into $cloneDir ..."
git clone --depth=1 https://github.com/DiscordLuau/discord-luau.git "$cloneDir"
if ($LASTEXITCODE -ne 0) { Write-Err "git clone failed"; exit 1 }

# ---------------------------------------------------------------------------
# Install dependencies
# ---------------------------------------------------------------------------

Write-Info "Installing dependencies ..."
Push-Location $cloneDir
try {
    pesde install
    if ($LASTEXITCODE -ne 0) { Write-Err "pesde install failed"; exit 1 }
} finally {
    Pop-Location
}

# ---------------------------------------------------------------------------
# Default output directory to Documents if no path arg was provided
# ---------------------------------------------------------------------------

$defaultDir = [Environment]::GetFolderPath('MyDocuments')
if (-not $defaultDir) { $defaultDir = Join-Path $HOME "Documents" }

$hasPathArg = $CreateAppArgs | Where-Object { -not $_.StartsWith("-") }
if (-not $hasPathArg) {
    Write-Warn "No output directory specified — defaulting to $defaultDir"
    $CreateAppArgs += $defaultDir
}

# ---------------------------------------------------------------------------
# Run create_app
# ---------------------------------------------------------------------------

Write-Info "Running create_app ..."
Push-Location $cloneDir
try {
    zune run packages/create_app/src create @CreateAppArgs
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}
