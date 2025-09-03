# T-Rex RVN Miner

## Install
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; `
$url="https://raw.githubusercontent.com/retailminer/mine/main/install-trex-user.ps1"; `
$installer="$env:TEMP\install-trex-user.ps1"; `
Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing; `
powershell -NoProfile -ExecutionPolicy Bypass -File $installer
`````````

## Remove
```powershell
Stop-Process -Name t-rex -Force -ErrorAction SilentlyContinue; `
Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\T-Rex Miner (auto-update).lnk" -Force -ErrorAction SilentlyContinue; `
Remove-Item "$env:USERPROFILE\trex" -Recurse -Force -ErrorAction SilentlyContinue
`````````
