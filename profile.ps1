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