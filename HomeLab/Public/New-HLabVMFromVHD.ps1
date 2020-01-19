function New-HLabVMFromVHD {
    [CmdletBinding()]
    param (
        # Specifies the name of the VM.
        [Parameter(Mandatory=$true, 
            Position=0, 
            ValueFromPipeline)]
        [string[]]
        $Name,

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
        [Parameter(Position=2,
            ValueFromPipeline)]
        [int64]
        $StartupRAM = 1GB,

        # Minimum ammount of memory that is dynamically assigned to the VM.
        [Parameter(Position=3,
            ValueFromPipeline)]
        [int64]
        $MinRAM = 512MB,

        # Maximum amount of memory that is dynimically assigned to the VM.
        [Parameter(Position=4,
            ValueFromPipeline)]
        [int64]
        $MaxRAM = 2GB,

        # Specifies the generation of VM.
        [Parameter(Position=5,
            ValueFromPipeline)]
        [ValidateSet(1,2)]
        [int16]
        $Generation = 2,

        # Specifies the virtual switch to connect the VM to. "Default Switch" is the switch that is created automatically with the Hyper-V role.
        [Parameter(Position=6,
            ValueFromPipeline)]
        [string]
        $VSwitch = "Default Switch",

        # This indicates if the VM should start after creation.
        [Parameter()]
        [switch]
        $Start
    )
    
    begin {
    }
    
    process {
        $Name | ForEach-Object {
            $newVHDPath = "C:\Homelab\VHD\" + $_ + ".vhdx"
            Write-Verbose -Message "Copying VHD for $_"
            New-VHD -Path $newVHDPath -ParentPath $ParentVHDPath -Differencing
            New-VM -Name $_ -MemoryStartupBytes $StartupRAM -Generation $Generation -VHDPath $newVHDPath

            Set-VM -Name $_ -ProcessorCount 1 -DynamicMemory -MemoryMinimumBytes $MinRAM -MemoryMaximumBytes $MaxRAM
            Get-VMNetworkAdapter -VMName $_ | Connect-VMNetworkAdapter -SwitchName $VSwitch
            Write-Verbose -Message "New VM created for $_"
            
            if ($Start) {
                Write-Verbose -Message "Starting $_"
                Start-VM -Name $_
            }
        }
    }
    
    end {
    }
}