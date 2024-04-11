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

