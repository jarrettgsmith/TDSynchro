#Just execute each commands one at a time in an elevated PowerShell. 
#If they run without errors you are setup. Repeat this process
#for each computer. 

#Sets the network profile to Private
Set-NetConnectionProfile -NetworkCategory Private

#Enable PSRemoting
Enable-PSRemoting

#Sets Trusted Hosts - * means any computers
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force

#It's better to scope trusted computers to their specific names. Do not use
#IP addresses unless you understand the security implications.
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "Server1, Client1, Client2"

#Enable Filesharing
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes

#Set Execution Policy
Set-ExecutionPolicy RemoteSigned -Force

#Create self signed certificates
$cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject "CN=MyCodeSigningCert" -CertStoreLocation "Cert:\CurrentUser\My"

#Set firewall rule for TouchDesigner.2023.30863
$rule = Get-NetFirewallRule -DisplayName "TouchDesigner.2023.30863"
New-NetFirewallRule -DisplayName "TouchDesigner.2023.Custom" -Direction $rule.Direction -Action $rule.Action -Profile $rule.Profile -Program $rule.ApplicationName