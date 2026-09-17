<#!
.SYNOPSIS
  Batch-scrape India white-collar portals in parallel, then merge/dedupe into
  job_scraper/seen_jobs.json. Implements /scrape Steps 1b + 4 mechanically;
  the agent continues at Step 2 (fetch & parse) and Step 3 (quick-fit).

.EXAMPLE
  pwsh -File scripts/Invoke-Scrape.ps1 -Query "data analyst" -Location "Bangalore" -JobAge 14 -Limit 20
  pwsh -File scripts/Invoke-Scrape.ps1 -Query "power bi" -Portals "hirist-search,cutshort-search"
#>
param(
  [Parameter(Mandatory = $true)][string]$Query,
  [string]$Location = "",
  [int]$JobAge = 14,
  [int]$Limit = 20,
  # Comma/semicolon/space-separated portal list (a plain string: array literals
  # do not survive `pwsh -File` argument passing from agent harnesses).
  [string]$Portals = 'hirist-search,cutshort-search,instahyre-search,iimjobs-search,protocoljobs-search,indeed-india-search',
  [int]$TimeoutSeconds = 180
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$stamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$rawDir = Join-Path $RepoRoot "job_scraper\raw\$stamp"
New-Item -ItemType Directory -Path $rawDir -Force | Out-Null

$portalList = @($Portals -split '[,;\s]+' | Where-Object { $_ -ne '' })
$jobs = foreach ($portal in $portalList) {
  $cli = Join-Path $RepoRoot ".agents\skills\$portal\cli\src\cli.ts"
  if (-not (Test-Path -LiteralPath $cli)) {
    Write-Warning "No CLI at $cli - skipping $portal (maybe detail-only like foundit-search)."
    continue
  }
  $argList = @('run', $cli, 'search', '-q', $Query, '--limit', "$Limit", '--format', 'json')
  if ($Location -ne '') { $argList += @('-l', $Location) }
  # --jobage is advisory: not every CLI supports it; failures are tolerated
  # and surfaced, never fatal (matches /scrape Step 1b rule 75).
  $probeArgs = $argList + @('--jobage', "$JobAge")
  Start-Job -Name $portal -ArgumentList @($probeArgs, $argList, $rawDir, $portal) -ScriptBlock {
    param($probeArgs, $fallbackArgs, $rawDir, $portal)
    $out = Join-Path $rawDir "$portal.json"
    $err = Join-Path $rawDir "$portal.stderr.txt"
    bun @probeArgs 1> $out 2> $err
    if ($LASTEXITCODE -ne 0) {
      # Retry once without --jobage (unsupported flag on some CLIs).
      bun @fallbackArgs 1> $out 2> $err
    }
    return @{ portal = $portal; exit = $LASTEXITCODE; out = $out }
  }
}

if (-not $jobs) { throw "No runnable portals." }
$jobs | Wait-Job -Timeout $TimeoutSeconds | Out-Null
$results = $jobs | Receive-Job
$jobs | Remove-Job -Force

$ok = @($results | Where-Object { $_.exit -eq 0 })
$failed = @($results | Where-Object { $_.exit -ne 0 })
Write-Host "Portals: $($ok.Count) ok ($($ok.portal -join ', '))" -NoNewline
if ($failed.Count -gt 0) { Write-Host "; $($failed.Count) failed ($($failed.portal -join ', ') - see $rawDir\*.stderr.txt)" }
else { Write-Host "" }

# Merge/dedupe into seen_jobs.json (additive-only; honours the tracker).
$py = $null
foreach ($c in @('py', 'python')) {
  try { & $c -c "import sys; sys.exit(0)" 2>$null; if ($LASTEXITCODE -eq 0) { $py = $c; break } } catch { }
}
if (-not $py) { throw "No working Python (tried 'py', 'python'). Raw results kept at $rawDir" }
& $py (Join-Path $RepoRoot 'tools\scrape_merge.py') --raw-dir $rawDir
if ($LASTEXITCODE -ne 0) { throw "scrape_merge.py failed; raw results kept at $rawDir" }
Write-Host "Raw results: $rawDir"
