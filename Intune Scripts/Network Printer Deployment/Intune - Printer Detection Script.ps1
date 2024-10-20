#Set Variables
$DriverName = "Canon Generic Plus PCL6" #The Name of the printer driver listed in the INF file
$PrinterName = "Canon Test Printer" #The name that you want assigned to the created printer and port

$DriverCheck = Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue
$PortCheck = Get-PrinterPort -Name $PrinterName -ErrorAction SilentlyContinue
$PrinterCheck = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue

If ($DriverCheck -ne $null -and $PortCheck -ne $null -and $PrinterCheck -ne $null){
    Write-Output "$($PrinterName) and components installed successfully"
    Exit 0
}Elseif ($DriverCheck -eq $null){
    Write-Output "Driver installation failed"
    Exit 1
}Elseif ($PortCheck -eq $null){
    Write-Output "Printer Port Creation Failed"
    Exit 1
}Elseif ($PrinterCheck -eq $null){
    Write-Output "Printer Object Creation Failed"
    Exit 1
}Else {
    Write-Output "Installation failed with unknown error"
    Exit 1
}