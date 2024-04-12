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
 * NAME:				Deploy-ProjectToCluster.ps1 
 *
#> 

#Get the configuration objects
. .\Get-Configuration.ps1
$config, $computers, $username, $credentialFile = Get-Configuration

#Get the credentials
. .\Get-Credential.ps1
$isValidLocalUser, $credential = Get-Credential -username $username -credentialFile $credentialFile

# Get the current script's directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Get the source directory path (two levels up from the script path)
$sourceDir = Split-Path -Parent (Split-Path -Parent $scriptPath)
Write-Host "We are here $scriptPath, and we are copying this: $sourceDir"

# Define the share name and the path to share
$shareName = "TempSourceShare"
$localPath = $sourceDir  # The local path you want to share

# Check if the SMB share already exists
$existingShare = Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue

if ($null -eq $existingShare) {
    Write-Host "Creating SMB share '$shareName'..."
    # Create the SMB share
    New-SmbShare -Name $shareName -Path $localPath -FullAccess everyone
} else {
    Write-Host "SMB share '$shareName' already exists."
}

# Iterate over each host
foreach ($computer in $computers) {
    try{
        Write-Host "Connecting to $computer..."
        # Establish a remote session to the host
        $session = New-PSSession -ComputerName $computer -Credential $credential

        # Map the network drive to the shared resources folder
        Invoke-Command -Session $session -ScriptBlock {
            param($credential, $sourceHost, $sourceDir, $shareName)

            # Mapping network drive with provided credentials
            New-PSDrive -Name "Source" `
                        -PSProvider "FileSystem" `
                        -Root "\\$sourceHost\$shareName" `
                        -Credential $credential
            Write-Host "Mapped network drive to Source."

            # Constructing source path using UNC naming conventions
            $sourcePath = "\\$sourceHost\$shareName"
            Write-Host "Source path set to $sourcePath"

            # Initiating Robocopy to mirror the source directory to the target directory
            Write-Host "Starting Robocopy operation from Source to Target directory."
            robocopy $sourcePath $sourceDir /MIR > robocopy_log.txt
            Write-Host "Robocopy operation completed."

        } -ArgumentList $credential, $env:ComputerName, $sourceDir, $sharename

        
        # Clean up the remote session
        Remove-PSSession $session
    }
    catch{
        Write-Host "Connection to $computer failed."
    }
}
