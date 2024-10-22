#Adjustable variables
$DriverName = "Canon Generic PCL6 Driver" #The Name of the printer driver listed in the INF file
$PrinterName = "Canon Test Printer" #The name that you want assigned to the created printer and port
$PrinterIP = "10.0.0.10" #The IP address of the printer in question
$INFSource = "C:\Temp\Test Printer\GPCL6_Driver_V311_W64_00\Driver\CNP60MA64.INF" #The Location of the INF file for your printer drivers (leave PSScriptRoot as it is)

#Add printer to driver store and collect published name
$PNPOutput = pnputil -a $INFSource| Select-String "Published Name"
$null = $pnpOutput -match "Published name :\s*(?<name>.*\.inf)" 
$driverINF = "C:\Windows\INF\$($matches.Name)"

#Add printer driver from driver store
Add-PrinterDriver -Name $DriverName -InfPath $driverinf

#Add Printer port using information provided
If ((Get-PrinterPort -Name $PrinterName -ErrorAction SilentlyContinue) -eq $null){
    Add-PrinterPort -Name $PrinterName -PrinterHostAddress $PrinterIP
}

#Create Printer object using new driver and port, with provided details
If ((Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue) -eq $null){
    Add-Printer -DriverName $DriverName -Name $PrinterName -PortName $PrinterName
}

#Create File to show successful deployment
If ((Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue) -ne $null){
    New-Item -Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\$($PrinterName) Deployment Successful.log"
    Exit 0
} Else {
    Exit 1
}
