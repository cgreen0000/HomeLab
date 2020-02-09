function New-HLabVMRouter {
    [CmdletBinding()]
    param (
        # Specifies the name of the VM.
        [Parameter(Mandatory=$true, 
            Position=0, 
            ValueFromPipeline)]
        [string]
        $Name,

        # Credentials
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        # Specifies the virtual switch to connect the connect the 1st network adapter to. This will be treated as the external network. "Default Switch" is the switch that is created automatically with the Hyper-V role.
        [Parameter(ValueFromPipeline)]
        [string]
        $ExternalvSwitch = "Default Switch",

        # External IP
        [Parameter(Mandatory)]
        [string]
        $ExternalIP,

        # External Subnet mask
        [Parameter()]
        [int]
        $ExternalSubnetMask,

        # External Gateway
        [Parameter()]
        [string]
        $ExternalGateway,

        # External DNS servers
        [Parameter()]
        [string[]]
        $ExternalDNS,

        # This specifies the private virtual switch to connect the 2nd network adapter to. This will be treated as the internal network to the router.
        [Parameter(Mandatory,
            Position=2,
            ValueFromPipeline)]
        [string]
        $InternalvSwitch,

        # Internal IP
        [Parameter(Mandatory)]
        [string]
        $InternalIP,

        # Internal Subnet mask
        [Parameter()]
        [int]
        $InternalSubnetMask,

        # Internal Gateway
        [Parameter()]
        [string]
        $InternalGateway,

        # Internal DNS servers
        [Parameter()]
        [string[]]
        $InternalDNS,
        
        # Specifies a path to one or more locations.
        [Parameter(Position=1,
            ParameterSetName="VHDPath",
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage="Path to one or more locations.")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('C:\HomeLab\VHD\2012R2 GUI Sysprep.vhdx','C:\HomeLab\VHD\win16.vhdx')]
        [string]
        $ParentVHDPath = 'C:\HomeLab\VHD\win16.vhdx',

        # Specifies the startup memory for the VM.
        [Parameter(ValueFromPipeline)]
        [int64]
        $StartupRAM = 1GB,

        # Minimum ammount of memory that is dynamically assigned to the VM.
        [Parameter(ValueFromPipeline)]
        [int64]
        $MinRAM = 512MB,

        # Maximum amount of memory that is dynimically assigned to the VM.
        [Parameter(ValueFromPipeline)]
        [int64]
        $MaxRAM = 2GB,

        # Specifies the generation of VM.
        [Parameter(ValueFromPipeline)]
        [ValidateSet(1,2)]
        [int16]
        $Generation = 2,

        

        # This indicates if the VM should start after creation.
        [Parameter()]
        [switch]
        $Start
    )
    
    begin {
        
    }
    
    process {
        New-HLabVMFromVHD -Name $Name -VSwitch $ExternalvSwitch -Start
        
        # Will need to check VM for when it is ready at this point.
        $VMStatus = ""
        while ($VMStatus -ne "OkApplicationsHealthy") {
            Start-Sleep -Seconds 5
            $VMStatus = (Get-VM -Name $Name).Heartbeat
        }

        Add-VMNetworkAdapter -VMName $Name -SwitchName $InternalvSwitch

        # Check for when the new network adapter is available.
        $VMNetworkAdapterStatus = ""
        while ($VMNetworkAdapterStatus -notcontains "Ok") {
            Start-Sleep -Seconds 5
            $VMNetworkAdapterStatus = (Get-VMNetworkAdapter -VMName $Name).Status
        }

        Set-HLabVMComputerName -VMName $Name -Credential $Credential

        # The VM will restart. Need to check for when it is ready again.
        $VMStatus = ""
        while ($VMStatus -ne "OkApplicationsHealthy") {
            Start-Sleep -Seconds 5
            $VMStatus = (Get-VM -Name $Name).Heartbeat
        }

        # Need to determine which network adapter is connected to which vSwitch.
        # This will get the attached network adapters. Includes the following useful properties: SwitchName, MacAddress
        $VMNetworkAdapters = Get-VMNetworkAdapter -VMName $Name
        $NetworkAdapters = Invoke-Command -VMName $Name -Credential $Credential -ScriptBlock {Get-NetAdapter}

        # Then find which MacAddress corresponds with which SwitchName.
        $ExternalNetworkAdapterMAC = ($VMNetworkAdapters | Where-Object {$_.SwitchName -eq "$ExternalvSwitch"}).MacAddress
        $InternalNetworkAdapterMAC = ($VMNetworkAdapters | Where-Object {$_.SwitchName -eq "$InternalvSwitch"}).MacAddress

        # Why you no use same format Microsoft?!? :-(
        $ExternalNetworkAdapterIndex = ($NetworkAdapters | Where-Object {($_.MacAddress -replace "[^A-Z0-9]","") -eq $ExternalNetworkAdapterMAC}).ifIndex
        $InternalNetworkAdapterIndex = ($NetworkAdapters | Where-Object {($_.MacAddress -replace "[^A-Z0-9]","") -eq $InternalNetworkAdapterMAC}).ifIndex

        Set-HLabVMIPConfig -VMName $Name -InterfaceIndex $ExternalNetworkAdapterIndex -IP $ExternalIP -SubnetMask $ExternalSubnetMask -GatewayIP $ExternalGateway -DnsServers $ExternalDNS -Credential $Credential
        Set-HLabVMIPConfig -VMName $Name -InterfaceIndex $InternalNetworkAdapterIndex -IP $InternalIP -SubnetMask $InternalSubnetMask -GatewayIP $InternalGateway -DnsServers $InternalDNS -Credential $Credential
    }
    
    end {
        
    }
}