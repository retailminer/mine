param(
  [string]$TaskName  = "TrexMiner-User",
  [string]$InstallDir = "$env:LOCALAPPDATA\trexminer",
  [switch]$VerboseOutput
)

$ErrorActionPreference = 'Stop'
if ($VerboseOutput) { $VerbosePreference = 'Continue' }

Write-Host "==> Uninstall starting…"
Write-Host "    TaskName  : $TaskName"
Write-Host "    InstallDir: $InstallDir"

# 1) Stop and remove Scheduled Task
try {
  $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
  Write-Host "==> Found scheduled task '$TaskName'. Stopping…"
  try { Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue } catch {}
  Write-Host "==> Unregistering scheduled task '$TaskName'…"
  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
} catch {
  Write-Host "==> Scheduled task '$TaskName' not found. Skipping task removal."
}

# 2) Stop any running miner processes launched from InstallDir
function Stop-IfOwnedProcess {
  param([string]$ProcName)
  try {
    $procs = Get-Process -Name $ProcName -ErrorAction SilentlyContinue
    if (-not $procs) { return }
    foreach ($p in $procs) {
      $path = $null
      try { $path = $p.Path } catch {}
      if ($path -and ($path -like "$InstallDir*")) {
        Write-Host "==> Stopping $ProcName (PID $($p.Id))"
        Stop-Process -Id $p.Id -Force -ErrorAction Stop
      }
    }
  } catch {}
}
Stop-IfOwnedProcess -ProcName "t-rex"
Stop-IfOwnedProcess -ProcName "cmd"
Stop-IfOwnedProcess -ProcName "powershell"

# 3) Delete install directory
if (Test-Path $InstallDir) {
  Write-Host "==> Removing install directory: $InstallDir"
  try {
    Get-ChildItem -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object { try { $_.IsReadOnly = $false } catch {} }
    Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction Stop
  } catch {
    Write-Warning "Could not fully remove '$InstallDir'. You may need to delete it manually."
  }
} else {
  Write-Host "==> Install directory not found. Skipping deletion."
}

Write-Host "==> Uninstall complete."
