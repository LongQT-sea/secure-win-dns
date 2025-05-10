# A simple powershell script used to install Adguard Dnsproxy and add it to startup with Task Scheduled
# Author: github.com/longqt-sea
$ErrorActionPreference = "SilentlyContinue"

# Check if the script is running with administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Exit if not running as administrator
if (-not ($isAdmin)) {
    Write-Warning "Administrator privileges required. Please run the script with administrator."
    Write-Host "`nPress Enter to exit." -NoNewline
    $null = Read-Host
    exit 1
}

function Install-dnsproxy {
    if (gcm dnsproxy) {
        Write-Host "`nDnsproxy is already installed, skip installing"
        return $true
    }

    # Check if winget is available
    while (-not (gcm winget)) {
        Write-Host "`nThe 'winget' command is unavailable. Please update 'App Installer' through Microsoft Store and then press Enter to continue."
        Write-Host "`nMicrosoft Store will open automatically in 5 seconds." -NoNewline
        sleep 5
        Start-Process "ms-windows-store://pdp?hl=en-us&gl=us&productid=9nblggh4nns1"
        $null = Read-Host
    }

    # Update winget sources
    Write-Host "Updating winget sources..."
    winget source update --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        Write-Host -b black -f yellow "`nFailed to update Winget sources!"
        return $false
    }

    # Install AdGuard.dnsproxy
    Write-Host "`nInstalling AdGuard.dnsproxy using Winget..."
    winget install --id=AdGuard.dnsproxy --accept-package-agreements --accept-source-agreements --disable-interactivity --scope user

    if ($LASTEXITCODE -ne 0) {
        Write-Host "`nFailed to install dnsproxy!"
        return $false
    } else {
        Write-Host "`nDnsproxy was installed successfully!"
        return $true
    }
}

function Add-ScheduledTask {
    $name = "Start Dnsproxy at startup"
    if (Get-ScheduledTask -TaskName $name) {
        Write-Host "`nA Scheduled Task name $name already exist, skipping"
        return $true
    }

    Write-Host "`nAdding dnsproxy to startup with Scheduled Task"
    $dnsproxyPath = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "dnsproxy.exe" | Select-Object -First 1 -ExpandProperty FullName
    if (-not $dnsproxyPath) {
        Write-Host "`nFailed to locate dnsproxy.exe."
        return $false
    }

    # Use Adguard DNS to block ads
    $dnsArgs = @(
        "-l 127.0.0.1 -l ::1"
        "-p 53"
        "-b 8.8.8.8 -b 2606:4700:4700::1111"
        "-f 9.9.9.9 -f 2620:fe::9"
        "-u [/www.googleadservices.com/]8.8.8.8"
        "-u [/ad.doubleclick.net/]8.8.8.8"
        "-u https://dns.adguard.com/dns-query"
        "-u quic://dns.adguard-dns.com"
        "-r 200 --cache --cache-optimistic --cache-size 2097152"
    ) -join " "

    $trigger = New-ScheduledTaskTrigger -AtStartup
    $user = "NT AUTHORITY\SYSTEM"
    $action = New-ScheduledTaskAction -Execute "$dnsproxyPath" -Argument "$dnsArgs"
    $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $name -Trigger $trigger -User $user -Action $action -Settings $settings
    Start-ScheduledTask $name

    if ($LASTEXITCODE -ne 0) {
        Write-Host "`nScheduled Task added, but failed to start. Check if another DNS server is already running on localhost."
        return $false
    } else {
        Write-Host "`nScheduled Task added and started successfully!"
        return $true
    }
}

if (Install-dnsproxy) {
    if (Add-ScheduledTask) {
        $targets = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and ($_.Name -like 'Ethernet*' -or $_.Name -like 'Wi-Fi*') }
        foreach ($adapter in $targets) {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses @("127.0.0.1", "::1")
            Write-Host "`nSet DNS for '$($adapter.Name)' to use dnsproxy at localhost successfully."
        }
    }
}

Write-Host -b black -f green "`nOperation completed. Press Enter to exit." -NoNewLine
$Host.UI.RawUI.FlushInputBuffer()
$null = Read-Host
exit