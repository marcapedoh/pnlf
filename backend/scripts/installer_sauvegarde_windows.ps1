# Installe la tâche planifiée Windows « PFNL - Sauvegarde production » (2 fois par jour).
# Usage (PowerShell, depuis backend/) :
#   powershell -ExecutionPolicy Bypass -File scripts\installer_sauvegarde_windows.ps1
#   powershell -ExecutionPolicy Bypass -File scripts\installer_sauvegarde_windows.ps1 -Heures 8,20
#   powershell -ExecutionPolicy Bypass -File scripts\installer_sauvegarde_windows.ps1 -Desinstaller
param(
    [int[]]$Heures = @(9, 21),
    [switch]$Desinstaller
)

$ErrorActionPreference = 'Stop'
$NomTache = 'PFNL - Sauvegarde production'

if ($Desinstaller) {
    Unregister-ScheduledTask -TaskName $NomTache -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "Tache '$NomTache' supprimee."
    exit 0
}

$Backend = Split-Path -Parent $PSScriptRoot
$Script = Join-Path $PSScriptRoot 'sauvegarde_prod.py'
$Python = (Get-Command python -ErrorAction Stop).Source
$PythonSansConsole = Join-Path (Split-Path -Parent $Python) 'pythonw.exe'
if (Test-Path $PythonSansConsole) { $Python = $PythonSansConsole }

$Action = New-ScheduledTaskAction -Execute $Python -Argument "`"$Script`"" -WorkingDirectory $Backend
$Declencheurs = $Heures | ForEach-Object { New-ScheduledTaskTrigger -Daily -At ([datetime]::Today.AddHours($_)) }
# StartWhenAvailable : une exécution manquée (PC éteint) est rattrapée dès le prochain démarrage.
$Parametres = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2) -MultipleInstances IgnoreNew -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 15)
$Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

Register-ScheduledTask -TaskName $NomTache -Action $Action -Trigger $Declencheurs -Settings $Parametres `
    -Principal $Principal -Description 'Copie la base Render et les medias R2 de la plateforme PFNL vers ce poste.' -Force | Out-Null

$Info = Get-ScheduledTaskInfo -TaskName $NomTache
Write-Host "Tache '$NomTache' installee : tous les jours a $($Heures -join 'h, ')h."
Write-Host "Prochaine execution : $($Info.NextRunTime)"
Write-Host "Journal : <projet>\sauvegardes\journal.log"
