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
 * NAME:				Start-ClusterProject.ps1 
 *
#> 

#Get the configuration objects
. .\Get-Configuration.ps1
$config, $computers, $username, $credentialFile = Get-Configuration

#Get the credentials
. .\Get-Credential.ps1
$isValidLocalUser, $credential = Get-Credential -username $username -credentialFile $credentialFile

# Get the current script's directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Get the source directory path (two levels up from the script path)
$sourceDir = Split-Path -Parent (Split-Path -Parent $scriptPath)

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
        #$app = "../../../TouchDesigner/bin/TouchDesigner.exe"
        $appPath = "TouchDesigner\bin\TouchDesigner.exe"
        $app = "$using:sourceDir\$appPath"
        $project = "$using:sourceDir\Project\Project.toe"
        Write-Host "Running TouchDesigner from $using:sourceDir"
        Set-Location $using:location
        & ../../PSTools/psexec -accepteula -s \\localhost -i $using:sessionId -u "NT AUTHORITY\NETWORK SERVICE" -d $app $project *> $null
    }

    #Invoke-Command $computer -EnableNetworkAccess -ScriptBlock {
    #    #$app = "../../../TouchDesigner/bin/TouchDesigner.exe"
    #    $appPath = "TouchDesigner\bin\TouchDesigner.exe"
    #    $app = "$using:sourceDir\$appPath"
    #    $project = "$using:sourceDir\Project\Project.toe"
    #    Write-Host "Running TouchDesigner from $using:sourceDir"
    #    Set-Location $using:location
    #    & ../../PSTools/psexec -accepteula -s \\localhost -i $using:sessionId -u "NT AUTHORITY\NETWORK SERVICE" -d $app $project
    #}

    Remove-PSSession $session 

}
# SIG # Begin signature block
# MIIFcwYJKoZIhvcNAQcCoIIFZDCCBWACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5Jkb73RqR97M0kqNZEy7qPVo
# GoagggMMMIIDCDCCAfCgAwIBAgIQLjUy+e7qMp1AdZiJBzl71jANBgkqhkiG9w0B
# AQsFADAcMRowGAYDVQQDDBFNeUNvZGVTaWduaW5nQ2VydDAeFw0yNDA1MDMxODQ4
# MDBaFw0yNTA1MDMxOTA4MDBaMBwxGjAYBgNVBAMMEU15Q29kZVNpZ25pbmdDZXJ0
# MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2lOwD6iYn441gp61Z4SQ
# vjdL8wri2lFlRrX8bUiYht77cUHr3DS+ncjW2ZS3OYKrQyb/2Fl8AIeil3gLGCb1
# IE6DmiMV6LWXb4NvS2NCm4LQ1cUfApBsJzyQbSgJ6o7Cj8LF1ELxSzQzjf8fBXCx
# OZvsLMbsgnKHa7ujlz4GGm78veLLonVcmm80QO+ad5boaafXnkbBtooDdL1Qk93y
# oV06V9e5hNFuSZepQ2bH4Y/SyXxWPU5L5vKYU9t1vZWEE1uWbgqON6FW2O/cGQsL
# ONIaj55fhyFWMbnEn3sOo8depFlaXP0Wza1yfFYFhc04AbxmZDMu/psw24zXMUwj
# +QIDAQABo0YwRDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMw
# HQYDVR0OBBYEFAZWcNTQO1+j5TOIo5BQMdl30W14MA0GCSqGSIb3DQEBCwUAA4IB
# AQCuHK1E99VnYZ0iJIHtBhw/8EIsmjx0WC1eTONEV0HtfTRTyhRPVpM1J1vz2BLQ
# gNEHexEzZgw4ofjN81Gxa7bLZF4swMkMFN3Hi3uyewUWkBHpZxQu640MYYyUfFa9
# WSuI9FuPGWPX3WJ+GfPvyjSPflNGln3HtE1956QBJy+cRlrMHVaF7iMKrryjDvOJ
# /z0TYir5ee/IqV4onZmlUPOfi49wDnIPLW8XrD8YN3J/a7LLe3ZA5nLEm42DEAQc
# aeh+Auzj29oiDkN69sjAtSjpI3BpPC69rTAMpVPJUzz8rBpC/xTLnEPH21rX2XRj
# 9P98j+KQPnh7gMnEoG2sk7HnMYIB0TCCAc0CAQEwMDAcMRowGAYDVQQDDBFNeUNv
# ZGVTaWduaW5nQ2VydAIQLjUy+e7qMp1AdZiJBzl71jAJBgUrDgMCGgUAoHgwGAYK
# KwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIB
# BDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU
# hfUWt0TQWaRZU7lzd3LYwgr0RE0wDQYJKoZIhvcNAQEBBQAEggEAnfi0gzgZT+mv
# NmTniXz74G/sn3gwIYdW6c81kW+cJvWLoG05j4uM1zNrojMC41AOOWtvoQJzJ2eH
# UcZMhw7n1JDQ4W+mUXM6oX0HhtRwkXH+xfkKUdSNEW0MQqPuKA4rcx3gfQg4TNs8
# jnwNhuZoMvCidV5/v1XE6XLkwPfkKdtAqTyGRt9vn98tg7+tnOculgKTl2ktDCEs
# aXYkxfA2oZhqVV9PEzsnot74TBvlxkO+1b/wrrlP5DAkS3WjPuQTO8t/tTGAk8mb
# 3t2fl4efAQakqQ4kynCTjwAkccQjD7UYP18XjtuwKyoWfPn+ViK3+17OsliQ+R45
# m77oYASM+A==
# SIG # End signature block
