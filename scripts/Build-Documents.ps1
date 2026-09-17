<#!
.SYNOPSIS
  Compile a tailored CV (lualatex, exactly 2 pages) and cover letter (xelatex,
  exactly 1 page), then mechanically verify the ATS text layer.
  Implements /apply Step 5a-5e in one call.

.EXAMPLE
  pwsh -File scripts/Build-Documents.ps1 -Company acme -Role "ml engineer" `
    -Email "you@example.com" -Phone "+91 98765 43210"
#>
param(
  [Parameter(Mandatory = $true)][string]$Company,
  [Parameter(Mandatory = $true)][string]$Role,
  [string]$Email = "",
  [string]$Phone = "",
  [switch]$SkipVerify
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot

function Get-Slug([string]$s) {
  ($s.ToLowerInvariant() -replace '\s+', '_' -replace '[^a-z0-9_]', '')
}

# Resolve a TeX binary, skipping bogus npm shims (e.g. a 0.0.0.0 xelatex.cmd
# that shadows the real MiKTeX/TeX Live binary) and Store shims.
function Get-TexBinary([string]$Name) {
  $cands = @(where.exe $Name 2>$null) |
    ForEach-Object { "$_".Trim() } |
    Where-Object { $_ -ne '' -and $_ -notmatch '\\npm\\' -and $_ -notmatch 'WindowsApps' -and (Test-Path -LiteralPath $_) }
  if (-not $cands -or $cands.Count -eq 0) {
    throw "No usable '$Name' found (npm/Store shims excluded). Install MiKTeX or TeX Live 2026."
  }
  Write-Host "Using ${Name}: $($cands[0])"
  return $cands[0]
}

function Get-Python() {
  foreach ($c in @('py', 'python')) {
    try {
      & $c -c "import sys; sys.exit(0)" 2>$null
      if ($LASTEXITCODE -eq 0) { Write-Host "Using python launcher: $c"; return $c }
    } catch { }
  }
  throw "No working Python found (tried 'py', 'python')."
}

function Invoke-TexBuild([string]$Exe, [string]$Dir, [string]$TexFile) {
  Push-Location -LiteralPath $Dir
  try {
    # Must compile from the file's own directory: cover.cls / OpenFonts and
    # cv \import paths are relative.
    & $Exe -interaction=nonstopmode -halt-on-error $TexFile
    if ($LASTEXITCODE -ne 0) { throw "$Exe failed on $TexFile (exit $LASTEXITCODE). See the .log file." }
  } finally {
    Pop-Location
  }
}

$slug = "$(Get-Slug $Company)_$(Get-Slug $Role)"
$cvTex = Join-Path $RepoRoot "cv\main_$slug.tex"
$coverTex = Join-Path $RepoRoot "cover_letters\cover_$slug.tex"
foreach ($f in @($cvTex, $coverTex)) {
  if (-not (Test-Path -LiteralPath $f)) { throw "Missing input: $f" }
}

$lualatex = Get-TexBinary 'lualatex'
$xelatex = Get-TexBinary 'xelatex'

Write-Host "--- CV (lualatex) ---"
Invoke-TexBuild $lualatex (Join-Path $RepoRoot 'cv') "main_$slug.tex"
Write-Host "--- Cover letter (xelatex) ---"
Invoke-TexBuild $xelatex (Join-Path $RepoRoot 'cover_letters') "cover_$slug.tex"

$cvPdf = Join-Path $RepoRoot "cv\main_$slug.pdf"
$coverPdf = Join-Path $RepoRoot "cover_letters\cover_$slug.pdf"

if (-not $SkipVerify) {
  $py = Get-Python
  $verify = Join-Path $RepoRoot 'tools\verify_pdf.py'
  Write-Host "--- ATS verify: CV (2 pages) ---"
  $cvArgs = @($verify, $cvPdf, '--pages', '2', '--min-chars', '200')
  if ($Email -ne '') { $cvArgs += @('--contains', $Email) }
  if ($Phone -ne '') { $cvArgs += @('--contains', $Phone) }
  & $py @cvArgs
  if ($LASTEXITCODE -ne 0) { throw "CV verification failed (see above)." }
  Write-Host "--- ATS verify: cover letter (1 page) ---"
  & $py $verify $coverPdf --pages 1 --min-chars 200
  if ($LASTEXITCODE -ne 0) { throw "Cover-letter verification failed (see above)." }
}

# Clean build artifacts on success only (keep .tex + .pdf).
Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'cv') -Include "main_$slug.aux", "main_$slug.log", "main_$slug.out" -ErrorAction SilentlyContinue |
  Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'cover_letters') -Include "cover_$slug.aux", "cover_$slug.log", "cover_$slug.out" -ErrorAction SilentlyContinue |
  Remove-Item -Force -ErrorAction SilentlyContinue

Write-Host "OK: $cvPdf (2pp) + $coverPdf (1pp)"
