# This script is expected to run while connected to the internet
$isOnline = Invoke-WebRequest -UseBasicParsing -Uri "https://graph.microsoft.com"
if (!$isOnline) {
    Write-Output "This device appear to NOT be Internet Connected."
    Read-Host "Press Enter to Exit "
    exit
}

Write-Host "Installing NuGet"
Install-PackageProvider -Name NuGet -Force
Write-Host "Installing Azure AD Module"
Install-Module -Name AzureAD -Force
Write-Host "Installing AutoPilot Module"
Install-Module -Name WindowsAutoPilotIntune -Force
Write-Host "Fetching AutoPilot Script"
Save-Script -Name Get-WindowsAutoPilotInfo -Path ./

Write-Output "`n`nLog in to Azure AD..."
Connect-MSGraph

$CSVFile = "$(get-date -Format FileDateTimeUniversal).csv"
./Get-WindowsAutoPilotInfo.ps1 -OutputFile $CSVFile

# Read CSV and process each device
$devices = Import-CSV $CSVFile

foreach ($device in $devices) {
    Add-AutoPilotImportedDevice -serialNumber $device.'Device Serial Number' -hardwareIdentifier $device.'Hardware Hash' -orderIdentifier 'Kiosk' $CSVFile
    Write-Output "Imported Device $($device.'Device Serial Number')"
}

Write-Output "It will take several minutes for the device to appear in the Intune portal before a Profile can be assigned."

#Remove-Item -Path $CSVFile
