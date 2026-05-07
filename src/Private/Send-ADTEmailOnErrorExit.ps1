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

                # Custom property added to ADT sessions for the purpose of defining custom non-failure return codes (not tied to AppSuccessExitCodes and AppRebootExitCodes, due to their specialized use in other PSADT functions)
                if ($adtSession.psobject.Properties.Name.Contains('ScriptSuccessExitCodes') -and ($exitCode -in $adtSession.ScriptSuccessExitCodes)) {
                    return
                }

                # Skip if the exit code provided is from the custom [ExitCode] enum, defined in the Invoke-AppDeployToolkit.ps1 script.
                if (Get-PSCallStack | & { process { if ($_.Command -eq 'Close-ADTSession' ) { return $_ } } } | Select-Object -First 1 | ForEach-Object { $_.InvocationInfo.Line -match '-ExitCode \(\[ExitCode\]::\w+\)' }) {
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
