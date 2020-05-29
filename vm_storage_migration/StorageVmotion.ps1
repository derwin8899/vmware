<####################################################################################### 
ScriptName:                      StorageVmotion.ps1 
Description:                     Executes storage vmotion from list of servers in csv file. 
				 csv file needs 2 columns: 1. vmname (Name) 2. Target datastore (NewDatastore)
Author:                          Damien Erwin 
Date Created:                    1/5/2014
Reveiwer:                        
Usage :                          StorageVmotion_v1.ps1 -vcenter <server> -csvfile <path to .csv file>
Example:                         StorageVmotion_v1.ps1 -vcenter iovcprdv005 -csvfile C:\server_list.csv 
Requirements:                    Script must be run in powercli session with user permissions to vcenter server
########################################################################################>

# Obtain vcenter and csvfile from user
PARAM($Vcenter,$csvfile)

# Disconnect any open connections to vcenters before starting
Write-Host "Disconnecting any  Vcenter connections already open before starting..."
$ErrorActionpreference = 'SilentlyContinue'
Disconnect-VIServer -Server * -Force -Confirm:$false  | Out-Null


$ErrorActionpreference = 'Inquire'
# Validate that Vcenter and cluster specified by user
if (($Vcenter -eq $null) -or ($csvfile -eq $null))
{
Write-Host "Error" -foreground Red
write-host "Vcenter server and cluster must be specified. Example: StorageVmotion.ps1  -vcenter <server> -csvfile <file name>"
Exit
}
else
{
Connect-VIServer $vcenter -ErrorAction stop | out-null
Test-Path $csvfile -ErrorAction Stop | Out-Null
}


$ErrorActionpreference = 'continue'
# Read csv file and run command to move VMs
Write-host "Attempting to move VMs. Monitor progress in Vcenter client." -ForegroundColor Yellow
Import-Csv $csvfile | Foreach {
    Get-VM $_.Name | Move-VM -DiskStorageFormat Thick -Datastore $_.NewDatastore -RunAsync | out-null
write-host ($_.Name + " to " + $_.NewDatastore)
}


Write-Host "Completed commands. Check Vcenter for any warnings or errors. " -ForegroundColor Yellow

# Disconnect from vcneter server
Disconnect-VIServer -Server * -Force -Confirm:$false