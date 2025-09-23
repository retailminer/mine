# RetailMiner -- T-Rex User Installer

This repo provides simple **PowerShell scripts** to install and run the
[T-Rex Miner](https://github.com/trexminer/T-Rex) in **user mode** (no
admin rights needed).\
The miner runs as a **hidden background task**, restarts automatically
on crash, and re-checks every 5 minutes.

------------------------------------------------------------------------

## ⚡ Quick Start

### Install the Miner

Run this one-liner in **PowerShell (non-admin)**:

``` powershell
$batUrl="https://raw.githubusercontent.com/retailminer/mine/main/RVN-2miners.bat"
irm https://raw.githubusercontent.com/retailminer/mine/main/install-trex-user.ps1 | iex
```

-   Downloads the **latest T-Rex release** from GitHub\
-   Downloads your `.bat` file (`RVN-2miners.bat`)\
-   Installs to `%LOCALAPPDATA%\trexminer`\
-   Creates a **scheduled task** (`TrexMiner-User`) that:
    -   starts at logon
    -   checks every 5 minutes
    -   restarts on crash
    -   runs hidden

------------------------------------------------------------------------

### Uninstall the Miner

Run this one-liner in **PowerShell (non-admin)**:

``` powershell
irm https://raw.githubusercontent.com/retailminer/mine/main/uninstall-trex-user.ps1 | iex
```

-   Stops and removes the scheduled task\
-   Terminates any running miner process from the install folder\
-   Deletes `%LOCALAPPDATA%\trexminer`

------------------------------------------------------------------------

## 📂 Files in this Repo

-   **`RVN-2miners.bat`**\
    Simple batch file that runs T-Rex against your pool and wallet.

-   **`install-trex-user.ps1`**\
    Installer script: downloads T-Rex + `.bat`, sets up scheduled task.

-   **`uninstall-trex-user.ps1`**\
    Cleanup script: removes task, stops processes, deletes install dir.

-   **`README.md`**\
    Instructions (this file).

------------------------------------------------------------------------

## 🛠 Customization

-   Edit `RVN-2miners.bat` to change:
    -   Wallet address
    -   Pool URL
    -   Worker name (defaults to `%COMPUTERNAME%`)
    -   Flags (e.g. `--low-load`)
-   Update `$batUrl` in the one-liner if you rename or move your `.bat`
    file.

------------------------------------------------------------------------

## ⚠️ Disclaimer

This project is for **educational purposes only**.\
Use responsibly and in accordance with your organization's policies and
applicable law.
