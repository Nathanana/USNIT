Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass;

Write-Host "=== Computer Specifications ==="

# Get OS Platform
$osPlatform = [System.Environment]::OSVersion.Platform

if ($osPlatform -eq [System.PlatformID]::Win32NT) {
    # Windows: Use systeminfo to get computer specs
    Write-Host "Detected Windows OS. Fetching system information..."
    systeminfo | Findstr /R "OS Name OS Version Total Physical Memory Available Physical Memory System Type"

} elseif ($osPlatform -eq [System.PlatformID]::MacOSX) {
    # macOS: Use system_profiler to get computer specs
    Write-Host "Detected macOS. Fetching system information..."
    system_profiler SPSoftwareDataType | Select-String "System Version" 
    system_profiler SPHardwareDataType | Select-String "Memory" 
    system_profiler SPHardwareDataType | Select-String "System Type"

} elseif ($osPlatform -eq [System.PlatformID]::Unix) {
    # Linux: Use lshw or free/uptime to get computer specs (for Debian-based systems)
    Write-Host "Detected Linux OS. Fetching system information..."
    
    # Check if lshw is available
    if (Get-Command lshw -ErrorAction SilentlyContinue) {
        lshw -short | Select-String "memory"
    }
    else {
        # Fallback to free and uptime
        free -h | Select-String "Mem"
        uname -a | Select-String "Linux"
    }
} else {
    Write-Host "Unsupported operating system detected. This script supports Windows, macOS, and Linux-based systems."
}

Write-Host "Press Enter to exit..."
Read-Host