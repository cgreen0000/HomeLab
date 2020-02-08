function Set-HLabVMIPConfig {
    [CmdletBinding()]
    param (
        # VM Name
        [Parameter(Mandatory)]
        [string]
        $VMName,

        # Network interface to configure
        [Parameter()]
        [int]
        $InterfaceIndex,

        # IP Address
        [Parameter(Mandatory)]
        [string]
        $IP,

        # Subnet Mask
        [Parameter()]
        [int]
        $SubnetMask,

        # Gateway address
        [Parameter()]
        [string]
        $GatewayIP,

        # DNS servers
        [Parameter()]
        [string[]]
        $DnsServers,

        # Credentials
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential
    )
    
    begin {

    }
    
    process {
        Invoke-Command -VMName $VMName -Credential $Credential -ScriptBlock {
            Set-NetIPInterface -InterfaceIndex $Using:InterfaceIndex -Dhcp Disabled
            New-NetIPAddress -InterfaceIndex $Using:InterfaceIndex -AddressFamily IPv4 -IPAddress $Using:IP -PrefixLength $Using:SubnetMask -Type Unicast -DefaultGateway $Using:GatewayIP | Out-Null
            Set-DnsClientServerAddress -InterfaceIndex $Using:InterfaceIndex -ServerAddresses $Using:DnsServers | Out-Null
        }
    }
    
    end {
        
    }
}