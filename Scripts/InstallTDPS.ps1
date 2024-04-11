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
$configFile = ".\custom_config.yml"
$config = Get-YamlConfiguration -ConfigFile $configFile

# Extract variables from the configuration
$computers = $config.computers
$localInstallerPath = "C:\Users\Jarrett\AppData\Local\Temp\TouchDesigner.2023.11600.exe"  # Update with the local installer path on each computer
$gitProject = $config.gitProject
$credentialFile = "$gitProject\Scripts\credential.xml"

# Get the username
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

# Iterate over each host
foreach ($computer in $computers) {
    Write-Host "Connecting to $computer..."

    # Define the PsExec command to run the installer on the remote computer
    $psexecCommand = "psexec.exe \\$computer -i -u $($credential.UserName) -p $($credential.GetNetworkCredential().Password) -h -d $localInstallerPath /VERYSILENT /SUPPRESSMSGBOXES"
    
    # Execute the PsExec command
    Invoke-Expression $psexecCommand
    
    # Wait for a certain period of time (e.g., 60 seconds) to allow the installation to complete
    Start-Sleep -Seconds 120
    
    # Check if the TouchDesigner application is running on the remote computer
    $touchDesignerProcess = Invoke-Command -ComputerName $computer -Credential $credential -ScriptBlock {
        Get-Process -Name "TouchDesigner" -ErrorAction SilentlyContinue
    }
    
    if ($touchDesignerProcess) {
        Write-Host "TouchDesigner installation completed successfully on $computer."
    } else {
        Write-Warning "TouchDesigner installation may have failed on $computer. Please check the installation logs."
    }
}