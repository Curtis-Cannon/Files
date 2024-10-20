<#############################################################################################

 Intune - Device Compliance Report
 Author: Curtis Cannon (Traversecloud.co.uk)
 https://traversecloud.co.uk/generate-a-device-compliance-report-using-powershell
 Version: 1.0
 Date: 19/08/2024

 Description:
 This script is used to generate a report on the compliance status of all managed devices
 within the 365 tenant. 

 While this script is normally fairly fast, the more devices you have the longer
 the script will take to run. The script indicates what it is working on at the time
 so that you can ensure it is still running

 Additional Info:
 - Requires you to have the MS Graph Powershell module installed (This will warn
   and not run if this is not present)
 - Requires you to have write access to the report path of your choosing
 - Report is saved to a destination of your choosing called "Intune - Unassigned Policies.csv" 
   by default, this can be changed on ln98
 - You will be prompted to sign into an account when connecting to MS Graph
 - You will require Delegated 'Device.Read.All' on the account you
   sign in with to generate this report. If you do not have permission to have this on the
   account of your choosing, an request will be sent to the approval administrator

#############################################################################################>

#Set Report Save Path
$ReportPath = "C:\Temp"

#Check Report Path
If (!(Test-Path -Path $ReportPath)){
    Write-Host -f Red "Report Path cannot be found, please check the report path and adjust where needed"
    Pause
    Exit
}

#Check for required PowerShell Module
$GraphCheck = Get-Module Microsoft.Graph -ListAvailable
If ($GraphCheck -eq $null){
    cls
    Write-host -f Red "MS Graph Powershell Module Not Installed!"
    Write-host ""
    Write-host "MS Graph Powershell module is required to run this script"
    Write-host "Please use the command [Install-Module Microsoft.Graph] to install"
    Write-host ""
    Write-host "You can also use the [-scope] switch for per user [CurrentUser]"
    Write-host "or Machine wide [all] install"
    Write-host ""
    Pause
    Exit
}

#Clear Results Array
$Results = @()

#Connect to Graph with required delegated permissions
Connect-MgGraph -Scopes Device.Read.All -NoWelcome

# Collect a list of all managed device IDs
$AllDevices = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/devices?$filter=managementType ne null&$count=true&$select=id' -Headers @{ConsistencyLevel = "eventual"}
$DeviceIDs = $AllDevices.value.ID

# Check and collect data from additional pages
Do{
    if ($AllDevices."@odata.nextlink" -ne $null){
        $AllDevices = Invoke-MgGraphRequest -Method GET -Uri $AllDevices."@odata.nextlink"
        $DeviceIDs += $AllDevices.value.ID
    }
}Until ($AllDevices."@odata.nextlink" -eq $null)

# Collect information for each listed device
$DeviceCount = 0
foreach ($DeviceID in $DeviceIDs){
    $DeviceCount ++
    #Display Progress on screen
    $Device = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/devices/$($DeviceID)?`$select=id,displayName,operatingSystem,operatingSystemVersion,isCompliant,manufacturer,model,createdDateTime,managementType"
    Write-Progress -PercentComplete ($DeviceCount/$DeviceIDs.count*100) -Status "Processing Devices" -Activity "($DeviceCount of $($DeviceIDs.count)) Currently on $($Device.displayname)"
    $Results += New-Object psobject -Property @{
        "Device Name" = $Device.displayname
        "Compliant" = $Device.isCompliant
        "OS" = $Device.operatingSystem
        "OS Version" = $Device.operatingSystemVersion
        "Owner" = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/devices/$($DeviceID)/registeredOwners?`$select=userPrincipalName").value.userPrincipalName
        "Model" = $Device.model
        "Created" = ($Device.createdDateTime).ToString('dd/MM/yyyy HH:mm')
        "Management Type" = $Device.managementType
    }
}
Write-Progress -Completed -Activity "Completed"

#Disconnect from Microsoft Graph
Disconnect-MgGraph

#Save results to csv
$results | Select "Device Name", "Compliant", "OS", "OS Version", "Owner", "Model", "Created", "Management Type" | Export-Csv -NoTypeInformation -Path "$($ReportPath)\Intune - Device Compliance.csv"
