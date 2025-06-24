# Requires running as Administrator

# Paths
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$WallpaperSrc = Join-Path $ScriptRoot 'wallpaper'
$RegFile     = Join-Path $ScriptRoot 'fotos.reg'
$ProfileSrc  = Join-Path $ScriptRoot 'profile.ps1'
$Installer   = Join-Path $ScriptRoot 'installer.ps1'

Write-Host '=== Iniciando configuración del equipo ==='

# 1. Cambiar wallpaper
function Set-Wallpaper {
    param($Path)
    if (-Not (Test-Path $Path)) { throw "Wallpaper no encontrado: $Path" }

    Add-Type @"
    using System.Runtime.InteropServices;
    public class Native {
        [DllImport("user32.dll",SetLastError=true)]
        public static extern bool SystemParametersInfo(int action, int uParam, string lpvParam, int flags);
    }
    "@

    # SPI_SETDESKWALLPAPER = 20, SPIF_UPDATEINIFILE = 1, SPIF_SENDCHANGE = 2
    [Native]::SystemParametersInfo(20, 0, $Path, 1 -bor 2) | Out-Null
    Write-Host "Wallpaper aplicado: $Path"
}
Set-Wallpaper -Path $WallpaperSrc

# 2. Importar registro de fotos
if (Test-Path $RegFile) {
    reg import $RegFile | Out-Null
    Write-Host "Registro importado: $RegFile"
} else { Write-Warning "No existe el archivo de registro: $RegFile" }

# 3. Crear o actualizar Profile
$ProfileDestDir = Join-Path $HOME 'Documents\PowerShell'
if (-Not (Test-Path $ProfileDestDir)) { New-Item -Path $ProfileDestDir -ItemType Directory -Force | Out-Null }
$ProfileDest = Join-Path $ProfileDestDir 'Profile.ps1'
Copy-Item -Path $ProfileSrc -Destination $ProfileDest -Force
Write-Host "Profile copiado a: $ProfileDest"

# 4. Ejecutar installer.ps1
if (Test-Path $Installer) {
    Write-Host 'Ejecutando installer.ps1...'
    & $Installer
    Write-Host 'Instalación completada.'
} else { Write-Warning 'No existe installer.ps1' }

# 5. Desactivar sonidos de Windows
Write-Host 'Desactivando sonidos de Windows...'
Get-ChildItem 'HKCU:\AppEvents\Schemes\Apps\.Default' -ErrorAction SilentlyContinue | ForEach-Object {
    $cur = Join-Path $_.PSPath '.Current'
    if (Test-Path $cur) {
        New-ItemProperty -Path $cur -Name '(Default)' -Value '' -PropertyType ExpandString -Force | Out-Null
    }
}
Write-Host 'Sonidos desactivados.'

# 6. Ajustar orientación y frecuencia de refresco
Add-Type @"
using System;
using System.Runtime.InteropServices;
[StructLayout(LayoutKind.Sequential)]
public struct DEVMODE {
    private const int CCHDEVICENAME = 32;
    private const int CCHFORMNAME = 32;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = CCHDEVICENAME)] public string dmDeviceName;
    public short dmSpecVersion;
    public short dmDriverVersion;
    public short dmSize;
    public short dmDriverExtra;
    public int dmFields;
    public int dmPositionX;
    public int dmPositionY;
    public int dmDisplayOrientation;
    public int dmDisplayFixedOutput;
    public short dmColor;
    public short dmDuplex;
    public short dmYResolution;
    public short dmTTOption;
    public short dmCollate;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = CCHFORMNAME)] public string dmFormName;
    public short dmLogPixels;
    public int dmBitsPerPel;
    public int dmPelsWidth;
    public int dmPelsHeight;
    public int dmDisplayFlags;
    public int dmDisplayFrequency;
    public int dmICMMethod;
    public int dmICMIntent;
    public int dmMediaType;
    public int dmDitherType;
    public int dmReserved1;
    public int dmReserved2;
    public int dmPanningWidth;
    public int dmPanningHeight;
}
public class DispApi {
    [DllImport("user32.dll")] public static extern bool EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);
    [DllImport("user32.dll")] public static extern int ChangeDisplaySettingsEx(string deviceName, ref DEVMODE devMode, IntPtr hwnd, int flags, IntPtr lParam);
}
"@

function Set-DisplayConfig {
    param(
        [string]$Device = $null,
        [int]$Orientation = 2,  # DMDO_180 (Landscape flipped)
        [int]$Freq = 100        # 100 Hz
    )
    $dm = New-Object DEVMODE
    $dm.dmSize = [Runtime.InteropServices.Marshal]::SizeOf($dm)
    if (-not [DispApi]::EnumDisplaySettings($Device, -1, [ref]$dm)) {
        Write-Warning "No se pudo obtener config para: $Device"
        return
    }
    # Modificar
    $dm.dmDisplayOrientation = $Orientation
    $dm.dmDisplayFrequency = $Freq
    # Aplicar: CDS_UPDATEREGISTRY (1)
    $res = [DispApi]::ChangeDisplaySettingsEx($Device, [ref]$dm, [IntPtr]::Zero, 1, [IntPtr]::Zero)
    if ($res -eq 0) { Write-Host "Pantalla $($Device ?? 'DEFAULT') ajustada: Orientación=$Orientation, Frec=$Freq Hz" }
    else { Write-Warning "Error ajustando pantalla $($Device ?? 'DEFAULT'): Código $res" }
}

# Enumerar dispositivos
$idx = 0
while ($true) {
    try {
        # Con null iteramos todas
        Set-DisplayConfig
        break
    } catch {
        break
    }
}

Write-Host 'Orientación y frecuencia establecidas.'

# 7. Instalar y habilitar servidor SSH
Write-Host 'Instalando y habilitando OpenSSH Server...'
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction SilentlyContinue | Out-Null
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
Write-Host 'Servidor SSH activado y configurado para iniciar automáticamente.'

# 8. Habilitar Escritorio Remoto
Write-Host 'Habilitando Escritorio Remoto...'
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0
Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'
Write-Host 'Escritorio Remoto habilitado y reglas de firewall activadas.'

Write-Host '=== Configuración completada ==='