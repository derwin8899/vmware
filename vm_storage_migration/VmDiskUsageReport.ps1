<####################################################################################### 
ScriptName:                      VmDiskUsageReport.ps1 
Description:                     Provides report on  disk usage of a VM including RAM amount for swap file space. 			 				
Author:                          DJE
Date Created:                    02/05/2014
Reveiwer:                        
Usage :                          VmDiskUsageReport.ps1   -vcenter <server> -csvfile <path to .txt file of servers>
Example:                         ./VmDiskUsageReport.ps1  -vcenter <server> -cluster <cluster name>
Requirements:                    Script must be run in powercli session with user permissions to vcenter server
########################################################################################>
PARAM($Vcenter, $Cluster)

# Disconnect any open connections to vcenters before starting
Write-Host "Disconnecting any  Vcenter connections already open before starting..."
$ErrorActionpreference = 'SilentlyContinue'
Disconnect-VIServer -Server * -Force -Confirm:$false  | Out-Null 

# Validate that Vcenter and cluster specified by user
$ErrorActionpreference = 'Inquire'
if (($Vcenter -eq $null) -or ($Cluster -eq $null)) {
	Write-Host "Error. Check vcenter name and cluster name" -foreground Red
	write-host "Vcenter server and cluster must be specified. Example: ./VmDiskUsageReport.ps1  -vcenter <server> -cluster <cluster name>"
	Exit
}
else {
	Connect-VIServer $vcenter -ErrorAction stop | out-null
	Get-Cluster $Cluster -ErrorAction stop | out-null
}

$ErrorActionpreference = 'Continue'

# Output file details
$outfilepath = ".\"
$outfilename = "DiskUsageReport-" + $cluster + ".csv"

$ErrorActionPreference = "silentlyContinue"

$vminfo = Get-VM -Location $cluster

# Start Report
$report = @()
foreach ($vm in $vminfo) {
	Write-Host ("Checking " + $vm.name)
	$diskSize = (Get-VM $vm.name | Get-HardDisk | Measure-Object -Property CapacityKB -Sum).sum / (1024 * 1024)
	$objds = "" | Select Name, Storage
	$objds.name = $vm
	$objds.DiskUse = $diskSize
	$objds.memsize = $vm.MemoryGB
	$objds.Storage = $diskSize + $vm.MemoryGb
	$report += $objds 

	$report | Export-Csv ($outfilepath + "\" + $outfilename) -NoTypeInformation
}

# Close any existing Vcenter connections
Disconnect-VIServer -Server * -Force -Confirm:$false

Write-Host ("Finished. Check " + $outfilepath + "\" + $outfilename) -ForegroundColor Yellow


