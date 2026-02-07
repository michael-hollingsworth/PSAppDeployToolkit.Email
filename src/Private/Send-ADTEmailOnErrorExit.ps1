function Send-ADTEmailOnErrorExit {
    [CmdletBinding()]
    param (
    )

    begin {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $adtSession = Get-ADTSession
    } process {
        try {
            try {
                [Int32]$exitCode = $adtSession.GetExitCode()

                if ($exitCode -eq 0) {
                    return
                }

                if ($exitCode -in $adtSession.AppSuccessExitCodes) {
                    return
                }

                if ($exitCode -in $adtSession.AppRebootExitCodes) {
                    return
                }

                if ($exitCode -in $adtSession.ScriptSuccessExitCodes) {
                    return
                }

                try {
                    if ($exitCode -in ([Enum]::GetValues([ExitCode]).value__)) {
                        return
                    }
                } catch {
                }

                Write-ADTLogEntry -Message "An unhandled, terminating error occurred resulting in exit code [$exitCode]." -Severity Error

                Send-ADTEmail -Subject "An unexpected error occurred while deploying [$($adtSession.InstallTitle)] on [$envComputerName]" -Body "Exit code: `r`n$exitCode$(if (($null -ne $Error) -and $Error.Count) { " `r`n$(Resolve-ADTErrorRecord -ErrorRecord $Error[0])" })" -IncludeLogs
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