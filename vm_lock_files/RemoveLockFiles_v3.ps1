<####################################################################################### 
ScriptName: RemoveLockFiles_v3.ps1
Description: Goes through all datastores in a vcenter, finds ctk.vmdk and -ctk.vmdk.lck files and prompts user to move them to temp_dir
Author: DJE 
Date Created: 11/21/2015 
Usage : .\RemoveLockFiles_v3.ps1 -vcenter <vcenter name>
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
  write-host "Vcenter server must be specified. Example: .\RemoveLockFiles_v3.ps1 -vcenter PHvcenter.PHdomain.com"
  Exit
}
else {
  Connect-VIServer $vcenter -ErrorAction stop | out-null
}
$ErrorActionpreference = 'Continue'

### Connect to virtual center server
Connect-viserver $vcenter 

### Check if log file exists. If not, create it. Use "add-content" to update log file
$logfile1 = ".\RemoveLockFiles.log"
$date = (Get-Date).ToString()
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
  else
  {}
}

### Function to move files
function move_items() {
  if (!(test-path -path "vmstore:\$dc\$ds\temp_dir\files\$file")) {
    move-item -Path $fullpath -Destination "vmstore:\$dc\$ds\temp_dir\files" 
  }
  else {
    move-item -Path $fullpath -Destination "vmstore:\$dc\$ds\temp_dir\files" -Force 
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

      $lockfiles = get-childitem vmstore:\$dc\$ds\$folder | Where-Object { $_.name -like "*ctk.vmdk" -or $_.name -like "*-ctk.vmdk.lck" } | % { $_.name }

      ### Loop through collection of lock files found
      foreach ($file in $lockfiles) {
        $fullpath = "vmstore:\$DC\$ds\$folder\$file"
        write-host ("Lock file found: " + $fullpath)

        ### Prompt user Y/N to move the file to temp_dir
        $title = "Move file"
        $message = "Do you want to move the item to the temp_dir?"
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
          "Item moved to temp_dir"
        $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
          "No changes made."
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
        $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

        switch ($result) {
          0 {
            "You selected Yes. Moving " + $file ; temp_dir_check ; move_items
			($date + " " + $fullpath + " moved to temp_dir") |  add-content  $logfile1  
          }
          1 { "You selected No. Searching for next file..." }
        }
      }
    }
  }
}

Write-Host ("Finished. Check " + $logfile1)

### Disconnect from Vcenter server
Disconnect-VIServer -Server * -Force -Confirm:$false



