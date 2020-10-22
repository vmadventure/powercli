#################################################################################
# Get VM Names with Spaces
# Author: Don Horrox (https://vmadventure.com)
# Version: 1.0
#
# Purpose: Intended to query vCenter to retrieve a list of VM names which contain spaces and export results to CSV or PS Grid.
#
# Prerequisites:
# 1) User must have adequate rights to view the vCenter VM inventory. Read-only permissions at minimum are required.
# 2) Specify the target vCenter FQDN on line 63 (Replace "vcenter.domain" with your vCenter FQDN).
# 3) User must have adequate rights to save the log file to the same directory where the script resides. Modify path in line 17 as needed.
# 4) User must have adequate rights to save output file to the same directory where the script resides. Modify path in line 63 as needed.
#################################################################################
## Prepare Logging
function Get-TimeStamp {
    return "[{0:MM/dd/yy}  {0:HH:mm:ss}]" -f (Get-Date)
}
$outputLog = ".\vm_properties_names_with_spaces_log.txt"

## Initialize Script
Write-Output "$(Get-Timestamp) Initializing script..." | Out-File $outputLog -Append

# Main Menu
function Show-Menu
{
    param (
        [string]$Title = 'Get VM Names with Spaces'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    Write-Host "Select your desired output format:"
    Write-Host "`n"
    Write-Host "1) CSV File"
    Write-Host "`n"
    Write-Host "2) PowerShell Table"
    Write-Host "`n"
    Write-Host "Q: Press 'Q' to quit."
    Write-Host "`n"
    Write-Host "`n"
}
Write-Output "$(Get-Timestamp) Waiting for user input..." | Out-File $outputLog -Append

# Main Menu: Action
     Show-Menu -Title 'Main menu'
     $selection = Read-Host "Please make a selection"
     switch ($selection)
     {
         '1' {
            $OutputSelection = "CSV"
         } '2' {
             $OutputSelection = "PowerShell Table"
            } 'q' {
                $OutputSelection = "Exit"
                Write-Output "$(Get-Timestamp) User aborted script. Exiting..." | Out-File $outputLog -Append
                Exit
            }
        }
        Write-Output "$(Get-Timestamp) User selected $OutputSelection..." | Out-File $outputLog -Append

# Connect to vCenter
Clear-Host
Write-Host "$Outputselection output selected..." -ForegroundColor Yellow
Write-Output "$(Get-Timestamp) Waiting for credentials..." | Out-File $outputLog -Append
$VCServer = "vcenter.domain"
$Username = Read-Host "Enter your username"
$Password = Read-Host "Enter password" -AsSecureString
$null = Connect-VIServer $VCServer -AllLinked -User $username -Password ([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)))
Write-Output "$(Get-Timestamp) Connecting to $VCServer as $Username ..." | Out-File $outputLog -Append

# Query vCenter for VM's with a name containing a space
Write-Host "Executing query..." -ForegroundColor Yellow
Write-Output "$(Get-Timestamp) Executing query..." | Out-File $outputLog -Append
$Report = @()
Get-VM | Where {($_.Name -like "* *")} | Sort-Object -Property Name | % {
    $vm = Get-View $_.ID
        $vms = "" | Select-Object -Property Name,PowerState
        $vms.Name = $vm.Name
        $vms.PowerState = $vm.summary.runtime.powerState
    $Report += $vms
}

# Output
if ($OutputSelection -eq "Powershell Table") {
    $report | Out-GridView
    Write-Output "$(Get-Timestamp) Presenting PowerShell Table to user..." | Out-File $outputLog -Append }
    
    if ($OutputSelection -eq "CSV") {
    $report | Export-Csv -Path .\VM_Names_with_Spaces.csv -NoTypeInformation
    Write-Output "$(Get-Timestamp) Exporting to CSV..." | Out-File $outputLog -Append }

# Log out of PowerCLI
Write-Host "Disconnecting vCenter session..." -ForegroundColor Yellow
Write-Output "$(Get-Timestamp) Disconnecting from $VCServer ..." | Out-File $outputLog -Append
Disconnect-VIServer -Server * -Force -Confirm:$false
Write-Host "Session disconnected." -ForegroundColor DarkGreen
Write-Output "$(Get-Timestamp) vCenter session disconnected..." | Out-File $outputLog -Append
Write-Host "Query complete. Please close terminal window." -ForegroundColor Green