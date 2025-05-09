# 🛡️ Secure Windows DNS - AdGuard Dnsproxy Installer

This script installs [AdGuard Dnsproxy](https://github.com/AdguardTeam/dnsproxy) on a Windows machine and configures it to run at startup using Task Scheduler. It uses **AdGuard’s secure DNS servers** with filtering to help block ads and enhance privacy.

## 🔧 Installation Command

To install the tool, run the following command in **PowerShell** or **Terminal** (run as administrator):

```powershell
irm https://raw.githubusercontent.com/LongQT-sea/secure-win-dns/main/Dnsproxy.ps1 | iex
```

## ✅ After Installation

Once installed, the script configures your system to use the local DNS server provided by dnsproxy:

### For IPv4:

* DNS server: `127.0.0.1`

### For IPv6:

* DNS server: `::1`

## ✅ What This Script Does

1. **Installs Winget** (if not already present).
2. **Updates Winget Sources**.
3. **Installs AdGuard.dnsproxy** via Winget.
4. **Creates a Startup Task**:

   * Uses **Task Scheduler** to launch Dnsproxy at boot.
5. **Configures Dnsproxy**:

   * Listens on `127.0.0.1` and `::1` (IPv4 & IPv6).
   * Binds to port `53` (standard DNS port).
   * Uses **AdGuard DoH/DoQ** as upstream resolvers.
   * Enables DNS caching for faster performance.

## 📋 Requirements

* **Windows 10 or later**
* **Built-in PowerShell**
* **Administrator privileges**
* **Internet connection**

## 🔄 Uninstallation

To remove Dnsproxy:

1. Open **Task Scheduler**.
2. Delete the task named: `Start Dnsproxy at startup`.
3. Go to **Settings > Apps > Installed apps**.
4. Search for `AdGuard.dnsproxy` and uninstall it.

Or use this PowerShell command:

```powershell
winget remove AdGuard.dnsproxy
```

Then reset your DNS settings with this command (run as administrator):

```powershell
$targets = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and ($_.Name -like 'Ethernet*' -or $_.Name -like 'Wi-Fi*') }

foreach ($adapter in $targets) {
    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ResetServerAddresses
    Write-Host "`nReset '$($adapter.Name)' to use the default DNS successfully."
}
```

## 📬 Feedback & Issues

Have questions or suggestions? Feel free to open an issue.

---

> ⚠️ Use at your own risk. The author is not responsible for any damage or unintended behavior caused by this script.
