#This code will connect to Vsphere and generate VM's using the Domotz template.

# Step 1.  Connect to Vcenter.
$vCenter = Read-Host "Enter vcenter ip"
Connect-VIServer -Server $vCenter

# Step 2.  Prompt for VM Name, Host, and Datastore
$VMName        = Read-Host "Enter name for VM"
$VMHostName    = Read-Host "Enter the target esxi host"
$DatastoreName = Read-Host "Enter target datastore name"

# step 3. Select content library
$LocalLibrary = Get-ContentLibrary |
                Where-Object { $_.Type -eq "Subscribed" } |
                Sort-Object Name |
                Out-GridView -Title "Select the Content Library" -PassThru
                
# Step 4. Feth the Template and Deploy
$TemplateName = "DOMOTZ-TEMPLATE"
$TemplateItem = Get-contentLibraryItem -Name $TemplateName -ContentLibrary $LocalLibrary
$VMHost       = Get-VMHost -Name $VMHostName
$Datastore    = Get-Datastore -Name $DatastoreName

New-VM -Name $VMName `
       -ContentLibraryItem $TemplateItem `
       -VMHost $VMHost `
       -Datastore $Datastore `
       -DiskStorageFormat Thin `
       -RunAsync
	   
Write-Host "Started deployment of '$VMName'! (Task ID: $($Task.Id))"

# Step 6 Ask if we are creating another VM
$CreateAnother = Read-Host "would you like to build another vm? (y/n)"

} while ($CreateAnother -eq 'Y' -or $CreateAnother -eq 'y')

# step 7 disconnect Vcenter
disconnect-VIServer -Server $vCenter -Confirm:$false
Write-Host "All tasks submitted.  Check recent tasks on vcenter to monitor.  Disconnected from VCenter."


