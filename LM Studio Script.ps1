# Require Administrator privileges for Firewall changes
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Administrator privileges are required to modify firewall rules."
    Write-Host "Please right-click PowerShell, select 'Run as Administrator', and execute this script again."
    Pause
    exit
}

$lmStudioPath = "$env:USERPROFILE\.lmstudio"

function Show-Menu {
    Clear-Host
    Write-Host "========================================="
    Write-Host "        LM Studio Utility Script         "
    Write-Host "========================================="
    Write-Host "Description:"
    Write-Host "This script allows for LM Studio usage to be completely offline by managing"
    Write-Host "a Windows Firewall outbound rule for LM Studio. When updates to the app"
    Write-Host "or model need to be made, it force closes the app, temporarily disables the"
    Write-Host "firewall to allow for updates, and temporarily relocates chat histories to"
    Write-Host "a temp folder."
    Write-Host "========================================="
    Write-Host "1. First-Time Setup: Create Firewall Rule"
    Write-Host "2. Temporarily Clear Chat History & Disable Firewall"
    Write-Host "3. Restore Chat History & Enable Firewall (and Exit)"
    Write-Host "4. Exit"
    Write-Host "========================================="
}

do {
    Show-Menu
    $selection = Read-Host "Please select an option (1-4)"

    switch ($selection) {
        '1' {
            Write-Host "`n[+] Checking for 'LM Studio Outbound' firewall rule..." -ForegroundColor Cyan
            $existingRule = Get-NetFirewallRule -DisplayName "LM Studio Outbound" -ErrorAction SilentlyContinue
            if ($existingRule) {
                Write-Host "    -> Firewall rule already exists. Skipping creation." -ForegroundColor Yellow
            } else {
                Write-Host "    -> Creating 'LM Studio Outbound' firewall rule..." -ForegroundColor Cyan
                $lmexe = "$env:SystemDrive\Users\$env:USERNAME\AppData\Local\Programs\LM Studio\LM Studio.exe"
                New-NetFirewallRule -DisplayName "LM Studio Outbound" -Direction Outbound -Program $lmexe -Action Block -Profile Any -ErrorAction SilentlyContinue
                if ($?) { Write-Host "    -> Firewall rule created successfully." -ForegroundColor Green }
                else { Write-Host "    -> Rule could not be created." -ForegroundColor Red }
            }
            Write-Host "`nDone."
            Pause
        }
        '2' {
            Write-Host "`n[+] Ensuring LM Studio is closed..." -ForegroundColor Cyan
            Get-Process -Name "*lm studio*" -ErrorAction SilentlyContinue | Stop-Process -Force
            Start-Sleep -Seconds 2
            Write-Host "    -> Application closed (if it was running)." -ForegroundColor Green

            Write-Host "`n[+] Disabling 'LM Studio Outbound' firewall rule..." -ForegroundColor Cyan
            Disable-NetFirewallRule -DisplayName "LM Studio Outbound" -ErrorAction SilentlyContinue
            
            if ($?) { Write-Host "    -> Firewall rule disabled successfully." -ForegroundColor Green }
            else { Write-Host "    -> Rule not found or could not be changed." -ForegroundColor Yellow }

            Write-Host "`n[+] Relocating Conversations and User Files to temp..." -ForegroundColor Cyan
            $backupPath = "$env:TEMP\LMStudioBackup"
            $backupConv = Join-Path $backupPath "conversations"
            $backupFiles = Join-Path $backupPath "user-files"
            
            if (!(Test-Path $backupConv)) { New-Item -ItemType Directory -Path $backupConv -Force | Out-Null }
            if (!(Test-Path $backupFiles)) { New-Item -ItemType Directory -Path $backupFiles -Force | Out-Null }

            $convPath = Join-Path -Path $lmStudioPath -ChildPath "conversations"
            if (Test-Path $convPath) {
                Move-Item -Path "$convPath\*" -Destination $backupConv -Force -ErrorAction SilentlyContinue
            }

            $filesPath = Join-Path -Path $lmStudioPath -ChildPath "user-files"
            if (Test-Path $filesPath) {
                Move-Item -Path "$filesPath\*" -Destination $backupFiles -Force -ErrorAction SilentlyContinue
            }
            Write-Host "    -> Chat histories temporarily relocated." -ForegroundColor Green
            
            Write-Host "`n[+] Launching LM Studio for updates..." -ForegroundColor Cyan
            $lmexe = "$env:SystemDrive\Users\$env:USERNAME\AppData\Local\Programs\LM Studio\LM Studio.exe"
            if (Test-Path $lmexe) {
                Start-Process -FilePath $lmexe -RedirectStandardOutput "$env:TEMP\lmstudio_out.txt" -RedirectStandardError "$env:TEMP\lmstudio_err.txt"
            } else {
                Write-Host "    -> Executable not found. Please open LM Studio manually." -ForegroundColor Yellow
            }

            Write-Host "`n>>> Please update the app and models now." -ForegroundColor Magenta
            Write-Host ">>> Return to this script and press any key to return to menu when ready." -ForegroundColor Magenta
            Pause
        }
        '3' {
            Write-Host "`n[+] Ensuring LM Studio is closed..." -ForegroundColor Cyan
            Get-Process -Name "*lm studio*" -ErrorAction SilentlyContinue | Stop-Process -Force
            Start-Sleep -Seconds 2
            Write-Host "    -> Application closed." -ForegroundColor Green

            Write-Host "`n[+] Restoring Conversations and User Files..." -ForegroundColor Cyan
            $backupPath = "$env:TEMP\LMStudioBackup"
            $backupConv = Join-Path $backupPath "conversations"
            $backupFiles = Join-Path $backupPath "user-files"

            $convPath = Join-Path -Path $lmStudioPath -ChildPath "conversations"
            $filesPath = Join-Path -Path $lmStudioPath -ChildPath "user-files"
            
            if (!(Test-Path $convPath)) { New-Item -ItemType Directory -Path $convPath -Force | Out-Null }
            if (!(Test-Path $filesPath)) { New-Item -ItemType Directory -Path $filesPath -Force | Out-Null }

            if (Test-Path $backupConv) {
                Move-Item -Path "$backupConv\*" -Destination $convPath -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path $backupFiles) {
                Move-Item -Path "$backupFiles\*" -Destination $filesPath -Force -ErrorAction SilentlyContinue
            }
            Write-Host "    -> Chat histories restored." -ForegroundColor Green

            Write-Host "`n[+] Enabling 'LM Studio Outbound' firewall rule..." -ForegroundColor Cyan
            Enable-NetFirewallRule -DisplayName "LM Studio Outbound" -ErrorAction SilentlyContinue
            
            if ($?) { Write-Host "    -> Firewall rule enabled successfully." -ForegroundColor Green }
            else { Write-Host "    -> Rule not found or could not be changed." -ForegroundColor Yellow }
            
            Write-Host "`n[+] Relaunching LM Studio..." -ForegroundColor Cyan
            $lmexe = "$env:SystemDrive\Users\$env:USERNAME\AppData\Local\Programs\LM Studio\LM Studio.exe"
            if (Test-Path $lmexe) {
                Start-Process -FilePath $lmexe -RedirectStandardOutput "$env:TEMP\lmstudio_out.txt" -RedirectStandardError "$env:TEMP\lmstudio_err.txt"
            }

            Write-Host "`nDone. Exiting script..."
            Start-Sleep -Seconds 2
            exit
        }
        '4' {
            Write-Host "Exiting..."
            exit
        }
        default {
            Write-Host "Invalid selection. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} until ($selection -eq '4')