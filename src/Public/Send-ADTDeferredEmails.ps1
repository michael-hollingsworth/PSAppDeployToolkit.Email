function Send-ADTDeferredEmails {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Switch]$DoNotExportOnFail
    )

    begin {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $adtSession = Get-ADTSession
        $adtConfig = Get-ADTConfig
    } process {
        try {
            try {
                if (-not $adtSession.DeferredEmails.Count) {
                    return
                }

                Write-ADTLogEntry -Message "Sending [$($adtSession.DeferredEmails.Count)] defered emails."

                foreach ($deferredEmail in $adtSession.DeferredEmails) {
                    try {
                        Send-ADTEmail @deferredEmail
                        $adtSession.DeferredEmails.Remove($deferredEmail)
                    } catch {
                        #TODO: Make sure the error is logged but don't exit
                    }
                }

                if (-not $adtSession.DeferredEmails.Count) {
                    return
                }

                if (-not $adtConfig.Email.ExportOnFailureToSend) {
                    Write-ADTLogEntry -Message "Failed to send [$($adtSession.DeferredEmails.Count)] emails." -Severity 3
                    return
                }

                Write-ADTLogEntry -Message "Failed to send [$($adtSession.DeferredEmails.Count)] emails. Exporting emails to [$($adtConfig.Email.ExportPath)]" -Severity 3

                foreach ($email in $deferredEmails) {
                    Export-ADTEmail @email
                }
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