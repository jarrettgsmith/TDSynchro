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

    Invoke-Command -Session $session -ScriptBlock {
        param($reposFolder, $credential, $installerFileName)
        New-PSDrive -Name "GitRepos" -PSProvider "FileSystem" -Root $reposFolder -Credential $credential
        Set-Location GitRepos:\TouchInstallers
        Get-Location

        # Define the installer path on the network share
        $remoteInstallerPath = Join-Path -Path $PWD.ProviderPath -ChildPath $installerFileName

        # Define the local temporary path on the remote computer
        $tempPath = Join-Path -Path $env:TEMP -ChildPath $installerFileName

        Write-Host "Copying $remoteInstallerPath to $tempPath"

        # Copy the installer file to the local temporary path
        Copy-Item -Path $remoteInstallerPath -Destination $tempPath -Progress

        # Define the installer arguments for silent installation
        #$installerArguments = "/VERYSILENT"

        # Execute the installer silently from the local temporary path
        #Start-Process -FilePath $tempPath -ArgumentList $installerArguments -Wait

        Write-Host "Installing $tempPath"

        $installerProcess = Start-Process -FilePath $tempPath -ArgumentList '/S','/v','/qn' -Wait -PassThru
        $installerProcess.WaitForExit()
        $exitCode = $installerProcess.ExitCode
        Write-Host "Installer exit code: $exitCode"

        # Clean up the temporary file
        Remove-Item -Path $tempPath
    } -ArgumentList $reposFolder, $credential, "TouchDesigner.2023.11600.exe"


    Remove-PSSession $session
}