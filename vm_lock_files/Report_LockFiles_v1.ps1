<####################################################################################### 
ScriptName: Report_LockFiles_v1.ps1
Description: Goes through all datastores in a vcenter, finds ctk.vmdk and -ctk.vmdk.lck files and reports them to log file
The output file can then be reviewed and provided as input for the RemoveLockFiles.ps1 script
Author: DJE 
Date Created: 11/21/2015 
Usage : .\Report_LockFiles_v1.ps1 -vcenter <vcenter name>
########################################################################################> 
param([string]$vcenter)

### Disconnect any open connections to vcenters before starting
Write-Host "Disconnecting any  Vcenter connections already open before starting..."
$ErrorActionpreference = 'SilentlyContinue'
Disconnect-VIServer -Server * -Force -Confirm:$false | Out-Null 

### Validate that Vcenter is specified
$ErrorActionpreference = 'Inquire'
if (($vcenter -eq $null)) {
  Write-Host "Error. Check vcenter name" -foreground Red
  write-host "Vcenter server must be specified. Example: .\Report_LockFiles_v1.ps1 -vcenter PHservername.PHdomain.com"
  Exit
}
else {
  Connect-VIServer $vcenter -ErrorAction stop | out-null
}
$ErrorActionpreference = 'Continue'

### Connect to virtual center server
Connect-viserver $vcenter 

### Check if log file exists. If not, create it. Use "add-content" to update log file
$logfile1 = ".\Report_LockFiles.log"
$tlf = Test-Path -Path $logfile1
If ($tlf -eq $true) {
  add-content $logfile1 $day
} 
else {
  New-Item -type file $logfile1
}

### Function to check if temp_dir exists if needed. If not, create it. 
function temp_dir_check() {
  if (!(test-path -path "vmstore:\$dc\$ds\temp_dir")) {
    new-item -itemtype directory -path "vmstore:\$dc\$ds\temp_dir\files" | Out-Null
  }
  else {

  }
}

### Get list of datacenters and datastores
$dcs = get-datacenter | % { $_.name }
foreach ($dc in $dcs) {
  $dslist = dir -path vmstore:\$dc | % { $_.name }
  Write-Host ("Datastores found on " + $dc)
  $dslist 

  ### Loop through each datastore, its folders, and search for -ctk.vmdk.lck & ctk.vmdk folders and files
  foreach ($ds in $dslist) {
    Write-Host ("Checking datastore: " + $ds) -ForegroundColor Yellow 
    $folderlist = dir -Path vmstore:\$DC\$ds | % { $_.name }
    foreach ($folder in $folderlist) {
      $lockfiles = get-childitem vmstore:\$dc\$ds\$folder | Where-Object { $_.name -like "*-ctk.vmdk.lck" } | % { $_.name }

      ### Loop through collection of lock files found
      foreach ($file in $lockfiles) {
        $fullpath = "vmstore:\$DC\$ds\$folder\$file"
        $message = ("Lock file found: " + $fullpath)
        Write-Host $message
        $message |  add-content  $logfile1 
      }    
    }
  }
}

Write-Host ("Finished. Check " + $logfile1)

### Disconnect from Vcenter server
Disconnect-VIServer -Server * -Force -Confirm:$false



