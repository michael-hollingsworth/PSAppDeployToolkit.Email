Add-ADTModuleCallback -Hookpoint OnStart -Callback (Get-Command -Name 'Confirm-ADTEmailConfig')
Add-ADTModuleCallback -Hookpoint PostOpen -Callback (Get-Command -Name 'Initialize-ADTDeferredEmailsProperty')
Add-ADTModuleCallback -Hookpoint PostOpen -Callback (Get-Command -Name 'Initialize-ADTAdditionalLogFilesProperty')
Add-ADTModuleCallback -Hookpoint PreClose -Callback (Get-Command -Name 'Send-ADTDeferredEmails')
Add-ADTModuleCallback -Hookpoint PreClose -Callback (Get-Command -Name 'Send-ADTEmailOnErrorExit')

if (Test-ADTModuleInitialized) {
    Confirm-ADTEmailConfig
}

# Initialize session properties if a session already exists
if (Test-ADTSessionActive) {
    $adtSession = Get-ADTSession

    if (-not $adtSession.PSObject.Properties.ContainsKey('DeferredEmails')) {
        Initialize-ADTDeferredEmailsProperty
    }

    if (-not $adtSession.PSObject.Properties.ContainsKey('AdditionalLogFiles')) {
        Initialize-ADTAdditionalLogFilesProperty
    }
}

Write-ADTLogEntry -Message "Module [$($MyInvocation.MyCommand.ScriptBlock.Module.Name)] imported successfully." -ScriptSection Initialization