properties {
    $scripts = (Get-ChildItem "$PSScriptRoot\HomeLab" -Recurse -Include "*.psm1","*.ps1").FullName

    $buildPath = $PSScriptRoot # For anytime you need to reference the root of the build.
}

task default -depends Analyze, Test

task Analyze {
    $saResults = Invoke-ScriptAnalyzer -Path "$PSScriptRoot\HomeLab" -Severity @('Error', 'Warning') -Recurse -Verbose:$false
    if ($saResults | Where-Object {$_.Severity -eq 'Error'}) {
        $saResults | Format-Table  
        Write-Error -Message "Script Analyzer errors where found. The build cannot continue!"
    } elseif ($saResults | Where-Object {$_.Severity -eq 'Warning'}) {
        Write-Warning -Message "Script analyzer warnings found. The build can continue."
    } else {
        $saResults | Format-Table
    }
}

task Test {
    $testResults = Invoke-Pester -Path $PSScriptRoot -CodeCoverage $scripts -PassThru
    if ($testResults.FailedCount -gt 0) {
        $testResults | Format-List
        Write-Error -Message 'One or more Pester tests failed. Build cannot continue!'
    }
}

task Deploy -depends Analyze, Test {
    Invoke-PSDeploy -Path '.\HomeLab.psdeploy.ps1' -Force -Verbose:$VerbosePreference
}
