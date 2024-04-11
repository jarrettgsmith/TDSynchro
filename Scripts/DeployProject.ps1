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

foreach ($computer in $computers) {
    Write-Host "Connecting to $computer..."

    try {
        # Establish a remote session to the target computer
        $session = New-PSSession -ComputerName $computer -Credential $credential -ErrorAction Stop

        # Get the public folder path on the target computer
        $publicFolder = Invoke-Command -Session $session -ScriptBlock {
            $env:PUBLIC
        }

        # Construct the target directory path
        $targetDir = Join-Path -Path $publicFolder -ChildPath (Split-Path -Parent $sourceDir | Split-Path -Leaf)

        # Create the target directory if it doesn't exist
        Invoke-Command -Session $session -ScriptBlock {
            param($targetDir)
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir | Out-Null
            }
        } -ArgumentList $targetDir

        # Sync the folder structure and contents
        Write-Host "Syncing folders and files to $computer..."
        Copy-Item -Path $sourceDir -Destination $targetDir -ToSession $session -Recurse -Force
        Write-Host "Sync completed for $computer."

        # Close the remote session
        Remove-PSSession $session
    }
    catch {
        Write-Host "Connection to $computer failed."
    }
}