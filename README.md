# LM Studio Offline Utility Script

This PowerShell script provides a convenient way to manage LM Studio for completely offline usage by controlling a Windows Firewall outbound rule. It also handles temporary data relocation so you can safely update LM Studio and its models when necessary without exposing your private chats or files.

## Features

- **Automated Firewall Management:** Easily block or allow LM Studio's outbound network traffic.
- **First-Time Setup:** Automatically creates the necessary Windows Firewall rule to block LM Studio from accessing the internet.
- **Update Mode:** Temporarily disables the firewall rule to allow for application and model updates, while automatically relocating your local chat histories and user files to a temporary folder to keep them safe.
- **Restore Mode:** Restores your chat histories and user files, re-enables the firewall rule, and relaunches LM Studio in offline mode.

## Prerequisites

- **Windows OS** with Windows Defender Firewall.
- **LM Studio** installed at the default location (`%LocalAppData%\Programs\LM Studio\LM Studio.exe`).
- **Administrator Privileges:** The script requires administrator rights to modify Windows Firewall rules. It will prompt you if it is not run as Administrator.

## Usage

1. Right-click on PowerShell and select **"Run as Administrator"**.
2. Execute the script:
   ```powershell
   .\"LM Studio Script.ps1"
   ```
3. A menu will appear with the following options:

   - **1. First-Time Setup: Create Firewall Rule**
     Run this the very first time. It creates an outbound firewall rule named "LM Studio Outbound" that blocks the application from accessing the internet.

   - **2. Temporarily Clear Chat History & Disable Firewall**
     Use this when you need to update LM Studio or download new models. It will:
     - Force close LM Studio.
     - Disable the firewall rule (allowing internet access).
     - Move your conversations and user files to a temporary backup folder.
     - Launch LM Studio so you can perform updates.

   - **3. Restore Chat History & Enable Firewall (and Exit)**
     Use this after you have finished updating. It will:
     - Force close LM Studio.
     - Restore your conversations and user files from the temporary backup folder.
     - Re-enable the firewall rule (blocking internet access).
     - Relaunch LM Studio.
     - Exit the script.

   - **4. Exit**
     Closes the script.

## How it Works

- **Data Backup:** The script moves your `conversations` and `user-files` directories from `~/.lmstudio` to `%TEMP%\LMStudioBackup` during updates.
- **Firewall Rule:** The script targets the specific executable path (`$env:SystemDrive\Users\$env:USERNAME\AppData\Local\Programs\LM Studio\LM Studio.exe`) to block outbound connections.

## Note
Always ensure you run the script with Administrator privileges, otherwise the firewall modifications will fail.
