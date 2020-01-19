# This gets the filenames of all of the functions that the module uses.
$PublicFunctions = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$PrivateFunctions = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

# Loading the functions into memory with dot-sourcing
foreach ($script in @($PublicFunctions + $PrivateFunctions)) {
    try {
        Write-Verbose -Message "Importing file named $($script.Fullname)"
        . $script.Fullname
    }
    catch {
        Write-Error -Message "Could not import $($script.Fullname): $_"
    }
}

Export-ModuleMember -Function $PublicFunctions.Basename