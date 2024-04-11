# Customizable variables
$computers = @("Jupiter", "Mars", "Polaris")
$reposFolder = "\\Polaris\GitRepos"
$gitProject = "C:\Users\Public\Projects\TDSynchro"
$username = "jarrett"
$credentialFile = "$gitProject\Scripts\credential.xml"

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
    
    # Map the network drive to the shared resources folder
    Invoke-Command -Session $session -ScriptBlock {
        param($reposFolder, $credential)
        New-PSDrive -Name "GitRepos" -PSProvider "FileSystem" -Root $reposFolder -Credential $credential
    } -ArgumentList $reposFolder, $credential
    
    # Connect to the mapped network drive
    Invoke-Command -Session $session -ScriptBlock {
        Set-Location GitRepos:
    }
    
    # Perform git pull on the mapped drive
    Invoke-Command -Session $session -ScriptBlock {
        param($gitProject)
        # Navigate to the specific directory where the Git repository is located
        Set-Location $gitProject
        # Perform git pull
        git pull
    } -ArgumentList $gitProject
    
    # Clean up the remote session
    Remove-PSSession $session
}