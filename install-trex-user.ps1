param(
  [Parameter(Mandatory=$true)]
  [string]$batUrl,                                       # Raw URL to your mining .bat in YOUR GitHub repo
  [string]$InstallDir = "$env:LOCALAPPDATA\trexminer",   # Per-user, no admin needed
  [string]$TaskName  = "TrexMiner-User"
)

$ErrorActionPreference = 'Stop'

# --- Prep ---
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Set-Location $InstallDir

# --- Download latest T-Rex (Windows zip) ---
$release = Invoke-RestMethod https://api.github.com/repos/trexminer/T-Rex/releases/latest -Headers @{ "User-Agent"="PS" }
$asset = $release.assets | Where-Object { $_.name -match "win.*\.zip" } | Select-Object -First 1
$zip = Join-Path $InstallDir $asset.name
Invoke-WebRequest -UseBasicParsing $asset.browser_download_url -OutFile $zip
Expand-Archive -Force -Path $zip -DestinationPath $InstallDir

# --- Download your BAT file ---
$batPath = Join-Path $InstallDir "miner.bat"
Invoke-WebRequest -UseBasicParsing -Uri $batUrl -OutFile $batPath

# --- Copy t-rex.exe to top-level folder ---
$trexExe = Get-ChildItem -Path $InstallDir -Recurse -Filter "t-rex.exe" | Select-Object -First 1
Copy-Item $trexExe.FullName (Join-Path $InstallDir "t-rex.exe") -Force

# --- Create a runner script to launch the BAT silently ---
$runner = Join-Path $InstallDir "run-miner.ps1"
@"
Start-Process cmd.exe -ArgumentList '/c', '`"$batPath`"' -WindowStyle Hidden -WorkingDirectory "$InstallDir"
"@ | Set-Content $runner -Encoding UTF8

# --- Scheduled Task (user-mode, restart on failure) ---
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel LeastPrivilege
$triggers = @(
  New-ScheduledTaskTrigger -AtLogOn,
  New-ScheduledTaskTrigger -Once (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration ([TimeSpan]::MaxValue)
)
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$runner`""
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1)

try { Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue } catch {}
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $triggers -Settings $settings -Principal $principal

Start-ScheduledTask -TaskName $TaskName
Write-Host "==> Task '$TaskName' installed. Miner runs hidden, restarts on crash, and checks every 5 min."
