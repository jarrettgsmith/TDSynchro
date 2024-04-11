# Define the client computer names
$clientComputers = "Client1", "Client2", "Client3"

# Start Notepad on each client computer
foreach ($computer in $clientComputers) {
    Invoke-Command -ComputerName $computer -ScriptBlock {
        # Start Notepad
        Invoke-Command -ComputerName $computer -EnableNetworkAccess -ScriptBlock {psexec -accepteula -s \\localhost -i 2 -d -u "NT AUTHORITY\NETWORK SERVICE" notepad}
    }
}
