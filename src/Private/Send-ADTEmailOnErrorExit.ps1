function Send-ADTEmailOnErrorExit {
    [CmdletBinding()]
    param (
    )

    begin {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $adtSession = Get-ADTSession
        $adtConfig = Get-ADTConfig
    } process {
        try {
            try {
                [Int32]$exitCode = $adtSession.GetExitCode()

                if ($exitCode -eq 0) {
                    return
                }

                if (($exitCode -eq $adtConfig.UI.DefaultExitCode) -or ($exitCode -eq $adtConfig.UI.DeferExitCode)) {
                    return
                }

                if ($exitCode -in $adtSession.AppSuccessExitCodes) {
                    return
                }

                if ($exitCode -in $adtSession.AppRebootExitCodes) {
                    return
                }

                if ($adtSession.PSObject.Properties.Name.Contains('ScriptSuccessExitCodes') -and ($exitCode -in $adtSession.ScriptSuccessExitCodes)) {
                    return
                }

                if (($null -ne [System.Management.Automation.PSTypeName]::new('ExitCode').Type) -and ($exitCode -in ([Enum]::GetValues([ExitCode]).value__))) {
                    return
                }

                Write-ADTLogEntry -Message "An unhandled, terminating error occurred resulting in exit code [$exitCode]." -Severity Error

                Send-ADTEmail -Subject "An unexpected error occurred while deploying [$($adtSession.InstallTitle)] on [$((Get-ADTEnvironmentTable).envComputerName)]" -Body "Exit code: $exitCode$(if ($Global:Error.Count) { " `r`n$(Resolve-ADTErrorRecord -ErrorRecord $Global:Error[0])" })" -IncludeLogs
            } catch {
                Write-Error -ErrorRecord $_
            }
        } catch {
            Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
        }
    } end {
        Complete-ADTFunction -Cmdlet $PSCmdlet
    }
}
