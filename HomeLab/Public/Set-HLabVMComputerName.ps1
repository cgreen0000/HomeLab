function Set-HLabVMComputerName {
    [CmdletBinding()]
    param (
        # VM Name
        [Parameter(Mandatory)]
        [string]
        $VMName,

        # New computer name of the VM. Will default to the value of $VMName if not set.
        [Parameter()]
        [string]
        $NewComputerName,

        # Credentials
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential
    )
    
    begin {
        # Sets $NewComputerName to $VMName if no value is set.
        if ($NewComputerName -eq "") {
            $NewComputerName = $VMName
        }
    }
    
    process {
        Invoke-Command -VMName $VMName -Credential $Credential -ScriptBlock { Rename-Computer -NewName $using:NewComputerName -Restart }
    }
    
    end {
        
    }
}