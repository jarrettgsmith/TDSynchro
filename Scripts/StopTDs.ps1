# Function to load YAML configuration
function Get-YamlConfiguration {
    param (
        [string]$ConfigFile
    )
    if (Test-Path $ConfigFile) {
        $config = Get-Content $ConfigFile -Raw | ConvertFrom-Yaml
    }
    else {
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
$reposFolder = $config.reposFolder
$gitProject = $config.gitProject
$credentialFile = "$gitProject\Scripts\credential.xml"
$username = $env:USERNAME

# Remove the current computer from the list of computers
$computers = $computers | Where-Object { $_ -ne $env:COMPUTERNAME }

# Function to get the credential
function Get-Credential {
    if (Test-Path $credentialFile) {
        # Import the credential from the file
        $credential = Import-Clixml -Path $credentialFile
    }
    else {
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
    # Establish a remote session to the host
    $session = New-PSSession -ComputerName $computer -Credential $credential

    # Kill all TouchDesigner processes on the remote computer
    Invoke-Command -Session $session -ScriptBlock {
        $processes = Get-Process -Name "TouchDesigner" -ErrorAction SilentlyContinue
        if ($processes) {
            $processes | Stop-Process -Force
            Write-Host "TouchDesigner processes killed on $($env:COMPUTERNAME)"
        }
        else {
            Write-Host "No TouchDesigner processes found on $($env:COMPUTERNAME)"
        }
    }

    Remove-PSSession $session
}