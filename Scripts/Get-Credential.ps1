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
 * NAME:				Get-Credential.ps1 
 *
#> 

Add-Type -AssemblyName System.DirectoryServices.AccountManagement

function DisplayInvalidCredentialsMessage {
    Write-Host ""
    Write-Host "Your credentials seem to be invalid." -ForegroundColor Red
    Write-Host "Please try again with the correct credentials.`n" -ForegroundColor Red
}

Add-Type -AssemblyName System.DirectoryServices.AccountManagement

function IsLocalUserNamePasswordValid($credential) {
    $principalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('machine', $env:COMPUTERNAME)
    $netCred = $credential.GetNetworkCredential()
    return $principalContext.ValidateCredentials($netCred.UserName, $netCred.Password)
}

#Potentially a way to check if the network is on a domain - but untested
#function IsDomainUserNamePasswordValid($credential, $domainName) {
#    $principalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('domain', $domainName)
#    $netCred = $credential.GetNetworkCredential()
#    return $principalContext.ValidateCredentials($netCred.UserName, $netCred.Password)
#}

#if the file is there use it
#Unless there is a -Force
#Then you need to the pass and validate it.

function Get-Credential {
    param (
        [switch]$Force
    )

    if ($Force -or -not (Test-Path $credentialFile)) {
        # Prompt for password securely
        $password = Read-Host -Prompt "Enter the password for $username" -AsSecureString

        # Create a new PSCredential object with the provided username and password
        $credential = New-Object System.Management.Automation.PSCredential($username, $password)

        # Validate the credential object
        $isValidLocalUser = IsLocalUserNamePasswordValid -credential $credential

        if ($isValidLocalUser) {
            # Export the credential to a file for future use
            $credential | Export-Clixml -Path $credentialFile
        }
        else {
            Write-Warning "Invalid password. Credential file not written."
        }
    }
    else {
        # Import the credential from the file
        $credential = Import-Clixml -Path $credentialFile
        $isValidLocalUser = $true
    }

    return $isValidLocalUser, $credential
}