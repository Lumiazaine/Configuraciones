# Instalar aplicaciones con winget
$apps = @(
    "Discord.Discord",
    "Brave.Brave",
    "Spotify.Spotify",
    "Microsoft.VisualStudioCode",
    "Microsoft.WindowsTerminal",
    "Valve.Steam",
    "WinSCP.WinSCP",
    "Docker.DockerDesktop",
    "Ollama.Ollama",
    "Git.Git",
    "RARLab.WinRAR",
    "qBittorrent.qBittorrent",
    "VideoLAN.VLC",
    "TeamViewer.TeamViewer"
)

Write-Host "Instalando aplicaciones con winget..." -ForegroundColor Cyan
foreach ($app in $apps) {
    Write-Host "Instalando $app..." -ForegroundColor Yellow
    winget install --id=$app -e
}

# Verificar y crear $PROFILE si no existe
if (-not (Test-Path -Path $PROFILE)) {
    Write-Host "El archivo de perfil no existe. Creando..." -ForegroundColor Cyan
    New-Item -Path $PROFILE -ItemType File -Force
} else {
    Write-Host "El archivo de perfil ya existe." -ForegroundColor Green
}

# Contenido a agregar al perfil
$profileContent = @'
# OH MY POSH
@(
    & "$env:USERPROFILE\AppData\Local\Programs\oh-my-posh\bin\oh-my-posh.exe" init pwsh --config "$env:USERPROFILE\AppData\Local\Programs\oh-my-posh\themes\zash.omp.json" --print
) -join "`n" | Invoke-Expression

# Importar módulos necesarios
Import-Module Terminal-Icons
Import-Module PSWindowsUpdate

# Configurar PSReadLine para que use el estilo de vista de predicción 'ListView'
Set-PSReadLineOption -PredictionViewStyle ListView

# Ejecutar la actualización de Windows utilizando PSWindowsUpdate
Get-WindowsUpdate -AcceptAll -AutoReboot

# Actualizar todas las aplicaciones instaladas con winget
winget upgrade --all --include-unknown

# PowerToys CommandNotFound module
Import-Module -Name Microsoft.WinGet.CommandNotFound

#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module
Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58

cls
'@

# Añadir contenido al perfil (sin sobrescribir si ya existe)
Add-Content -Path $PROFILE -Value $profileContent

Write-Host "Configuración completada. Reinicia PowerShell para aplicar los cambios." -ForegroundColor Green
