Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass;

Write-Host "`n=== Installed Programs Larger than 100MB ==="

# Get OS Platform
$osPlatform = [System.Environment]::OSVersion.Platform

if ($osPlatform -eq [System.PlatformID]::Win32NT) {
    # Windows: Use registry to fetch installed programs
    Write-Host "Detected Windows OS. Fetching installed programs..."
    $programs = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" |
    Where-Object { $_.DisplayName -and $_.EstimatedSize } |
    Select-Object DisplayName, @{Name="Size(MB)";Expression={[math]::Round($_.EstimatedSize / 1024, 2)}} |
    Sort-Object -Property "Size(MB)" -Descending

    if ($programs) {
        $programs | Format-Table -AutoSize
    } else {
        Write-Host "No programs with size information found."
    }

} elseif ($osPlatform -eq [System.PlatformID]::MacOSX) {
    # macOS: Use system_profiler
    Write-Host "Detected macOS. Fetching installed applications..."
    $apps = system_profiler SPApplicationsDataType | Select-String "Location:" -Context 0,5 |
    ForEach-Object { $_ -replace "Location: ", "" } |
    Where-Object { $_ -and (Test-Path $_) -and (Get-Item $_).Length -gt 104857600 } | # Size > 100MB
    ForEach-Object { Get-Item $_ | Select-Object Name, @{Name="Size(MB)";Expression={[math]::Round($_.Length / 1MB, 2)}} }

    if ($apps) {
        $apps | Format-Table -AutoSize
    } else {
        Write-Host "No applications larger than 100MB found."
    }

} elseif ($osPlatform -eq [System.PlatformID]::Unix) {
    # Linux: Use dpkg-query or RPM
    Write-Host "Detected Linux OS. Fetching installed packages..."
    $packageManager = if (Get-Command dpkg-query -ErrorAction SilentlyContinue) {
        "dpkg-query"
    } elseif (Get-Command rpm -ErrorAction SilentlyContinue) {
        "rpm"
    } else {
        Write-Host "No supported package manager found (dpkg or rpm)."
        return
    }

    if ($packageManager -eq "dpkg-query") {
        $programs = dpkg-query -W --showformat='${Installed-Size} ${Package}\n' |
        ForEach-Object { $_ -split "\s+", 2 } |
        Where-Object { $_[0] -as [int] -and [int]($_[0]) -gt 102400 } | # Size > 100MB (in KB)
        ForEach-Object { [PSCustomObject]@{ Name = $_[1]; "Size(MB)" = [math]::Round($_[0] / 1024, 2) } }

    } elseif ($packageManager -eq "rpm") {
        $programs = rpm -qa --queryformat "%{SIZE} %{NAME}\n" |
        ForEach-Object { $_ -split "\s+", 2 } |
        Where-Object { $_[0] -as [int] -and [int]($_[0]) -gt 104857600 } | # Size > 100MB
        ForEach-Object { [PSCustomObject]@{ Name = $_[1]; "Size(MB)" = [math]::Round($_[0] / 1024, 2) } }
    }

    if ($programs) {
        $programs | Format-Table -AutoSize
    } else {
        Write-Host "No packages larger than 100MB found."
    }

} else {
    Write-Host "Unsupported operating system. This script supports Windows, macOS, and Linux-based systems."
}
Write-Host "Press Enter to exit..."
Read-Host
