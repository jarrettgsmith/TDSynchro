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
# Remove the current computer from the list of computers
$computers = $computers | Where-Object { $_ -ne $env:COMPUTERNAME }

# Get the credential
$username = $env:USERNAME 
Write-Host "Hello $username."
$password = Read-Host -Prompt "Enter the password for $username" -AsSecureString
$credential = New-Object System.Management.Automation.PSCredential($username, $password)

# Iterate over each host
foreach ($computer in $computers) {

    Invoke-Command -ComputerName $computer -EnableNetworkAccess -ScriptBlock {
        Write-Host "I am $env:ComputerName"
    }

}