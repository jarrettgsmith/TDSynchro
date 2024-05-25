<# Shared Use License: This file is owned by Derivative Inc. (Derivative)
* and can only be used, and/or modified for use, in conjunction with
* Derivative's TouchDesigner software, and only if you are a licensee who has
* accepted Derivative's TouchDesigner license or assignment agreement
* (which also govern the use of this file). You may share or redistribute
* a modified version of this file provided the following conditions are met:
*
* 1. The shared file or redistribution must retain the information set out
* above and this list of conditions.
* 2. Derivative's name (Derivative Inc.) or its trademarks may not be used
* to endorse or promote products derived from this file without specific
* prior written permission from Derivative.
*/

/*
 * Produced by:
 *
 * 				Derivative Inc
 *				401 Richmond Street West, Unit 386
 *				Toronto, Ontario
 *				Canada   M5V 3A8
 *				416-591-3555
 *
 * NAME:				Extract-TD.ps1 
 *
#> 

# Get the directory of the currently running script
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Calculate the installer path as two levels up from the script's location
$InstallerPath = Split-Path -Parent (Split-Path -Parent $scriptPath)

# Set the InstallDir as a subfolder called TouchDesigner inside $InstallerPath
$InstallDir = Join-Path -Path $InstallerPath -ChildPath "TouchDesigner"

# Find the first TouchDesigner installer in the $InstallerPath directory
$installerFile = Get-ChildItem -Path $InstallerPath -Filter "TouchDesigner.*.exe" | Select-Object -First 1

# If no installer file is found, exit the script
if ($null -eq $installerFile) {
    Write-Error "No TouchDesigner installer file found in $InstallerPath"
    exit
}

# Full path to the installer
$fullInstallerPath = $installerFile.FullName

# Create a firewall rule for new TouchDesigner
New-NetFirewallRule -DisplayName "TouchDesigner TDSynchro Extraction" `
                    -Direction Inbound `
                    -Action Allow `
                    -Profile Any `
                    -Program ($InstallDir + "\bin\TouchDesigner.exe") `
                    -Description "Allow inbound traffic for TouchDesigner"

# Check if the TouchDesigner directory already exists
if (Test-Path -Path $InstallDir) {
    # Remove the existing TouchDesigner directory and its contents
    Remove-Item -Path $InstallDir -Recurse -Force
}

# Ensure the target directory exists or create it
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

# Construct the installation command arguments
$installArgs = "/VERYSILENT /Extract /DIR=`"$InstallDir`""

Write-Host ""
Write-Host "Extracting TouchDesigner. This can take a few minutes." 
Write-Host "The prompt will return when extraction is complete."

# Execute the installation command using Start-Process
Start-Process -FilePath "$fullInstallerPath" -ArgumentList $installArgs -Wait -NoNewWindow
