# ================================
# 🛠️ Script de configuración para sistema limpio
# ================================

# Verificamos si Winget está disponible
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Winget no está disponible. Abre Microsoft Store al menos una vez e intenta nuevamente." -ForegroundColor Red
    exit
}

# ✅ Instalar Oh My Posh primero
Write-Host "`n🎨 Instalando Oh My Posh..."
winget install JanDeDobbeleer.OhMyPosh -s winget --accept-package-agreements --accept-source-agreements --silent

# ✅ Crear el archivo de perfil de PowerShell
if (!(Test-Path -Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    Write-Host "📄 Archivo de perfil creado: $PROFILE"
}

# ✅ Agregar configuración de Oh My Posh al perfil
$ohMyPoshBlock = @'
@(
    & "$env:USERPROFILE\AppData\Local\Programs\oh-my-posh\bin\oh-my-posh.exe" init pwsh --config "$env:USERPROFILE\AppData\Local\Programs\oh-my-posh\themes\zash.omp.json" --print
) -join "`n" | Invoke-Expression
'@

if (-not (Get-Content $PROFILE | Select-String 'oh-my-posh')) {
    Add-Content -Path $PROFILE -Value "`n$ohMyPoshBlock"
    Write-Host "✅ Configuración de Oh My Posh añadida al perfil."
} else {
    Write-Host "ℹ️ Configuración de Oh My Posh ya existe en el perfil. Saltando."
}

# ✅ Lista de aplicaciones a instalar
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
    "VideoLAN.VLC"
)

foreach ($app in $apps) {
    Write-Host "📦 Instalando $app..."
    Start-Process "winget" -ArgumentList "install --id=$app -e --accept-package-agreements --accept-source-agreements --silent" -Wait
}

Write-Host "`n✅ Todo listo. Reinicia PowerShell o abre una nueva terminal para ver los cambios." -ForegroundColor Green
