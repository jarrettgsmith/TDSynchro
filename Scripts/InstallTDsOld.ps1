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
$reposFolder = $config.reposFolder
$gitProject = $config.gitProject
$credentialFile = "$gitProject\\Scripts\\credential.xml" 

#Get the username
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
    # Establish a remote session to the host

    $session = New-PSSession -ComputerName $computer -Credential $credential
        
    $sessionId = Invoke-Command -Session $session -ScriptBlock {
        $output = qwinsta | Select-String "Active"
        if ($output -match "(\d+)\s+Active") {
            $matches[1]
        } else {
            Write-Warning "No active session found."
        }
    }

    Write-Host "Session ID: $sessionId"

    # Map the network drive to the shared resources folder
    Invoke-Command -Session $session -ScriptBlock {
        param($reposFolder, $credential)
        New-PSDrive -Name "GitRepos" -PSProvider "FileSystem" -Root $reposFolder -Credential $credential
        Set-Location GitRepos:
        Get-Location
        whoami
        # Define the installer path
        $installerPath = ".\TouchInstallers\TouchDesigner.2023.11600.exe"

        $isFile = Test-Path $installerPath
        Write-Host "Is file $isFile"

        # Define the installer arguments for silent installation
        $installerArguments = "/VERYSILENTLY" # '/S' for silent installation

        # Execute the installer silently
        Start-Process -FilePath $installerPath -ArgumentList $installerArguments -Wait

        #psexec -accepteula -s \\localhost -i 1 -d -u $($credential.UserName) -p $($credential.GetNetworkCredential().Password) whoami
    } -ArgumentList $reposFolder, $credential

    Remove-PSSession $session
}