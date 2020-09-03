$server_Name=$env:COMPUTERNAME
[int]$allocation_unit=0
if($server_Name -match 'db'){

write-host "Looks Like DB server and changing the allocation unit to 64K"
$allocation_unit=65536

}
else{
write-host "Looks Like Norma server and changing the allocation unit to 4K"
$allocation_unit=4096
}
Get-Disk|where{$_.OperationalStatus -eq "offline"}|Set-Disk -IsOffline $false
Get-Disk |Where-Object PartitionStyle -Eq "RAW" |Initialize-Disk -PassThru -PartitionStyle GPT |New-Partition  -UseMaximumSize |Format-Volume -AllocationUnitSize $allocation_unit -Confirm:$false -Force
$driveletters=@("D","E","F","G","H","i","J","K","L")
$no_of_Disk=Get-Disk
$j=0


for($i=1;$i -lt $no_of_Disk.Count;$i++){

Write-Host $i $driveletters[$i]
Get-Disk -Number $i |Get-Partition |where {$_.type -eq "Basic"}|  Set-Partition -NewDriveLetter $driveletters[$i]
$j=$j+1
}

https://colab.research.google.com/drive/1bg846F7wdwgkmPyqLcvkRUH8mGhgZkAc