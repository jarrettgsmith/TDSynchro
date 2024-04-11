# Get the current script's directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Get the source directory path (two levels up from the script path)
$sourceDir = Split-Path -Parent (Split-Path -Parent $scriptPath)
Write-Host "We are here $scriptPath, and we are copying this: $sourceDir"

# Function to load YAML configuration
function Get-YamlConfiguration {
    param (
        [string]$ConfigFile
    )
    if (Test-Path $ConfigFile) {
        $config = Get-Content $ConfigFile -Raw | ConvertFrom-Yaml
    } else {
        Write-Warning "Custom configuration file not found. Using default configuration."
        $config = Get-Content ".\default_config.yml" -Raw | ConvertFrom-Yaml
    }
    return $config
}

# Load configuration from YAML
$configFile = "..\..\config.yml"
$config = Get-YamlConfiguration -ConfigFile $configFile

# Extract variables from the configuration
$computers = $config.computers
$reposFolder = $config.reposFolder
$gitProject = $config.gitProject
$credentialFile = ".\credential.xml"
$username = $env:USERNAME

# Remove the current computer from the list of computers
$computers = $computers | Where-Object { $_ -ne $env:COMPUTERNAME }

# Function to get the credential
function Get-Credential {
    if (Test-Path $credentialFile) {
        # Import the credential from the file
        $credential = Import-Clixml -Path $credentialFile
    } else {
        # Prompt for password securely
        $password = Read-Host -Prompt "Enter the password for $username" -AsSecureString
        # Create a new PSCredential object with the provided username and password
        $credential = New-Object System.Management.Automation.PSCredential($username, $password)
        # Export the credential to a file for future use
        $credential | Export-Clixml -Path $credentialFile
    }
    return $credential
}

# Get the credential
$credential = Get-Credential

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
