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
 * NAME:				Start-ClusterNotepad.ps1 
 *
#> 

#Get the configuration objects
. .\Get-Configuration.ps1
$config, $computers, $username, $credentialFile = Get-Configuration

#Get the credentials
. .\Get-Credential.ps1
$isValidLocalUser, $credential = Get-Credential -username $username -credentialFile $credentialFile

if ($isValidLocalUser){
    # Iterate over each host
    foreach ($computer in $computers) {
        Write-Host "Connecting to $computer..."

        # Establish a remote session to the host
        $session = New-PSSession -ComputerName $computer -Credential $credential
        $location = Get-Location
            
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
            $app = "notepad.exe"
            Set-Location $using:location
            Get-Location
            & ../../PSTools/psexec -accepteula -s \\localhost -i $using:sessionId -d -u "NT AUTHORITY\NETWORK SERVICE" $app
        }

        Remove-PSSession $session 

    }
}