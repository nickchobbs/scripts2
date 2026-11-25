Write-Output "Starting WinSxS component Cleanup"
DISM.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase

if ($LASTEXITCODE -eq 0) {
    Write-Output "Cleanup Successful"
} elseif ($LASTEXITCODE -eq 3010) {
   Write-Output "Cleanup completed, reboot required." 
} else {
  Write-out "DISM Failed with exit code: $LASTEXITCODE"
}