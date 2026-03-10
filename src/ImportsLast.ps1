try {
    # Set all functions as read-only, export all public definitions and finalise the CommandTable.
    Set-Item -LiteralPath $FunctionPaths -Options ReadOnly
    Get-Item -LiteralPath $FunctionPaths | & { process { $CommandTable.Add($_.Name, $_) } }
    New-Variable -Name CommandTable -Value ([System.Collections.ObjectModel.ReadOnlyDictionary[System.String, System.Management.Automation.CommandInfo]]::new($CommandTable)) -Option Constant -Force -Confirm:$false
    Export-ModuleMember -Function $Module.Manifest.FunctionsToExport

    Add-ADTModuleCallback -Hookpoint OnStart -Callback $CommandTable.'Confirm-ADTEmailConfig'
    Add-ADTModuleCallback -Hookpoint PostOpen -Callback $CommandTable.'Initialize-ADTDeferredEmailsProperty'
    Add-ADTModuleCallback -Hookpoint PostOpen -Callback $CommandTable.'Initialize-ADTAdditionalLogFilesProperty'
    Add-ADTModuleCallback -Hookpoint PreClose -Callback $CommandTable.'Send-ADTDeferredEmails'
    Add-ADTModuleCallback -Hookpoint PreClose -Callback $CommandTable.'Send-ADTEmailOnErrorExit'

    if (Test-ADTModuleInitialized) {
        Confirm-ADTEmailConfig
    }

    # Initialize session properties if a session already exists
    if (Test-ADTSessionActive) {
        $adtSession = Get-ADTSession
    
        if (-not $adtSession.PSObject.Properties.Name.Contains('DeferredEmails')) {
            Initialize-ADTDeferredEmailsProperty
        }
    
        if (-not $adtSession.PSObject.Properties.Name.Contains('AdditionalLogFiles')) {
            Initialize-ADTAdditionalLogFilesProperty
        }
    }

    # Announce successful importation of module.
    Write-ADTLogEntry -Message "Module [$($MyInvocation.MyCommand.ScriptBlock.Module.Name)] imported successfully." -ScriptSection Initialization
} catch {
    throw
}