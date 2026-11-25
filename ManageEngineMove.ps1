#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Stops ManageEngine UEMS-Distribution Server, updates repository paths, and migrates existing files.
#>

$ErrorActionPreference = "Stop"

# --- Configuration Variables ---
$ServiceName   = "ManageEngine UEMS - Distribution Server" # Verify exact service name if needed
$ScriptDir     = "C:\Program Files (x86)\ManageEngine\UEMS_DistributionServer\Scripts"

$OldPatchDir   = "C:\Program Files (x86)\ManageEngine\UEMS_DistributionServer\replication\store"
$NewPatchDir   = "D:\ManageEngine\PatchStore"

$OldSwRepoDir  = "C:\Program Files (x86)\ManageEngine\UEMS_DistributionServer\replication\swrepository"
$NewSwRepoDir  = "D:\ManageEngine\SoftwareRepository"

# 1. Stop the ManageEngine UEMS-Distribution Server service
Write-Host "Checking service status for '$ServiceName'..." -ForegroundColor Cyan
$Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if (-not $Service) {
    # Fallback search in case the display name or internal name varies slightly
    $Service = Get-Service | Where-Object { $_.DisplayName -like "*ManageEngine UEMS*Distribution*" -or $_.Name -like "*ManageEngine UEMS*Distribution*" } | Select-Object -First 1
}

if ($Service) {
    if ($Service.Status -ne 'Stopped') {
        Write-Host "Stopping service: $($Service.DisplayName)..." -ForegroundColor Yellow
        Stop-Service -Name $Service.Name -Force
        $Service.WaitForStatus('Stopped', '00:02:00')
        Write-Host "Service stopped successfully." -ForegroundColor Green
    } else {
        Write-Host "Service is already stopped." -ForegroundColor Green
    }
} else {
    Write-Warning "Could not find the Distribution Server service. Please verify the exact service name before proceeding."
    exit 1
}

# 2. Build the new directories on the D drive
Write-Host "Creating new repository directories on D: drive..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $NewPatchDir -Force | Out-Null
New-Item -ItemType Directory -Path $NewSwRepoDir -Force | Out-Null
Write-Host "Directories created." -ForegroundColor Green

# 3. Change directory and run the VBScript commands sequentially
Write-Host "Changing directory to $ScriptDir..." -ForegroundColor Cyan
if (Test-Path $ScriptDir) {
    Push-Location -Path $ScriptDir
    try {
        Write-Host "Running changepath.vbs for PatchStore..." -ForegroundColor Yellow
        # Using cscript //nologo prevents popup dialog boxes that would pause automation
        & cscript.exe //nologo changepath.vbs patchstore "$NewPatchDir"
        
        Write-Host "Running changepath.vbs for SoftwareRepository..." -ForegroundColor Yellow
        & cscript.exe //nologo changepath.vbs softwarerepository "$NewSwRepoDir"
        
        Write-Host "Configuration scripts completed." -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
} else {
    Write-Error "Script directory not found: $ScriptDir"
}

# 4. Copy existing files to their new locations using Robocopy
Write-Host "Copying existing PatchStore files to $NewPatchDir..." -ForegroundColor Cyan
if (Test-Path $OldPatchDir) {
    # /E copies subdirectories (including empty ones), /Z uses restartable mode, /MT:8 uses 8 threads for speed
    robocopy "$OldPatchDir" "$NewPatchDir" /E /Z /MT:8 /R:3 /W:5 /NP
} else {
    Write-Warning "Source PatchStore directory not found: $OldPatchDir"
}

Write-Host "Copying existing SoftwareRepository files to $NewSwRepoDir..." -ForegroundColor Cyan
if (Test-Path $OldSwRepoDir) {
    robocopy "$OldSwRepoDir" "$NewSwRepoDir" /E /Z /MT:8 /R:3 /W:5 /NP
} else {
    Write-Warning "Source SoftwareRepository directory not found: $OldSwRepoDir"
}

Write-Host "Migration script finished! Please verify the data and start the service." -ForegroundColor Green
