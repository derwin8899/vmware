Three scripts writtend as utils for a VMware storage migration effort.

- VMDiskUsageReport.ps1 provides total storage used per VM including RAM
  - RAM is counted since VMs use datastores for swap space.

- Vms_to_Groups.ps1 automatically groups VMs efficiently in max 1800GB groups to be placed on new 2TB datastores.

- StorageVmotion.ps1 takes the grouped VMs and performs the moves to the new 2TB datastores.
